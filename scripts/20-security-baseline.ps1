# ============================================================================
# 20-security-baseline.ps1
#
# PURPOSE
# -------
# Establish and VERIFY a minimal, sane security baseline for Windows 11
# in SMB / no-domain environments.
#
# SECURITY BASELINE = enforcement of high-value, low-risk controls.
#
# THIS SCRIPT IS:
# ----------------
# - minimal
# - explicit
# - admin-driven
#
# THIS SCRIPT IS NOT:
# -------------------
# - a hardening script
# - a policy engine
# - a replacement for MDM / GPO
#
# ============================================================================
#
# SCOPE
# -----
# MAY:
# - Verify security-critical system state
# - Enforce mandatory security prerequisites (explicit only)
#
# MUST NOT:
# - Tune OS behavior (belongs to 25-system-configuration)
# - Change UX defaults
# - Apply registry hardening
# - Modify firewall rules
#
# ============================================================================

# -----------------------------------------------------------------------------
# Bootstrap
# -----------------------------------------------------------------------------

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptRoot\.."

. "$ProjectRoot\lib\common.ps1"


Assert-Administrator
Test-PowerShellVersion | Out-Null

Write-Section "Security Baseline"

# =============================================================================
# 0) APPLY – EXPLICIT SECURITY REQUIREMENTS
# =============================================================================
# Only actions that are:
# - high value
# - low risk
# - universally expected
#
# Currently: NONE (by design)
#
# BitLocker enabling remains a conscious admin decision.
# =============================================================================

Write-Section "Apply (explicit requirements)"
Write-Info "No automatic security changes applied by this script."

# =============================================================================
# 1) VERIFY – WINDOWS DEFENDER
# =============================================================================

Write-Section "Verify: Windows Defender"

$svc = Get-Service -Name WinDefend -ErrorAction SilentlyContinue
if (-not $svc -or $svc.Status -ne 'Running') {
    Write-Warn "Windows Defender service is not running."
}
else {
    $mp = Try-GetMpComputerStatus -TimeoutSec 5

    if (-not $mp) {
        Write-Warn "Defender status unavailable (timeout)."
    }
    else {
        Write-Info "Antivirus enabled: $($mp.AntivirusEnabled)"
        Write-Info "Real-time protection: $($mp.RealTimeProtectionEnabled)"

        if (-not $mp.AntivirusEnabled -or -not $mp.RealTimeProtectionEnabled) {
            Write-Warn "Defender is not fully enabled. Manual investigation required."
        }
    }
}

# =============================================================================
# 2) VERIFY – WINDOWS FIREWALL
# =============================================================================

Write-Section "Verify: Windows Firewall"

Get-NetFirewallProfile | ForEach-Object {
    Write-Info "Firewall [$($_.Name)] enabled: $($_.Enabled)"

    if (-not $_.Enabled) {
        Write-Warn "Firewall profile '$($_.Name)' is disabled."
    }
}

# =============================================================================
# 3) VERIFY – BITLOCKER (MANDATORY)
# =============================================================================

Write-Section "Verify: BitLocker"

try {
    Get-BitLockerVolume | ForEach-Object {
        Write-Info "Volume $($_.MountPoint): ProtectionStatus = $($_.ProtectionStatus)"

        if ($_.ProtectionStatus -ne 1) {
            Write-Warn "BitLocker NOT enabled on $($_.MountPoint)"
            Write-Warn "Action required: enable BitLocker and store recovery key OFFLINE."
        }
    }
}
catch {
    Write-Warn "BitLocker status unavailable."
}

# =============================================================================
# 4) VERIFY – SECURE BOOT (INFORMATIONAL)
# =============================================================================

Write-Section "Verify: Secure Boot"

try {
    Write-Info "Secure Boot enabled: $(Confirm-SecureBootUEFI)"
}
catch {
    Write-Warn "Secure Boot status unavailable (legacy BIOS or unsupported firmware)."
}

# =============================================================================
# 5) VERIFY – LOCAL ADMIN EXPOSURE
# =============================================================================

Write-Section "Verify: Local Administrators"

Get-LocalGroupMember -Group "Administrators" | ForEach-Object {
    Write-Info "Admin member: $($_.Name)"
}

# =============================================================================
# 6) GUARANTEES (INTENTIONAL NON-ACTIONS)
# =============================================================================

Write-Section "Baseline Guarantees"

Write-Info "No services were disabled"
Write-Info "No firewall rules were modified"
Write-Info "No Defender configuration overridden"
Write-Info "No registry hardening applied"
Write-Info "No user rights assignments modified"

# =============================================================================
# 7) SUMMARY
# =============================================================================

Write-Section "Summary"
Write-Info "Security baseline verification completed."
