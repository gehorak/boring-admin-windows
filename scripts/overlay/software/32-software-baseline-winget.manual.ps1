# ============================================================================
# 32-software-baseline-winget.manual.ps1
#
# PURPOSE
# -------
# Install a minimal, explicit secondary software baseline using WinGet.
#
# This baseline defines a consciously selected subset of
# role-agnostic, long-term stable tools for environments
# that intentionally use the secondary WinGet path.
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
# - use WinGet strictly as a transport mechanism
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

Write-Section "Software Baseline (WinGet Secondary Minimal Path)"

Write-Warn "This script installs baseline software packages."
Write-Warn "This is a secondary minimal path and does not mirror the full Chocolatey baseline."
Write-Warn "Proceed only with explicit operator intent."
Require-ManualConfirmation


# ---------------------------------------------------------------------------
# Baseline package definition
# ---------------------------------------------------------------------------
# Minimal, stable, role-agnostic tools only.
# Explicit WinGet IDs are used where the repository expects a stable
# long-term package identity for the secondary path.

$BaselinePackages = Get-BoringAdminSoftwarePackageList -Config $config -PackageClass baseline -PackageManager winget


# ---------------------------------------------------------------------------
# Execution
# ---------------------------------------------------------------------------

Write-Section "Baseline Installation"

foreach ($pkg in $BaselinePackages) {
    Write-Info "Installing baseline package: $pkg"

    & winget install `
        --id $pkg `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements

    if ($LASTEXITCODE -ne 0) {
        Write-WarnFlagged "WinGet returned non-zero exit code ($LASTEXITCODE) for $pkg" ([ref]$script:HadWarnings)
    }
}


# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------

Write-Section "Verification"

foreach ($pkg in $BaselinePackages) {
    & winget list --id $pkg --accept-source-agreements > $null 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Info "Verified: $pkg installed"
    }
    else {
        Write-WarnFlagged "Package '$pkg' not found in WinGet inventory" ([ref]$script:HadWarnings)
    }
}

Write-Info "Software baseline installation completed."
Write-Info "If you require the broader admin/tooling baseline, use the primary Chocolatey path."

Exit-Warn
