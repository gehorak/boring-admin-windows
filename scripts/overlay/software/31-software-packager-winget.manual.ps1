# ============================================================================
# 31-software-packager-winget.manual.ps1
#
# PURPOSE
# -------
# Ensure WinGet package manager is available and configured
# for the secondary, minimal-compatibility software transport path.
#
# WinGet is treated strictly as a PACKAGE TRANSPORT layer.
#
# LIFECYCLE
# ---------
# Stage: 30–39 — Software Delivery
# Phase: Phase-2 (transport & baseline)
#
# WHY
# ---
# WinGet is the native Windows package manager and provides
# a first-party mechanism for system-level software delivery
# without introducing third-party agents.
# In this repository it remains a secondary path, not a package-equivalent
# replacement for the primary Chocolatey workflow.
#
# DESIGN PRINCIPLES
# -----------------
# - transport only (no lifecycle management)
# - verify native availability
# - explicit acceptance of agreements
# - reduction of background noise and telemetry
#
# NON-GOALS
# ---------
# - software installation beyond verification
# - package upgrades or updates
# - background automation
# - source or policy manipulation beyond documented scope
#
# SAFETY
# ------
# - Idempotent
# - No reboot
# - No software installed by this script
#
# CONTRACT
# --------
# This script follows docs/SCRIPT-CONTRACT.md
# ============================================================================


# ---------------------------------------------------------------------------
# Bootstrap
# ---------------------------------------------------------------------------

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptRoot "..\..")
if (-not (Test-Path (Join-Path $ProjectRoot "core\lib\common.ps1"))) {
    $ProjectRoot = Resolve-Path (Join-Path $ScriptRoot "..\..\..")
}

. (Join-Path $ProjectRoot "core\lib\common.ps1")

$script:HadWarnings = $false

Assert-Administrator
Test-PowerShellVersion | Out-Null

Write-Section "WinGet Package Transport (Secondary Path)"

Write-Warn "This script configures the WinGet transport layer."
Write-Warn "WinGet is a secondary native path and is not treated as package-equivalent to Chocolatey."
Write-Warn "Proceed only with explicit operator intent."
Require-ManualConfirmation


# =============================================================================
# 1) Pre-flight — Availability Check
# =============================================================================
# In Windows 11, WinGet is normally provided via
# Microsoft.DesktopAppInstaller.

if (-not (Get-Command winget.exe -ErrorAction SilentlyContinue)) {

    Write-Warn "WinGet executable not found in PATH."
    Write-Info "Attempting to locate App Installer package..."

    $appInstaller = Get-AppxPackage -AllUsers -Name "Microsoft.DesktopAppInstaller"

    if (-not $appInstaller) {
        Exit-Fatal "WinGet (Microsoft.DesktopAppInstaller) is not installed. Install App Installer from Microsoft Store or GitHub."
    }

    Write-Info "App Installer package detected. WinGet should be available after user sign-in."
}
else {
    Write-Info "WinGet detected: $(winget --version)"
}


# =============================================================================
# 2) Configuration — Telemetry & Noise Reduction
# =============================================================================
# REQUIREMENT:
# - Operational privacy
# - Deterministic, non-interactive behavior

Write-Section "WinGet Configuration Baseline"

Write-Info "Disabling WinGet telemetry and surveys (user-level setting)"
winget settings --enable TelemetryDisabled | Out-Null


# =============================================================================
# 3) Agreements — Non-interactive Execution
# =============================================================================
# Prevents future prompts such as:
# "Do you agree to all source agreements?"

Write-Info "Accepting WinGet source agreements"

winget source update | Out-Null
winget list --name "Windows" --accept-source-agreements | Out-Null


# =============================================================================
# 4) Policy Enforcement — System-wide Defaults
# =============================================================================
# These policies ensure stable behavior regardless of user profile.

$WingetPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinGet"
if (-not (Test-Path $WingetPolicyPath)) {
    New-Item -Path $WingetPolicyPath -Force | Out-Null
}

Write-Info "Enforcing telemetry disablement via policy (HKLM)"
New-ItemProperty `
    -Path $WingetPolicyPath `
    -Name "DisableTelemetry" `
    -PropertyType DWord `
    -Value 1 `
    -Force | Out-Null


# =============================================================================
# 5) Verification
# =============================================================================

Write-Section "Verification"

try {
    $testSearch = winget search "PowerShell" --limit 1 --accept-source-agreements

    if ($testSearch -match "msft.powershell") {
        Write-Info "Verification successful: WinGet can reach sources."
    }
    else {
        Write-WarnFlagged "Verification inconclusive: search result did not match expected output." ([ref]$script:HadWarnings)
    }
}
catch {
    Write-WarnFlagged "Verification failed: WinGet sources may be temporarily unreachable." ([ref]$script:HadWarnings)
}


# =============================================================================
# 6) Guarantees — Intentional Non-Actions
# =============================================================================

Write-Section "Guarantees"

Write-Info "This script does NOT:"
Write-Info "- install or upgrade any software packages"
Write-Info "- enable experimental WinGet features"
Write-Info "- modify firewall or network policy"
Write-Info "- introduce background automation"
Write-Info "- change system security baselines"


# =============================================================================
# 7) Summary
# =============================================================================

Write-Section "Summary"

Write-Info "WinGet package transport verified and configured."
Write-Info "System is ready for controlled software delivery scripts."

Exit-Warn
