# ============================================================================
# 29-security-visibility.verify.ps1
#
# PURPOSE
# -------
# Provide a READ-ONLY security snapshot for audit, review,
# and incident context.
#
# This script exposes the CURRENT security posture without
# enforcing or remediating anything.
#
# LIFECYCLE
# ---------
# Stage: 20–29 — Security & System Policy
#
# MODE
# ----
# VERIFY
# - Read-only
# - Safe to run repeatedly
# - No side effects
#
# ROLE
# ----
# - Security visibility
# - Audit snapshot
# - Incident context support
#
# EXIT MODEL
# ----------
# Variant A:
# - exit 0 : completed (with or without warnings)
# - exit 1 : fatal error only
#
# CONTRACT
# --------
# Follows docs/ARCHITECTURE.md
# and docs/ARCHITECTURE.md
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

$script:HadWarnings = $false
$warnings = [System.Collections.Generic.List[string]]::new()

function Add-SecurityWarning {
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

$defenderServiceState = $null
$defenderStatus = $null
$firewallProfiles = @()
$bitLockerVolumes = @()
$secureBootEnabled = $null


# ============================================================================
# 2. SECURITY SNAPSHOT
# ============================================================================
# Pure observation. No expectations, no enforcement.
# ============================================================================

try {
    $svc = Get-Service -Name WinDefend -ErrorAction SilentlyContinue
    if ($svc) {
        $defenderServiceState = $svc.Status.ToString()
    }
    else {
        Add-SecurityWarning "Defender service not found."
    }

    $mp = Try-GetMpComputerStatus -TimeoutSec 5
    if ($mp) {
        $defenderStatus = [pscustomobject]@{
            antivirusEnabled       = [bool]$mp.AntivirusEnabled
            realTimeProtection     = [bool]$mp.RealTimeProtectionEnabled
            tamperProtection       = [bool]$mp.IsTamperProtected
        }
    }
    else {
        Add-SecurityWarning "Defender detailed status unavailable."
    }
}
catch {
    Add-SecurityWarning "Unable to query Windows Defender."
}


# ---------------------------------------------------------------------------
# Windows Firewall
# ---------------------------------------------------------------------------

try {
    $firewallProfiles = @(
        Get-NetFirewallProfile | ForEach-Object {
            [pscustomobject]@{
                name    = $_.Name
                enabled = [bool]$_.Enabled
            }
        }
    )
}
catch {
    Add-SecurityWarning "Unable to query firewall profiles."
}


# ---------------------------------------------------------------------------
# BitLocker
# ---------------------------------------------------------------------------

try {
    $bitLockerVolumes = @(
        Get-BitLockerVolume | ForEach-Object {
            [pscustomobject]@{
                mountPoint        = $_.MountPoint
                protectionStatus  = $_.ProtectionStatus
            }
        }
    )
}
catch {
    Add-SecurityWarning "Unable to query BitLocker status."
}


# ---------------------------------------------------------------------------
# Secure Boot
# ---------------------------------------------------------------------------

try {
    $secureBootEnabled = [bool](Confirm-SecureBootUEFI)
}
catch {
    Add-SecurityWarning "Secure Boot status unavailable."
}

$result = [pscustomobject]@{
    scope       = "security-visibility"
    generatedAt = Get-Rfc3339Timestamp
    security    = [pscustomobject]@{
        windowsDefender = [pscustomobject]@{
            serviceState = $defenderServiceState
            status       = $defenderStatus
        }
        firewallProfiles = @($firewallProfiles)
        bitLockerVolumes = @($bitLockerVolumes)
        secureBootEnabled = $secureBootEnabled
    }
    warnings    = @($warnings)
}

if ($OutputFormat -eq "Json") {
    $result | ConvertTo-Json -Depth 6
    Exit-Warn
}

Write-Section "29-security — Visibility (VERIFY)"
Write-Section "Security snapshot"

Write-SubSection "Windows Defender"
if ($defenderServiceState) {
    Write-Info "Service state : $defenderServiceState"
}
if ($defenderStatus) {
    Write-Info "Antivirus enabled    : $($defenderStatus.antivirusEnabled)"
    Write-Info "Real-time protection : $($defenderStatus.realTimeProtection)"
    Write-Info "Tamper protection    : $($defenderStatus.tamperProtection)"
}

Write-SubSection "Windows Firewall"
foreach ($firewallProfile in $firewallProfiles) {
    Write-Info "Profile [$($firewallProfile.name)] enabled: $($firewallProfile.enabled)"
}

Write-SubSection "BitLocker"
foreach ($volume in $bitLockerVolumes) {
    Write-Info "Volume $($volume.mountPoint): ProtectionStatus = $($volume.protectionStatus)"
}

Write-SubSection "Secure Boot"
if ($null -ne $secureBootEnabled) {
    Write-Info "Secure Boot enabled: $secureBootEnabled"
}


# ============================================================================
# 3. CONTEXTUAL NOTES (NON-ENFORCING)
# ============================================================================
# Informational hints only.
# ============================================================================

Write-Section "Contextual notes"

Write-Info "This snapshot reflects the CURRENT runtime state."
Write-Info "No assumptions are made about compliance or policy."
Write-Info "Use this output for:"
Write-Info "- audits"
Write-Info "- incident response"
Write-Info "- administrative review"


# ============================================================================
# 4. INTENTIONAL NON-ACTIONS
# ============================================================================
# Explicit guarantees for audit clarity.
# ============================================================================

Write-Section "Intentional non-actions"

Write-Info "No security settings were modified"
Write-Info "No policies were applied"
Write-Info "No remediation was attempted"
Write-Info "No reboot was scheduled or performed"


# ============================================================================
# 5. SUMMARY & EXIT
# ============================================================================

Write-Section "Summary"

Write-Info "Security visibility snapshot completed."

if ($script:HadWarnings) {
    Write-Warn "Some security information could not be retrieved."
    Exit-Warn
}

Exit-Warn
