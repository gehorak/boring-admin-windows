# ============================================================================
# 46-identity-local-visibility.verify.ps1
#
# PURPOSE
# -------
# Provide read-only visibility into local identity state
# on Windows 11 systems in SMB / non-domain environments.
#
# This script performs OBSERVATION ONLY.
# It does NOT modify system state.
#
# LIFECYCLE
# ---------
# Stage: 40–49 — Identity & Access
#
# MODE
# ----
# VERIFY
# - Read-only
# - Safe to run repeatedly
# - No credentials requested
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
# Follows docs/SCRIPT-CONTRACT.md and docs/STRUCTURE.md
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

function Add-IdentityWarning {
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

$localUsers = @()
$administratorsGroup = @()
$managedAccounts = @()


# ============================================================================
# 2. LOCAL USER ACCOUNTS (OVERVIEW)
# ============================================================================
# Full visibility. No interpretation.
# ============================================================================

try {
    $localUsers = @(
        Get-LocalUser -ErrorAction Stop |
            Sort-Object Name |
            ForEach-Object {
                [pscustomobject]@{
                    name            = $_.Name
                    enabled         = [bool]$_.Enabled
                    passwordExpires = (-not $_.PasswordNeverExpires)
                }
            }
    )
}
catch {
    Add-IdentityWarning "Unable to enumerate local user accounts."
}


# ============================================================================
# 3. LOCAL ADMINISTRATORS GROUP
# ============================================================================
# Critical visibility for privilege creep.
# ============================================================================

try {
    $administratorsGroup = @(
        Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop |
            Sort-Object Name |
            ForEach-Object {
                [pscustomobject]@{
                    name = $_.Name
                }
            }
    )
}
catch {
    Add-IdentityWarning "Unable to enumerate Administrators group membership."
}


# ============================================================================
# 4. MANAGED IDENTITY MARKERS
# ============================================================================
# Highlight known, expected accounts without enforcing policy.
# ============================================================================

$managedAccountNames = @(
    "admin.LOCAL",
    "admin.RECOVERY",
    "guest.TEMP"
)

foreach ($name in $managedAccountNames) {
    try {
        $u = Get-LocalUser -Name $name -ErrorAction Stop
        $managedAccounts += [pscustomobject]@{
            name    = $name
            exists  = $true
            enabled = [bool]$u.Enabled
        }
    }
    catch {
        Add-IdentityWarning "Managed account '$name' does NOT exist."
        $managedAccounts += [pscustomobject]@{
            name    = $name
            exists  = $false
            enabled = $null
        }
    }
}


# ============================================================================
# 5. ANOMALY HINTS (NON-ENFORCING)
# ============================================================================
# Human hints only. No automatic judgement.
# ============================================================================

# Disabled administrators (unexpected but not enforced)
 $disabledAdministrators = [System.Collections.Generic.List[string]]::new()
try {
    Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop |
        ForEach-Object {
            try {
                $u = Get-LocalUser -Name $_.Name -ErrorAction Stop
                if (-not $u.Enabled) {
                    $disabledAdministrators.Add($_.Name) | Out-Null
                    Add-IdentityWarning "Administrator account '$($_.Name)' is DISABLED."
                }
            }
            catch {
                return
            }
        }
}
catch {
    Add-IdentityWarning "Unable to evaluate administrator account states."
}

$result = [pscustomobject]@{
    scope       = "identity-local-visibility"
    generatedAt = (Get-Date).ToString("s")
    identity    = [pscustomobject]@{
        localUsers              = @($localUsers)
        administratorsGroup     = @($administratorsGroup)
        managedAccounts         = @($managedAccounts)
        disabledAdministrators  = @($disabledAdministrators)
    }
    warnings    = @($warnings)
}

if ($OutputFormat -eq "Json") {
    $result | ConvertTo-Json -Depth 6
    Exit-Warn
}

Write-Section "46-identity — Local Identity Visibility (VERIFY)"
Write-Section "Local user accounts"
foreach ($user in $localUsers) {
    Write-Info ("{0,-20} Enabled={1,-5} PasswordExpires={2}" -f `
        $user.name, $user.enabled, $user.passwordExpires)
}

Write-Section "Local Administrators group membership"
foreach ($member in $administratorsGroup) {
    Write-Info "Administrator member: $($member.name)"
}

Write-Section "Managed identity markers"
foreach ($managedAccount in $managedAccounts) {
    if ($managedAccount.exists) {
        Write-Info "Managed account '$($managedAccount.name)' exists (Enabled: $($managedAccount.enabled))"
    }
}

Write-Section "Anomaly hints (human review required)"


# ============================================================================
# 6. INTENTIONAL NON-ACTIONS
# ============================================================================

Write-Section "Intentional non-actions"

Write-Info "No users were created, modified, or removed"
Write-Info "No group memberships were changed"
Write-Info "No passwords were requested or validated"
Write-Info "No policy or security settings were enforced"


# ============================================================================
# 7. COMPLETION & EXIT STRATEGY
# ============================================================================

Write-Section "Summary"
Write-Info "Local identity visibility check completed."

Exit-Warn
