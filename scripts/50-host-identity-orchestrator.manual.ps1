# ============================================================================
# 50-host-identity-orchestrator.manual.ps1
#
# PURPOSE
# -------
# Provide a human-oriented entry point to HOST IDENTITY management.
#
# This script explains what host identity means, shows the current
# host identity state, and guides the operator to the correct
# MANUAL or VERIFY scripts.
#
# THIS SCRIPT DOES NOT CHANGE SYSTEM STATE.
#
# LIFECYCLE
# ---------
# Stage: 50–59 — Host & Device Identity
#
# MODE
# ----
# MANUAL (read-only)
# - Safe to run repeatedly
# - No side effects
# - No automatic execution of other scripts
#
# ROLE
# ----
# - Host identity overview
# - Operator guidance
# - Read-only visibility
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

Write-Section "50-host-identity — Orchestrator (MANUAL, read-only)"


# ============================================================================
# 2. WHAT IS HOST IDENTITY
# ============================================================================
# Conceptual overview for the operator.
# ============================================================================

Write-Section "Host identity overview"

Write-Info "Host identity defines how this machine presents itself to:"
Write-Info "- administrators"
Write-Info "- logs and audit trails"
Write-Info "- remote management tools"

Write-Host ""
Write-Info "Host identity is:"
Write-Info "- global to the machine"
Write-Info "- stable over time"
Write-Info "- changed rarely and intentionally"

Write-Host ""
Write-Info "Host identity is NOT:"
Write-Info "- user identity"
Write-Info "- security policy"
Write-Info "- network configuration"
Write-Info "- cloud or domain identity"


# ============================================================================
# 3. CURRENT HOST IDENTITY STATE (READ-ONLY)
# ============================================================================
# No enforcement. Observation only.
# ============================================================================

Write-Section "Current host identity state"

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
# 4. EXPECTED PHASE-1 HOST IDENTITY SCOPE
# ============================================================================
# Explicitly document what Phase-1 host identity covers.
# ============================================================================

Write-Section "Phase-1 host identity scope"

Write-Info "Phase-1 host identity includes ONLY:"
Write-Info "- Computer name"
Write-Info "- System time zone"
Write-Info "- System locale (non-Unicode)"

Write-Host ""
Write-Info "Phase-1 host identity EXCLUDES:"
Write-Info "- UI language and keyboard layout"
Write-Info "- Network identity (IP, DNS, domain)"
Write-Info "- Time synchronization configuration"
Write-Info "- Certificates and machine keys"
Write-Info "- Cloud or device enrollment"


# ============================================================================
# 5. OPERATOR GUIDANCE
# ============================================================================
# Explicit navigation without automation.
# ============================================================================

Write-Section "Available host identity actions"

Write-Info "To APPLY or CHANGE core host identity state:"
Write-Info "  -> Run: 51-host-identity-core.manual.ps1"

Write-Host ""
Write-Info "To VIEW host identity for audit or troubleshooting:"
Write-Info "  -> Run: 55-host-identity-visibility.verify.ps1 (if present)"


# ============================================================================
# 6. INTENTIONAL NON-ACTIONS
# ============================================================================
# Explicit declaration of what this orchestrator does not do.
# ============================================================================

Write-Section "Intentional non-actions"

Write-Info "No system settings were changed"
Write-Info "No reboot was scheduled or performed"
Write-Info "No other scripts were executed"
Write-Info "No configuration was enforced"


# ============================================================================
# 7. SUMMARY & EXIT
# ============================================================================

Write-Section "Summary"

Write-Info "Host identity orchestrator completed."

if ($script:HadWarnings) {
    Write-Warn "Some host identity information could not be read."
    Exit-Warn
}

Exit-Warn
