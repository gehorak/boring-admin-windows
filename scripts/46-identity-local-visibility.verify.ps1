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


# ============================================================================
# 0. BOOTSTRAP
# ============================================================================

$ScriptRoot  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptRoot\.."

. "$ProjectRoot\lib\common.ps1"

$script:HadWarnings = $false


# ============================================================================
# 1. EXECUTION CONTEXT
# ============================================================================

Assert-Administrator
Test-PowerShellVersion | Out-Null

Write-Section "46-identity — Local Identity Visibility (VERIFY)"


# ============================================================================
# 2. LOCAL USER ACCOUNTS (OVERVIEW)
# ============================================================================
# Full visibility. No interpretation.
# ============================================================================

Write-Section "Local user accounts"

try {
    Get-LocalUser -ErrorAction Stop |
        Sort-Object Name |
        ForEach-Object {
            Write-Info ("{0,-20} Enabled={1,-5} PasswordExpires={2}" -f `
                $_.Name, $_.Enabled, (-not $_.PasswordNeverExpires))
        }
}
catch {
    Write-WarnFlagged "Unable to enumerate local user accounts."
}


# ============================================================================
# 3. LOCAL ADMINISTRATORS GROUP
# ============================================================================
# Critical visibility for privilege creep.
# ============================================================================

Write-Section "Local Administrators group membership"

try {
    Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop |
        Sort-Object Name |
        ForEach-Object {
            Write-Info "Administrator member: $($_.Name)"
        }
}
catch {
    Write-WarnFlagged "Unable to enumerate Administrators group membership."
}


# ============================================================================
# 4. MANAGED IDENTITY MARKERS
# ============================================================================
# Highlight known, expected accounts without enforcing policy.
# ============================================================================

Write-Section "Managed identity markers"

$managedAccounts = @(
    "admin.LOCAL",
    "admin.RECOVERY",
    "guest.TEMP"
)

foreach ($name in $managedAccounts) {
    try {
        $u = Get-LocalUser -Name $name -ErrorAction Stop
        Write-Info "Managed account '$name' exists (Enabled: $($u.Enabled))"
    }
    catch {
        Write-WarnFlagged "Managed account '$name' does NOT exist."
    }
}


# ============================================================================
# 5. ANOMALY HINTS (NON-ENFORCING)
# ============================================================================
# Human hints only. No automatic judgement.
# ============================================================================

Write-Section "Anomaly hints (human review required)"

# Disabled administrators (unexpected but not enforced)
try {
    Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop |
        ForEach-Object {
            try {
                $u = Get-LocalUser -Name $_.Name -ErrorAction Stop
                if (-not $u.Enabled) {
                    Write-WarnFlagged "Administrator account '$($_.Name)' is DISABLED."
                }
            }
            catch {
                # Non-local principals (SID / group) — informational
            }
        }
}
catch {
    Write-WarnFlagged "Unable to evaluate administrator account states."
}


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
