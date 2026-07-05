# ============================================================================
# 60-recovery-visibility.verify.ps1
#
# PURPOSE
# -------
# Provide read-only visibility into the minimum recovery signals
# expected by the v002 operating model.
#
# This script does NOT perform recovery.
# It only confirms whether baseline recovery prerequisites
# are visible enough for a human to decide whether to continue or stop.
#
# LIFECYCLE
# ---------
# Stage: 60–69 — Recovery / Continuation Boundary
#
# MODE
# ----
# VERIFY
# - Read-only
# - Safe to run repeatedly
# - No side effects
#
# EXIT MODEL
# ----------
# Variant A:
# - exit 0 : completed (with or without warnings)
# - exit 1 : fatal error only
#
# CONTRACT
# --------
# Follows docs/ARCHITECTURE.md and docs/ARCHITECTURE.md
# ============================================================================


[CmdletBinding()]
param(
    [ValidateSet("Text", "Json")]
    [string] $OutputFormat = "Text"
)


# ============================================================================
# 0. BOOTSTRAP
# ============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptRoot "..\..")
if (-not (Test-Path (Join-Path $ProjectRoot "core\lib\common.ps1"))) {
    $ProjectRoot = Resolve-Path (Join-Path $ScriptRoot "..\..\..")
}

. (Join-Path $ProjectRoot "core\lib\common.ps1")
. (Join-Path $ProjectRoot "core\lib\config.ps1")

$script:HadWarnings = $false
$warnings = [System.Collections.Generic.List[string]]::new()
$config = Import-BoringAdminConfigOrFail
$identitySettings = Get-BoringAdminIdentitySettings -Config $config

function Add-RecoveryWarning {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    $script:HadWarnings = $true
    $warnings.Add($Message) | Out-Null

    if ($OutputFormat -eq "Text") {
        Write-Warn $Message
    }
}


# ============================================================================
# 1. EXECUTION CONTEXT
# ============================================================================

Assert-Administrator
Test-PowerShellVersion | Out-Null

$recoveryAdminState = [pscustomobject]@{
    exists  = $false
    enabled = $null
}
$bitLockerVolumes = [System.Collections.Generic.List[object]]::new()
$externalChecklist = @(
    "BitLocker recovery keys are stored outside the workstation",
    "offline recovery documentation exists and is current",
    "OneDrive or equivalent data recovery path is understood",
    "reinstall path remains acceptable to the operator"
)


# ============================================================================
# 2. RECOVERY ADMINISTRATOR SIGNAL
# ============================================================================

try {
    $recoveryAdmin = Get-LocalUser -Name $identitySettings.recoveryAdminName -ErrorAction Stop
    $recoveryAdminState = [pscustomobject]@{
        exists  = $true
        enabled = [bool]$recoveryAdmin.Enabled
    }

    if ($recoveryAdmin.Enabled) {
        Add-RecoveryWarning "Recovery administrator is ENABLED. Verify that this is intentional."
    }
}
catch {
    Add-RecoveryWarning ("Recovery administrator '{0}' not found." -f $identitySettings.recoveryAdminName)
}


# ============================================================================
# 3. BITLOCKER RECOVERY SIGNAL
# ============================================================================

try {
    $volumes = Get-BitLockerVolume -ErrorAction Stop

    if (-not $volumes) {
        Add-RecoveryWarning "No BitLocker volumes were returned."
    }

    foreach ($volume in $volumes) {
        $mountPoint = if ($volume.MountPoint) { $volume.MountPoint } else { "<unknown>" }

        $protectors = @($volume.KeyProtector)
        $hasRecoveryProtector = $false

        foreach ($protector in $protectors) {
            if ($protector.KeyProtectorType -match "Recovery") {
                $hasRecoveryProtector = $true
            }
        }

        if (-not $hasRecoveryProtector) {
            Add-RecoveryWarning "Volume $mountPoint has no visible recovery key protector."
        }

        $bitLockerVolumes.Add([pscustomobject]@{
            mountPoint           = $mountPoint
            protectionStatus     = $volume.ProtectionStatus
            hasRecoveryProtector = $hasRecoveryProtector
        }) | Out-Null
    }
}
catch {
    Add-RecoveryWarning "Unable to query BitLocker recovery state."
}

$result = [pscustomobject]@{
    scope       = "recovery-visibility"
    generatedAt = Get-Rfc3339Timestamp
    recovery    = [pscustomobject]@{
        recoveryAdministrator = $recoveryAdminState
        bitLockerVolumes      = @($bitLockerVolumes)
        externalChecklist     = @($externalChecklist)
    }
    warnings    = @($warnings)
}

if ($OutputFormat -eq "Json") {
    $result | ConvertTo-Json -Depth 6
    Exit-Warn
}

Write-Section "60-recovery — Visibility (VERIFY)"
Write-Section "Recovery administrator signal"
if ($recoveryAdminState.exists) {
    Write-Info ("Recovery administrator exists: {0}" -f $identitySettings.recoveryAdminName)
    Write-Info "Recovery administrator enabled: $($recoveryAdminState.enabled)"
}

Write-Section "BitLocker recovery signal"
foreach ($volume in $bitLockerVolumes) {
    Write-Info "Volume $($volume.mountPoint) protection status: $($volume.protectionStatus)"
    if ($volume.hasRecoveryProtector) {
        Write-Info "Volume $($volume.mountPoint) has a recovery key protector."
    }
}


# ============================================================================
# 4. RECOVERY INTERPRETATION NOTES
# ============================================================================

Write-Section "Interpretation notes"

Write-Info "Recovery visibility in v002 is intentionally limited."
Write-Info "This check confirms only minimal recovery prerequisites:"
Write-Info "- break-glass account visibility"
Write-Info "- BitLocker recovery signal visibility"
Write-Info "It does not confirm external key escrow, backups, or successful restore drills."


# ============================================================================
# 5. EXTERNAL CHECKLIST REFERENCES
# ============================================================================

Write-Section "External checklist references"

Write-Info "The following recovery items must be confirmed outside the local device:"
Write-Info "- BitLocker recovery keys are stored outside the workstation"
Write-Info "- offline recovery documentation exists and is current"
Write-Info "- OneDrive or equivalent data recovery path is understood"
Write-Info "- reinstall path remains acceptable to the operator"
Write-Info "Suggested reference points:"
Write-Info "- docs/ANNUAL-MAINTENANCE.md"
Write-Info "- docs/RECOVERY-PLAYBOOK.md"
Write-Info "- offline recovery checklist or personal recovery note"


# ============================================================================
# 6. INTENTIONAL NON-ACTIONS
# ============================================================================

Write-Section "Intentional non-actions"

Write-Info "No recovery actions were performed"
Write-Info "No accounts were enabled or disabled"
Write-Info "No BitLocker settings were modified"
Write-Info "No continuation decision was automated"


# ============================================================================
# 7. SUMMARY & EXIT
# ============================================================================

Write-Section "Summary"
Write-Info "Recovery visibility check completed."

if ($script:HadWarnings) {
    Write-Warn "Recovery visibility contains unresolved warnings."
    Exit-Warn
}

Exit-Warn
