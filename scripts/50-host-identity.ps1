# ============================================================================
# 50-host-identity.ps1
#
# PURPOSE
# -------
# Define and enforce the basic host identity of the system.
#
# This script establishes how the machine presents itself:
# - name
# - locale
# - timezone
#
# Host identity is foundational and should change rarely.
#
# LIFECYCLE
# ---------
# Stage: 50–59 — Host & Device Identity
#
# RISK CLASS
# ----------
# MEDIUM
# Host identity changes affect discoverability, logging,
# and administrative clarity, but do not directly alter access control.
#
# SCOPE
# -----
# MAY:
# - set computer name
# - configure system locale and timezone
#
# MUST NOT:
# - create or modify user accounts
# - install software
# - change security baselines
# - modify network policy beyond identity-related settings
#
# SAFETY
# ------
# - Idempotent
# - No reboot is forced automatically
# - Changes are explicit and reviewable
#
# CONTRACT
# --------
# This script follows docs/SCRIPT-CONTRACT.md
# and the lifecycle model defined in docs/STRUCTURE.md
# ============================================================================

# ---------------------------------------------------------------------------
# Bootstrap
# ---------------------------------------------------------------------------

$ScriptRoot  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptRoot\.."

. "$ProjectRoot\lib\common.ps1"

Assert-Administrator
Test-PowerShellVersion | Out-Null

Write-Section "Host Identity"

# ---------------------------------------------------------------------------
# Configuration (explicit, readable)
# ---------------------------------------------------------------------------
# Adjust intentionally. These values define how the machine is identified.

$DesiredComputerName = "WIN11-HOST"
$DesiredTimeZone     = "Central Europe Standard Time"
$DesiredSystemLocale = "en-US"

# ---------------------------------------------------------------------------
# 1) Computer name
# ---------------------------------------------------------------------------
# WHY
# ---
# A stable, meaningful hostname improves:
# - logging
# - remote administration
# - audit readability
# ---------------------------------------------------------------------------

Write-Section "Computer Name"

$currentName = $env:COMPUTERNAME

Write-Info "Current computer name: $currentName"
Write-Info "Desired computer name: $DesiredComputerName"

if ($currentName -ieq $DesiredComputerName) {
    Write-Info "Computer name already set correctly."
}
else {
    Write-Warn "Computer name differs from desired value."

    Write-Warn "Renaming computer requires a reboot to take effect."
    Write-Warn "No automatic reboot will be performed."

    Rename-Computer -NewName $DesiredComputerName -Force
    Write-Info "Computer rename scheduled. Reboot manually when appropriate."
}

# ---------------------------------------------------------------------------
# 2) Time zone
# ---------------------------------------------------------------------------
# WHY
# ---
# Correct timezone is critical for:
# - logs
# - certificate validation
# - incident timelines
# ---------------------------------------------------------------------------

Write-Section "Time Zone"

$currentTz = (Get-TimeZone).Id

Write-Info "Current time zone: $currentTz"
Write-Info "Desired time zone: $DesiredTimeZone"

if ($currentTz -eq $DesiredTimeZone) {
    Write-Info "Time zone already correct."
}
else {
    Set-TimeZone -Id $DesiredTimeZone
    Write-Info "Time zone updated."
}

# ---------------------------------------------------------------------------
# 3) System locale
# ---------------------------------------------------------------------------
# WHY
# ---
# System locale affects:
# - default encoding
# - non-Unicode application behavior
# - consistency across systems
# ---------------------------------------------------------------------------

Write-Section "System Locale"

$currentLocale = (Get-WinSystemLocale).Name

Write-Info "Current system locale: $currentLocale"
Write-Info "Desired system locale: $DesiredSystemLocale"

if ($currentLocale -eq $DesiredSystemLocale) {
    Write-Info "System locale already correct."
}
else {
    Set-WinSystemLocale -SystemLocale $DesiredSystemLocale
    Write-Info "System locale updated. A reboot may be required."
}

# ---------------------------------------------------------------------------
# 4) Summary
# ---------------------------------------------------------------------------

Write-Section "Summary"

Write-Info "Host identity configuration completed."
Write-Info "If the computer name or system locale was changed,"
Write-Info "a manual reboot is required for full effect."
