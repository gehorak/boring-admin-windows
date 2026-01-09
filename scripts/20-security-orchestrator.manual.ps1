# ============================================================================
# 20-security-orchestrator.manual.ps1
#
# PURPOSE
# -------
# Provide a human-oriented entry point to SYSTEM SECURITY management.
#
# This script explains what "security" means in the context of
# boring-admin-windows, shows high-level security state visibility,
# and guides the operator to the correct Phase-1 scripts.
#
# THIS SCRIPT DOES NOT MODIFY SYSTEM STATE.
#
# LIFECYCLE
# ---------
# Stage: 20–29 — Security & System Policy
#
# MODE
# ----
# MANUAL (read-only)
# - Safe to run repeatedly
# - No side effects
# - Must not be executed in CI
#
# ROLE
# ----
# - Conceptual security overview
# - Phase-1 scope explanation
# - Operator navigation
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

Write-Section "20-security — Orchestrator (MANUAL, read-only)"


# ============================================================================
# 2. SECURITY PHILOSOPHY (BORING-ADMIN)
# ============================================================================
# This section defines what security IS and IS NOT in this project.
# ============================================================================

Write-Section "Security philosophy"

Write-Info "In boring-admin-windows, security means:"
Write-Info "- minimum expected protection is present"
Write-Info "- state is observable and reviewable"
Write-Info "- no hidden automation or magic"

Write-Host ""
Write-Info "Security here is NOT:"
Write-Info "- enterprise hardening"
Write-Info "- CIS / STIG compliance"
Write-Info "- automatic remediation"
Write-Info "- policy enforcement engine"


# ============================================================================
# 3. PHASE-1 SECURITY SCOPE
# ============================================================================
# Explicit contract for what Phase-1 covers.
# ============================================================================

Write-Section "Phase-1 security scope"

Write-Info "Phase-1 security covers ONLY:"
Write-Info "- Windows Defender (presence and runtime state)"
Write-Info "- Windows Firewall (profiles enabled)"
Write-Info "- BitLocker (awareness of protection status)"
Write-Info "- Secure Boot (firmware support awareness)"

Write-Host ""
Write-Info "Phase-1 security EXCLUDES:"
Write-Info "- firewall rules"
Write-Info "- Defender exclusions or ASR rules"
Write-Info "- credential hardening"
Write-Info "- network or crypto policy"
Write-Info "- Windows Update policy"


# ============================================================================
# 4. HIGH-LEVEL SECURITY VISIBILITY (READ-ONLY)
# ============================================================================
# Light snapshot only. No expectations, no enforcement.
# ============================================================================

Write-Section "High-level security snapshot"

# --- Defender service --------------------------------------------------------

try {
    $svc = Get-Service -Name WinDefend -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq 'Running') {
        Write-Info "Windows Defender service: running"
    }
    else {
        Write-WarnFlagged "Windows Defender service is not running." ([ref]$script:HadWarnings)
    }
}
catch {
    Write-WarnFlagged "Unable to read Windows Defender service state." ([ref]$script:HadWarnings)
}

# --- Firewall profiles -------------------------------------------------------

try {
    Get-NetFirewallProfile | ForEach-Object {
        Write-Info "Firewall [$($_.Name)] enabled: $($_.Enabled)"
        if (-not $_.Enabled) {
            Write-WarnFlagged "Firewall profile '$($_.Name)' is disabled." ([ref]$script:HadWarnings)
        }
    }
}
catch {
    Write-WarnFlagged "Unable to read firewall profile state." ([ref]$script:HadWarnings)
}


# ============================================================================
# 5. OPERATOR NAVIGATION
# ============================================================================
# Explicit guidance without automation.
# ============================================================================

Write-Section "Available security actions"

Write-Info "To APPLY or REVIEW the Phase-1 security baseline:"
Write-Info "  -> Run: 21-security-baseline.manual.ps1"

Write-Host ""
Write-Info "To VIEW security state for audit or incident context:"
Write-Info "  -> Run: 29-security-visibility.verify.ps1 (if present)"


# ============================================================================
# 6. INTENTIONAL NON-ACTIONS
# ============================================================================
# Explicit declaration for audit clarity.
# ============================================================================

Write-Section "Intentional non-actions"

Write-Info "No security settings were changed"
Write-Info "No policies were applied"
Write-Info "No firewall rules were modified"
Write-Info "No Defender configuration was altered"
Write-Info "No reboot was scheduled or performed"


# ============================================================================
# 7. SUMMARY & EXIT
# ============================================================================

Write-Section "Summary"

Write-Info "Security orchestrator completed."

if ($script:HadWarnings) {
    Write-Warn "One or more security components may require attention."
    Exit-Warn
}

Exit-Warn
