# ============================================================================
# 34-software-ux-winget.manual.ps1
#
# PURPOSE
# -------
# Install a curated UX-oriented software baseline using WinGet.
#
# This baseline improves daily usability and operator experience
# while remaining role-agnostic and explicit.
# It is the secondary reduced UX path, not a full package-equivalent
# mirror of the Chocolatey UX set.
#
# IMPORTANT
# ---------
# - This script is NEVER executed by default.
# - Execution is a conscious, manual decision.
#
# LIFECYCLE
# ---------
# Stage: 30–39 — Software
#
# RISK CLASS
# ----------
# MEDIUM
# Installs user-facing software but does not modify
# security policy, identity, or enforcement.
#
# SCOPE
# -----
# MAY:
# - install explicitly listed UX baseline applications
# - use WinGet strictly as a transport mechanism
#
# MUST NOT:
# - install developer stacks
# - install background agents with hidden behavior
# - auto-upgrade existing software
#
# NON-GOALS
# ---------
# - development tooling
# - system hardening
# - user personalization or theming
#
# SAFETY
# ------
# - MANUAL execution only
# - Explicit package list
# - No reboot
#
# CONTRACT
# --------
# This script follows docs/SCRIPT-CONTRACT.md
# and the lifecycle model defined in docs/STRUCTURE.md
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

Write-Section "Software UX Baseline (WinGet Secondary Path)"

Write-Warn "This script installs optional UX software."
Write-Warn "WinGet UX is a reduced secondary path and does not mirror the full Chocolatey UX choice set."
Write-Warn "Proceed only with explicit operator intent."
Require-ManualConfirmation


# ---------------------------------------------------------------------------
# UX baseline package definition
# ---------------------------------------------------------------------------
# Explicit WinGet package IDs.
# Focus: clarity, long-term usability, minimal background behavior.

$UxBaselinePackages = @(

    # ---------------------------------------------------------------------
    # Identity & security
    # ---------------------------------------------------------------------
    "KeePassXCTeam.KeePassXC",


    # ---------------------------------------------------------------------
    # Editors & documents
    # ---------------------------------------------------------------------
    "KDE.Kate",
    "KDE.Okular",


    # ---------------------------------------------------------------------
    # Media & interaction
    # ---------------------------------------------------------------------
    "VideoLAN.VLC",
    "File-New-Project.EarTrumpet",
    "QL-Win.QuickLook",


    # ---------------------------------------------------------------------
    # Connectivity & access
    # ---------------------------------------------------------------------
    "RustDesk.RustDesk",
    "LocalSend.LocalSend",
    "KDE.KDEConnect"
)


# ---------------------------------------------------------------------------
# Execution
# ---------------------------------------------------------------------------

Write-Section "UX Baseline Installation"

foreach ($pkg in $UxBaselinePackages) {
    Write-Info "Processing UX baseline package: $pkg"

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

foreach ($pkg in $UxBaselinePackages) {
    & winget list --id $pkg --accept-source-agreements > $null 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Info "Verified: $pkg installed"
    }
    else {
        Write-WarnFlagged "Package '$pkg' not found in WinGet inventory" ([ref]$script:HadWarnings)
    }
}

Write-Info "UX baseline installation completed."
Write-Info "For the broader curated UX choice set, use the primary Chocolatey UX path."

Exit-Warn
