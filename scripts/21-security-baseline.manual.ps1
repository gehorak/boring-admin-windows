# ============================================================================
# 21-security-baseline.manual.ps1
#
# PURPOSE
# -------
# Define and REVIEW a minimal, explicit security baseline
# for Windows 11 systems in SMB / non-domain environments.
#
# This script represents the AUTHORITATIVE Phase-1 security minimum:
# - the system is not trivially insecure
# - core protection mechanisms are present and observable
#
# LIFECYCLE
# ---------
# Stage: 20–29 — Security & System Policy
#
# MODE
# ----
# MANUAL
# - Requires explicit human execution
# - Safe to run repeatedly
# - No automatic remediation
#
# RISK CLASS
# ----------
# LOW
# This script does not enforce policy or modify configuration.
#
# SCOPE
# -----
# MAY:
# - verify presence and runtime state of core security components
# - WARN on deviations from expected baseline
#
# MUST NOT:
# - apply security hardening
# - change Defender, Firewall, or BitLocker configuration
# - manage firewall rules or exclusions
# - emulate GPO / MDM behavior
#
# EXIT MODEL
# ----------
# Variant A:
# - exit 0 : baseline reviewed (with or without warnings)
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

Write-Section "21-security-baseline — Phase-1 (MANUAL)"


# ============================================================================
# 2. BASELINE INTENT
# ============================================================================
# Explicit statement of what Phase-1 security means.
# ============================================================================

Write-Section "Baseline intent"

Write-Info "Phase-1 security baseline ensures that:"
Write-Info "- core protection mechanisms are present"
Write-Info "- system is not trivially or embarrassingly insecure"
Write-Info "- no automatic remediation is performed"

Write-Host ""
Write-Info "This script does NOT perform security hardening."
Write-Info "All remediation decisions remain with the administrator."


# ============================================================================
# 3. VERIFY — WINDOWS DEFENDER
# ============================================================================
# Expected: Defender service running, real-time protection enabled.
# ============================================================================

Write-Section "Verify: Windows Defender"

try {
    $svc = Get-Service -Name WinDefend -ErrorAction SilentlyContinue

    if (-not $svc) {
        Write-WarnFlagged "Windows Defender service not found." ([ref]$script:HadWarnings)
    }
    elseif ($svc.Status -ne 'Running') {
        Write-WarnFlagged "Windows Defender service is not running." ([ref]$script:HadWarnings)
    }
    else {
        $mp = Try-GetMpComputerStatus -TimeoutSec 5

        if (-not $mp) {
            Write-WarnFlagged "Defender status unavailable (timeout)." ([ref]$script:HadWarnings)
        }
        else {
            Write-Info "Antivirus enabled        : $($mp.AntivirusEnabled)"
            Write-Info "Real-time protection     : $($mp.RealTimeProtectionEnabled)"

            if (-not $mp.AntivirusEnabled -or -not $mp.RealTimeProtectionEnabled) {
                Write-WarnFlagged "Defender is not fully enabled." ([ref]$script:HadWarnings)
            }
        }
    }
}
catch {
    Write-WarnFlagged "Unable to query Windows Defender state." ([ref]$script:HadWarnings)
}


# ============================================================================
# 4. VERIFY — WINDOWS FIREWALL
# ============================================================================
# Expected: All profiles enabled.
# ============================================================================

Write-Section "Verify: Windows Firewall"

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
# 5. VERIFY — BITLOCKER
# ============================================================================
# Expected: Protection enabled on system volumes.
# No automatic enabling is performed.
# ============================================================================

Write-Section "Verify: BitLocker"

try {
    Get-BitLockerVolume | ForEach-Object {
        Write-Info "Volume $($_.MountPoint): ProtectionStatus = $($_.ProtectionStatus)"

        if ($_.ProtectionStatus -ne 1) {
            Write-WarnFlagged "BitLocker is NOT enabled on $($_.MountPoint)." ([ref]$script:HadWarnings)
            Write-Warn "Action required: enable BitLocker and store recovery key OFFLINE."
        }
    }
}
catch {
    Write-WarnFlagged "BitLocker status unavailable." ([ref]$script:HadWarnings)
}


# ============================================================================
# 6. VERIFY — SECURE BOOT
# ============================================================================
# Expected: Enabled where supported.
# Informational only.
# ============================================================================

Write-Section "Verify: Secure Boot"

try {
    $sb = Confirm-SecureBootUEFI
    Write-Info "Secure Boot enabled: $sb"

    if (-not $sb) {
        Write-WarnFlagged "Secure Boot is disabled." ([ref]$script:HadWarnings)
    }
}
catch {
    Write-WarnFlagged "Secure Boot status unavailable (legacy BIOS or unsupported firmware)." ([ref]$script:HadWarnings)
}


# ============================================================================
# 7. INTENTIONAL NON-ACTIONS
# ============================================================================
# Explicit guarantees for audit clarity.
# ============================================================================

Write-Section "Intentional non-actions"

Write-Info "No security settings were modified"
Write-Info "No firewall rules were changed"
Write-Info "No Defender configuration was altered"
Write-Info "No registry hardening was applied"
Write-Info "No reboot was scheduled or performed"


# ============================================================================
# 8. SUMMARY & EXIT
# ============================================================================

Write-Section "Summary"

Write-Info "Phase-1 security baseline review completed."

if ($script:HadWarnings) {
    Write-Warn "One or more baseline expectations are not met."
    Exit-Warn
}

Exit-Warn
