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

Write-Section "29-security — Visibility (VERIFY)"


# ============================================================================
# 2. SECURITY SNAPSHOT
# ============================================================================
# Pure observation. No expectations, no enforcement.
# ============================================================================

Write-Section "Security snapshot"


# ---------------------------------------------------------------------------
# Windows Defender
# ---------------------------------------------------------------------------

Write-SubSection "Windows Defender"

try {
    $svc = Get-Service -Name WinDefend -ErrorAction SilentlyContinue
    if ($svc) {
        Write-Info "Service state : $($svc.Status)"
    }
    else {
        Write-WarnFlagged "Defender service not found." ([ref]$script:HadWarnings)
    }

    $mp = Try-GetMpComputerStatus -TimeoutSec 5
    if ($mp) {
        Write-Info "Antivirus enabled    : $($mp.AntivirusEnabled)"
        Write-Info "Real-time protection : $($mp.RealTimeProtectionEnabled)"
        Write-Info "Tamper protection    : $($mp.IsTamperProtected)"
    }
    else {
        Write-WarnFlagged "Defender detailed status unavailable." ([ref]$script:HadWarnings)
    }
}
catch {
    Write-WarnFlagged "Unable to query Windows Defender." ([ref]$script:HadWarnings)
}


# ---------------------------------------------------------------------------
# Windows Firewall
# ---------------------------------------------------------------------------

Write-SubSection "Windows Firewall"

try {
    Get-NetFirewallProfile | ForEach-Object {
        Write-Info "Profile [$($_.Name)] enabled: $($_.Enabled)"
    }
}
catch {
    Write-WarnFlagged "Unable to query firewall profiles." ([ref]$script:HadWarnings)
}


# ---------------------------------------------------------------------------
# BitLocker
# ---------------------------------------------------------------------------

Write-SubSection "BitLocker"

try {
    Get-BitLockerVolume | ForEach-Object {
        Write-Info "Volume $($_.MountPoint): ProtectionStatus = $($_.ProtectionStatus)"
    }
}
catch {
    Write-WarnFlagged "Unable to query BitLocker status." ([ref]$script:HadWarnings)
}


# ---------------------------------------------------------------------------
# Secure Boot
# ---------------------------------------------------------------------------

Write-SubSection "Secure Boot"

try {
    $sb = Confirm-SecureBootUEFI
    Write-Info "Secure Boot enabled: $sb"
}
catch {
    Write-WarnFlagged "Secure Boot status unavailable." ([ref]$script:HadWarnings)
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
