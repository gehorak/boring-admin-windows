# ============================================================================
# 31-software-packager-choco.manual.ps1
#
# PURPOSE
# -------
# Ensure Chocolatey package manager is available and configured
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
# - explicit manual bootstrap
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
# - No software installed by this script
#
# CONTRACT
# --------
# This script follows docs/ARCHITECTURE.md
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

Write-Section "Chocolatey Package Transport"

Write-Warn "This script configures the Chocolatey transport layer only when Chocolatey is already present."
Write-Warn "Repository policy blocks remote bootstrap via downloaded PowerShell install scripts."
Write-Warn "Proceed only with explicit operator intent."
Require-ManualConfirmation


# =============================================================================
# 1) Pre-flight — Availability Check
# =============================================================================

if (Get-Command choco.exe -ErrorAction SilentlyContinue) {
    Write-Info "Chocolatey is already installed. No action required."
}
else {
    Write-Warn "Chocolatey not found."
    Write-Info "Manual bootstrap is required before this repository will use Chocolatey."
    Write-Info "Trusted source policy:"
    Write-Info "- prefer an internal mirror, offline package, or another operator-verified source"
    Write-Info "- if the upstream installer is used, review it out of band before execution"
    Write-Info "- rerun this script only after choco.exe is available in PATH"
    Exit-Fatal "Chocolatey bootstrap requires manual operator verification."
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

Write-Info "Chocolatey package transport is verified and configured."
Write-Info "System is ready for controlled software delivery scripts."

Exit-Warn
