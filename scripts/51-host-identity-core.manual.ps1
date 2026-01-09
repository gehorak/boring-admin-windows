# ============================================================================
# 51-host-identity-core.manual.ps1
#
# PURPOSE
# -------
# Define and enforce the CORE host identity state of the system.
#
# This script establishes the authoritative identity of the machine:
# - computer name
# - system time zone
# - system locale (non-Unicode)
#
# Host identity is GLOBAL, RARELY CHANGED, and ADMIN-OWNED.
#
# LIFECYCLE
# ---------
# Stage: 50–59 — Host & Device Identity
#
# MODE
# ----
# MANUAL
# - Explicit human intent required
# - Not safe for unattended execution
# - Must not be executed in CI
#
# RISK CLASS
# ----------
# MEDIUM
# Changes affect discoverability, logging, and diagnostics,
# but do not directly modify access control.
#
# SCOPE
# -----
# MAY:
# - set computer name
# - set system time zone
# - set system locale (non-Unicode)
#
# MUST NOT:
# - create or modify user accounts
# - install software
# - change security baselines
# - modify network configuration
# - force reboot or restart services
#
# EXIT MODEL
# ----------
# Variant A:
# - exit 0 : completed (with or without warnings)
# - exit 1 : fatal error only
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

Write-Section "51-host-identity — Core Host Identity (MANUAL)"


# ============================================================================
# 2. DESIRED HOST IDENTITY STATE (AUTHORITATIVE)
# ============================================================================
# Adjust intentionally. These values define how the machine is identified.
# ============================================================================
# NOTE:
# - Changes are explicit and reviewable
# - No automatic reboot is performed
# ============================================================================

$DesiredComputerName = "WIN11-HOST"
$DesiredTimeZone     = "Central Europe Standard Time"
$DesiredSystemLocale = "en-US"


# ============================================================================
# 3. APPLY — COMPUTER NAME
# ============================================================================
# WHY:
# - Primary machine identifier
# - Appears in logs, certificates, and remote management
# ============================================================================

Write-Section "Computer Name"

$currentName = $env:COMPUTERNAME

Write-Info "Current computer name : $currentName"
Write-Info "Desired computer name : $DesiredComputerName"

if ($currentName -ieq $DesiredComputerName) {
    Write-OK "Computer name already matches desired state."
}
else {
    Write-WarnFlagged "Computer name differs from desired state." ([ref]$script:HadWarnings)

    Write-Warn "Renaming the computer requires a reboot to take effect."
    Write-Warn "No automatic reboot will be performed."

    try {
        Rename-Computer -NewName $DesiredComputerName -Force
        Write-Info "Computer rename scheduled. Reboot manually when appropriate."
    }
    catch {
        Exit-Fatal "Failed to schedule computer rename."
    }
}


# ============================================================================
# 4. APPLY — TIME ZONE
# ============================================================================
# WHY:
# - Critical for logs, incident timelines, and certificate validation
# ============================================================================

Write-Section "System Time Zone"

$currentTz = (Get-TimeZone).Id

Write-Info "Current time zone : $currentTz"
Write-Info "Desired time zone : $DesiredTimeZone"

if ($currentTz -eq $DesiredTimeZone) {
    Write-OK "System time zone already matches desired state."
}
else {
    try {
        Set-TimeZone -Id $DesiredTimeZone
        Write-Info "System time zone updated."
    }
    catch {
        Exit-Fatal "Failed to set system time zone."
    }
}


# ============================================================================
# 5. APPLY — SYSTEM LOCALE (NON-UNICODE)
# ============================================================================
# WHY:
# - Affects legacy applications and default encoding behavior
# ============================================================================

Write-Section "System Locale (Non-Unicode)"

$currentLocale = (Get-WinSystemLocale).Name

Write-Info "Current system locale : $currentLocale"
Write-Info "Desired system locale : $DesiredSystemLocale"

if ($currentLocale -eq $DesiredSystemLocale) {
    Write-OK "System locale already matches desired state."
}
else {
    try {
        Set-WinSystemLocale -SystemLocale $DesiredSystemLocale
        Write-WarnFlagged "System locale updated. Reboot required for full effect." ([ref]$script:HadWarnings)
    }
    catch {
        Exit-Fatal "Failed to set system locale."
    }
}


# ============================================================================
# 6. INTENTIONAL NON-ACTIONS
# ============================================================================
# Explicit documentation of what this script does NOT do.
# ============================================================================

Write-Section "Intentional non-actions"

Write-Info "No reboot was performed"
Write-Info "No services were restarted"
Write-Info "No user or group identities were modified"
Write-Info "No network configuration was changed"
Write-Info "No security baselines were altered"


# ============================================================================
# 7. SUMMARY & EXIT
# ============================================================================

Write-Section "Summary"

Write-Info "Host identity core configuration completed."

if ($script:HadWarnings) {
    Write-Warn "One or more changes require a MANUAL reboot to take effect."
    Exit-Warn
}

Exit-Warn