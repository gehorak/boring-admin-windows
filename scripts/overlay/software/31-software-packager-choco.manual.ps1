# ============================================================================
# 31-software-packager-choco.manual.ps1
#
# PURPOSE
# -------
# Ensure Chocolatey package manager is installed and configured
# for the primary, controlled, non-interactive software transport path.
#
# Chocolatey is treated strictly as a PACKAGE TRANSPORT layer.
#
# LIFECYCLE
# ---------
# Stage: 30–39 — Software Delivery
# Phase: Phase-2 (transport & baseline)
#
# WHY
# ---
# Chocolatey provides a predictable CLI-based transport mechanism
# for system software installation without relying on GUI workflows.
# It is the primary manually tested software path in this repository.
#
# DESIGN PRINCIPLES
# -----------------
# - transport only (no lifecycle management)
# - explicit installation
# - non-interactive behavior
# - no background activity
#
# NON-GOALS
# ---------
# - automatic upgrades
# - scheduled jobs
# - background services
# - package lifecycle management
#
# SAFETY
# ------
# - Idempotent
# - No reboot
# - No software installed beyond Chocolatey itself
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

function Invoke-ChocolateyBootstrapScript {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Justification = 'Chocolatey bootstrap uses the official upstream install script text and requires explicit evaluation.')]
    param(
        [Parameter(Mandatory)]
        [string] $InstallScript
    )

    Invoke-Expression $InstallScript
}

Assert-Administrator
Test-PowerShellVersion | Out-Null

Write-Section "Chocolatey Package Transport"

Write-Warn "This script installs and configures the Chocolatey transport layer."
Write-Warn "Proceed only with explicit operator intent."
Require-ManualConfirmation


# =============================================================================
# 1) Pre-flight — Availability Check
# =============================================================================

if (Get-Command choco.exe -ErrorAction SilentlyContinue) {
    Write-Info "Chocolatey is already installed. No action required."
}
else {
    Write-Info "Chocolatey not found. Proceeding with explicit installation."


    # ------------------------------------------------------------------------
    # 2) Installation — Official Bootstrap Script
    # ------------------------------------------------------------------------
    # REQUIREMENT:
    # - Secure transport (TLS 1.2+)
    # - Official upstream source only
    # - No silent background modifications beyond Chocolatey itself

    Write-Info "Enforcing TLS 1.2+ for secure download"
    [Net.ServicePointManager]::SecurityProtocol =
        [Net.ServicePointManager]::SecurityProtocol -bor 3072

    Write-Info "Downloading and executing official Chocolatey install script"
    $installScript = Invoke-RestMethod -Uri 'https://community.chocolatey.org/install.ps1'
    Invoke-ChocolateyBootstrapScript -InstallScript $installScript


    # ------------------------------------------------------------------------
    # 3) PATH Refresh (current session)
    # ------------------------------------------------------------------------
    # Chocolatey updates system PATH, but the current PowerShell session
    # does not automatically inherit it.

    Write-Info "Refreshing PATH for current session"
    $env:Path =
        [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
        [System.Environment]::GetEnvironmentVariable("Path", "User")
}


# =============================================================================
# 4) Verification — Sanity Check
# =============================================================================

if (-not (Get-Command choco.exe -ErrorAction SilentlyContinue)) {
    Exit-Fatal "Verification failed: choco.exe not available in PATH."
}

Write-Info "Chocolatey executable detected"
Write-Info "Chocolatey version: $(choco --version)"


# =============================================================================
# 5) Configuration — Hard Rules
# =============================================================================
# These settings are REQUIRED to ensure deterministic, non-interactive behavior
# for all subsequent software delivery scripts.

Write-Section "Chocolatey Configuration Baseline"

# Enable global confirmation to avoid interactive prompts
Write-Info "Enabling global confirmation (allowGlobalConfirmation)"
choco feature enable -n allowGlobalConfirmation | Out-Null

# Disable non-official confirmation messages and noise
Write-Info "Disabling non-official confirmation messages"
choco config set -n showNonOfficialConfirmationMessages -v false | Out-Null


# =============================================================================
# 6) Guarantees — Intentional Non-Actions
# =============================================================================

Write-Section "Guarantees"

Write-Info "This script does NOT:"
Write-Info "- install any application packages"
Write-Info "- enable automatic upgrades"
Write-Info "- register scheduled tasks"
Write-Info "- modify system security policy"
Write-Info "- introduce background services"


# =============================================================================
# 7) Summary
# =============================================================================

Write-Section "Summary"

Write-Info "Chocolatey package transport is installed and configured."
Write-Info "System is ready for controlled software delivery scripts."

Exit-Warn
