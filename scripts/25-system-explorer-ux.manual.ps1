# ============================================================================
# 25-system-explorer-ux.manual.ps1
#
# PURPOSE
# -------
# Apply a minimal, explainable USER EXPERIENCE baseline
# focused on HUMAN-FACTOR SAFETY and OPERATIONAL CLARITY.
#
# This script reduces risk caused by misleading defaults
# and accidental user actions.
#
# LIFECYCLE
# ---------
# Stage: 20–29 — Security & System Policy
# Sub-layer: Human-Factor UX Baseline
#
# MODE
# ----
# MANUAL
# - Explicit human execution required
# - Safe to run repeatedly
#
# RISK CLASS
# ----------
# LOW
# Changes affect UX defaults only.
#
# SCOPE
# -----
# MAY:
# - configure Explorer and shell defaults
# - reduce risk of user mistakes
# - increase system transparency
#
# MUST NOT:
# - change security baselines (Defender, Firewall, BitLocker)
# - modify Windows Update behavior
# - alter power management or performance policy
# - apply aggressive or opaque registry hardening
#
# DESIGN PRINCIPLES
# -----------------
# - clarity over aesthetics
# - predictability over convenience
# - error prevention over personalization
# - explainable changes only
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

Write-Section "25-system-explorer-ux — Phase-1 (MANUAL)"


# ============================================================================
# 2. UX BASELINE INTENT
# ============================================================================
# Explicitly define what this script is responsible for.
# ============================================================================

Write-Section "UX baseline intent"

Write-Info "This UX baseline focuses on:"
Write-Info "- preventing common user mistakes"
Write-Info "- improving visibility and transparency"
Write-Info "- reducing misleading defaults"

Write-Host ""
Write-Info "This script does NOT apply personalization or performance tuning."


# ============================================================================
# 3. FILE SYSTEM TRANSPARENCY
# ============================================================================
# WHY:
# - Prevent file type spoofing
# - Improve operator awareness
# ============================================================================

Write-Section "File system transparency"

# Show file extensions (critical for security)
Set-RegistryPreference `
    -KeyPath "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -ValueName "HideFileExt" `
    -Value 0

Write-Info "File extensions are visible."

# Show hidden files (operational clarity)
Set-RegistryPreference `
    -KeyPath "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -ValueName "Hidden" `
    -Value 1

Write-Info "Hidden files are visible."


# ============================================================================
# 4. EXPLORER PREDICTABILITY
# ============================================================================
# WHY:
# - Reduce confusion
# - Improve path awareness
# ============================================================================

Write-Section "Explorer predictability"

# Open Explorer to 'This PC'
Set-RegistryPreference `
    -KeyPath "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -ValueName "LaunchTo" `
    -Value 1

Write-Info "Explorer opens to 'This PC'."

# Show full path in title bar
Set-RegistryPreference `
    -KeyPath "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -ValueName "FullPathAddress" `
    -Value 1

Write-Info "Full path is shown in Explorer title bar."


# ============================================================================
# 5. ACCIDENT PREVENTION
# ============================================================================
# WHY:
# - Prevent accidental destructive UI actions
# ============================================================================

Write-Section "Accident prevention"

# Disable Aero Shake (accidental window minimization)
Set-RegistryPreference `
    -KeyPath "Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -ValueName "DisallowShaking" `
    -Value 1

Write-Info "Aero Shake disabled."


# ============================================================================
# 6. INTENTIONAL NON-ACTIONS
# ============================================================================
# Explicit guarantees for audit clarity.
# ============================================================================

Write-Section "Intentional non-actions"

Write-Info "No Windows Update behavior was modified"
Write-Info "No power or performance settings were changed"
Write-Info "No security policies were altered"
Write-Info "No personalization or visual theming applied"


# ============================================================================
# 7. SUMMARY & EXIT
# ============================================================================

Write-Section "Summary"

Write-Info "Phase-1 UX baseline applied."

if ($script:HadWarnings) {
    Write-Warn "Some UX settings may require review."
    Exit-Warn
}

Exit-Warn
