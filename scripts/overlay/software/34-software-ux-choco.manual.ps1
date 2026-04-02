# ============================================================================
# 34-software-ux-choco.manual.ps1
#
# PURPOSE
# -------
# Install a curated UX-oriented software baseline using Chocolatey.
#
# This baseline improves day-to-day usability and operator experience
# while remaining role-agnostic and non-invasive.
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
# security policy, identity, or system enforcement.
#
# SCOPE
# -----
# MAY:
# - install explicitly listed UX baseline applications
# - use Chocolatey strictly as a package transport
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

Write-Section "Software UX Baseline (Chocolatey)"

Write-Warn "This script installs optional UX software."
Write-Warn "Proceed only with explicit operator intent."
Require-ManualConfirmation


# ---------------------------------------------------------------------------
# UX baseline package definition
# ---------------------------------------------------------------------------
# Curated, operator-friendly applications.
# Focus: clarity, stability, and long-term usability.

$UxBaselinePackages = @(

    # ---------------------------------------------------------------------
    # Identity & security (clean UI, long-term viable)
    # ---------------------------------------------------------------------
    "keepassxc",        # Modern password manager with passkey support


    # ---------------------------------------------------------------------
    # Editors & documents
    # ---------------------------------------------------------------------
    "kate",             # Lightweight, future-proof text editor
    "okular",           # Minimalist document viewer (PDF, etc.)


    # ---------------------------------------------------------------------
    # Media & interaction
    # ---------------------------------------------------------------------
    "vlc",              # Universal media player
    # "sharex",           # Screenshot & capture utility (powerful, explicit)
    "eartrumpet",       # Per-app volume control (Windows-native UX)
    # "imageglass",       # Modern image viewer
    "quicklook",        # Instant preview (Space-like UX)


    # ---------------------------------------------------------------------
    # Maintenance & storage
    # ---------------------------------------------------------------------
    #"wisediskcleaner",  # Native, fast disk cleanup (non-GTK)


    # ---------------------------------------------------------------------
    # Connectivity & access
    # ---------------------------------------------------------------------
    "rustdesk",         # Remote access with clean UI
    "localsend",        # Simple, modern local file transfer
    "kdeconnect"        # Device integration (phone ↔ desktop)
)


# ---------------------------------------------------------------------------
# Execution
# ---------------------------------------------------------------------------

Write-Section "UX Baseline Installation"

foreach ($pkg in $UxBaselinePackages) {
    Write-Info "Installing UX baseline package: $pkg"

    & choco install $pkg `
        -y `
        --no-progress `
        --limit-output

    if ($LASTEXITCODE -ne 0) {
        Write-WarnFlagged "Chocolatey returned non-zero exit code ($LASTEXITCODE) for $pkg" ([ref]$script:HadWarnings)
    }
}


# ---------------------------------------------------------------------------
# Verification
# ---------------------------------------------------------------------------

Write-Section "Verification"

foreach ($pkg in $UxBaselinePackages) {
    if (& choco list --local-only --exact $pkg) {
        Write-Info "Verified: $pkg installed"
    }
    else {
        Write-WarnFlagged "Package '$pkg' not found in local Chocolatey inventory" ([ref]$script:HadWarnings)
    }
}

Write-Info "UX baseline installation completed."

Exit-Warn
