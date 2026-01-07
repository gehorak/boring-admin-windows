# ============================================================================
# 90-audit.ps1
#
# PURPOSE
# -------
# Provide a fast, read-only audit of the system state to verify that
# the intended Windows 11 (no-domain, SMB) design is still intact.
#
# THIS SCRIPT:
# ------------
# - makes NO changes
# - reports facts, not opinions
# - highlights deviations from the design
#
# AUDIT SCOPE
# -----------
# - OS & join state
# - Admin exposure
# - Security baseline (Defender, Firewall, BitLocker)
# - Debloat markers (policies present)
# - Chocolatey presence
# - Host account presence
#
# OUTPUT GOAL
# -----------
# One screen. Actionable signals.
# ============================================================================

# -----------------------------------------------------------------------------
# Bootstrap
# -----------------------------------------------------------------------------

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptRoot\.."

. "$ProjectRoot\lib\common.ps1"


Assert-Administrator
Test-PowerShellVersion | Out-Null

Write-Section "System Audit (Read-Only)"

# ---------------------------------------------------------------------------
# 1) OS & domain state
# ---------------------------------------------------------------------------

Write-Section "OS & Join State"

$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem

Write-Info "OS: $($os.Caption) ($($os.Version))"
Write-Info "Computer name: $($cs.Name)"
Write-Info "Domain joined: $($cs.PartOfDomain)"

if ($cs.PartOfDomain) {
    Write-Warn "System is domain-joined. This deviates from the design."
}

# ---------------------------------------------------------------------------
# 2) Local administrators exposure
# ---------------------------------------------------------------------------
# WHY
# ---
# Admin sprawl is the #1 SMB security problem.
# Visibility is more important than automation.
# ---------------------------------------------------------------------------

Write-Section "Local Administrators"

$admins = Get-LocalGroupMember -Group "Administrators"

foreach ($admin in $admins) {
    Write-Info "Admin member: $($admin.Name)"
}

# Quick signal
$unexpectedAdmins = $admins | Where-Object {
    $_.Name -notmatch "admin\.local|admin\.recovery"
}

if ($unexpectedAdmins) {
    Write-Warn "Unexpected admin accounts detected. Review required."
}

# ---------------------------------------------------------------------------
# 3) Windows Defender status
# ---------------------------------------------------------------------------

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

# removed alternative code block below
# ---------------------------------------------------------------------------
# ALTERNATIVE CODE BLOCK FOR DEFENDER STATUS - not used for Get-MpComputerStatus
#Write-Section "Windows Defender"
#try {
#    $mp = Get-MpComputerStatus
#    Write-Info "Antivirus enabled: $($mp.AntivirusEnabled)"
#    Write-Info "Real-time protection: $($mp.RealTimeProtectionEnabled)"
#    if (-not $mp.AntivirusEnabled -or -not $mp.RealTimeProtectionEnabled) {
#        Write-Warn "Defender is not fully enabled."
#    }
#}
#catch {
#    Write-Warn "Unable to query Defender status."
#}

# ---------------------------------------------------------------------------
# 4) Firewall status
# ---------------------------------------------------------------------------

Write-Section "Windows Firewall"

$profiles = Get-NetFirewallProfile
foreach ($p in $profiles) {
    Write-Info "Profile [$($p.Name)] enabled: $($p.Enabled)"
    if (-not $p.Enabled) {
        Write-Warn "Firewall profile '$($p.Name)' is disabled."
    }
}

# ---------------------------------------------------------------------------
# 5) BitLocker status
# ---------------------------------------------------------------------------
# WHY
# ---
# Data-at-rest protection is mandatory in this design.
# ---------------------------------------------------------------------------

Write-Section "BitLocker"

try {
    $vols = Get-BitLockerVolume
    foreach ($v in $vols) {
        Write-Info "Volume $($v.MountPoint): ProtectionStatus = $($v.ProtectionStatus)"
        if ($v.ProtectionStatus -ne 1) {
            Write-Warn "BitLocker NOT enabled on $($v.MountPoint)"
        }
    }
}
catch {
    Write-Warn "BitLocker status not available."
}

# ---------------------------------------------------------------------------
# 6) Mini-debloat markers (policy presence)
# ---------------------------------------------------------------------------
# WHY
# ---
# We do not re-evaluate every tweak; we check that key policies exist.
# ---------------------------------------------------------------------------

Write-Section "Debloat Policy Markers"

$checks = @(
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Name = "DisableConsumerFeatures" },
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"; Name = "AllowNewsAndInterests" }
)

foreach ($c in $checks) {
    $val = Get-ItemProperty -Path $c.Path -Name $c.Name -ErrorAction SilentlyContinue
    if ($null -eq $val) {
        Write-Warn "Missing policy: $($c.Path)\$($c.Name)"
    } else {
        Write-Info "Policy OK: $($c.Path)\$($c.Name)"
    }
}

# ---------------------------------------------------------------------------
# 7) Chocolatey presence
# ---------------------------------------------------------------------------

Write-Section "Chocolatey"

if (Get-Command choco.exe -ErrorAction SilentlyContinue) {
    Write-Info "Chocolatey installed."
} else {
    Write-Warn "Chocolatey NOT installed."
}

# ---------------------------------------------------------------------------
# 8) Host account presence
# ---------------------------------------------------------------------------
# WHY
# ---
# Host account should be temporary. Presence is a warning, not an error.
# ---------------------------------------------------------------------------

Write-Section "Host Account"

$host = Get-LocalUser -Name "host.temp" -ErrorAction SilentlyContinue
if ($host) {
    Write-Warn "Temporary host account EXISTS. Remove if no longer needed."
} else {
    Write-Info "No host account present."
}

# ---------------------------------------------------------------------------
# 9) Summary
# ---------------------------------------------------------------------------

Write-Section "Audit Summary"

Write-Info "Audit completed."
Write-Info "Review WARNINGS above. No automatic remediation performed."
