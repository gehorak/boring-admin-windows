# ============================================================================
# 32-software-baseline-choco.manual.ps1
#
# PURPOSE
# -------
# Install a minimal, explicit software baseline using Chocolatey.
#
# This baseline defines a consciously selected set of
# role-agnostic, long-term stable tools expected on
# every administered system.
#
# LIFECYCLE
# ---------
# Stage: 30–39 — Software
#
# RISK CLASS
# ----------
# MEDIUM
# Software installation changes system state but does not
# alter security policy or identity.
#
# SCOPE
# -----
# MAY:
# - install explicitly listed baseline packages
# - use Chocolatey strictly as a transport mechanism
#
# MUST NOT:
# - install role-specific or developer stacks
# - auto-upgrade existing software
# - introduce background services or scheduled tasks
#
# NON-GOALS
# ---------
# - developer tooling
# - user personalization
# - opinionated workflows
#
# SAFETY
# ------
# - MANUAL execution only
# - Explicit package list
# - No automatic upgrades
# - No reboot
#
# CONTRACT
# --------
# This script follows docs/ARCHITECTURE.md
# and the lifecycle model defined in docs/ARCHITECTURE.md
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
. (Join-Path $ProjectRoot "core\lib\config.ps1")

$script:HadWarnings = $false
$config = Import-BoringAdminConfigOrFail

Assert-Administrator
Test-PowerShellVersion | Out-Null

Write-Section "Software Baseline (Chocolatey)"

Write-Warn "This script installs baseline software packages."
Write-Warn "Proceed only with explicit operator intent."
Require-ManualConfirmation


# ---------------------------------------------------------------------------
# Baseline package definition
# ---------------------------------------------------------------------------
# Minimal, stable, role-agnostic tools only.
# These packages are expected to remain usable
# across multiple system lifecycles.

$BaselinePackages = Get-BoringAdminSoftwarePackageList -Config $config -PackageClass baseline -PackageManager choco


# ---------------------------------------------------------------------------
# Execution
# ---------------------------------------------------------------------------

Write-Section "Baseline Installation"

foreach ($pkg in $BaselinePackages) {
    Write-Info "Installing baseline package: $pkg"
    choco install $pkg -y --no-progress --limit-output --skip-powershell-check

    if ($LASTEXITCODE -ne 0) {
        Write-WarnFlagged "Chocolatey returned non-zero exit code ($LASTEXITCODE) for $pkg" ([ref]$script:HadWarnings)
    }
}


# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------

Write-Section "Verification"

foreach ($pkg in $BaselinePackages) {
    if (& choco list --local-only --exact $pkg) {
        Write-Info "Verified: $pkg installed"
    }
    else {
        Write-WarnFlagged "Package '$pkg' may not be available or requires PATH refresh" ([ref]$script:HadWarnings)
    }
}

Write-Info "Software baseline installation completed."

Exit-Warn
