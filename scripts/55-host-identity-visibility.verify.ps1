# ============================================================================
# 55-host-identity-visibility.verify.ps1
#
# PURPOSE
# -------
# Provide read-only visibility into HOST IDENTITY state.
#
# This script exposes how the machine currently identifies itself:
# - computer name
# - system time zone
# - system locale (non-Unicode)
#
# The script performs OBSERVATION ONLY.
# It does NOT enforce or modify any configuration.
#
# LIFECYCLE
# ---------
# Stage: 50–59 — Host & Device Identity
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
# Follows docs/SCRIPT-CONTRACT.md
# and docs/STRUCTURE.md
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

Write-Section "55-host-identity — Visibility (VERIFY)"


# ============================================================================
# 2. HOST IDENTITY SNAPSHOT
# ============================================================================
# Pure visibility. No expectations, no enforcement.
# ============================================================================

Write-Section "Host identity snapshot"

# --- Computer name -----------------------------------------------------------

try {
    Write-Info "Computer name : $env:COMPUTERNAME"
}
catch {
    Write-WarnFlagged "Unable to read computer name." ([ref]$script:HadWarnings)
}

# --- Time zone ---------------------------------------------------------------

try {
    $tz = Get-TimeZone
    Write-Info "Time zone     : $($tz.Id)"
    Write-Info "UTC offset    : $($tz.BaseUtcOffset)"
}
catch {
    Write-WarnFlagged "Unable to read system time zone." ([ref]$script:HadWarnings)
}

# --- System locale -----------------------------------------------------------

try {
    $locale = Get-WinSystemLocale
    Write-Info "System locale : $($locale.Name)"
}
catch {
    Write-WarnFlagged "Unable to read system locale." ([ref]$script:HadWarnings)
}


# ============================================================================
# 3. CONTEXTUAL NOTES (NON-ENFORCING)
# ============================================================================
# Human hints only. No judgement.
# ============================================================================

Write-Section "Contextual notes"

Write-Info "Host identity affects:"
Write-Info "- log readability"
Write-Info "- incident and forensic timelines"
Write-Info "- remote administration clarity"

Write-Host ""
Write-Info "Changes to host identity:"
Write-Info "- are rare and intentional"
Write-Info "- may require a manual reboot"
Write-Info "- should be documented when performed"


# ============================================================================
# 4. INTENTIONAL NON-ACTIONS
# ============================================================================
# Explicit declaration for audit clarity.
# ============================================================================

Write-Section "Intentional non-actions"

Write-Info "No configuration was modified"
Write-Info "No reboot was scheduled or performed"
Write-Info "No enforcement or remediation occurred"
Write-Info "No network or security settings were accessed"


# ============================================================================
# 5. SUMMARY & EXIT
# ============================================================================

Write-Section "Summary"

Write-Info "Host identity visibility check completed."

if ($script:HadWarnings) {
    Write-Warn "Some host identity information could not be retrieved."
    Exit-Warn
}

Exit-Warn
