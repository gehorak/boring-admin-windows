# ============================================================================
# 45-identity-local-guest.manual.ps1
#
# PURPOSE
# -------
# Create or remove a temporary local guest-style account
# for short-term, explicitly approved access.
#
# This script provides controlled, time-bound access
# without introducing persistent privileges.
#
# LIFECYCLE
# ---------
# Stage: 40–49 — Identity & Access
#
# RISK CLASS
# ----------
# HIGH
# Identity changes directly affect access control and system ownership.
#
# ACCOUNT MODEL
# -------------
# - local account (no cloud identity)
# - standard user only (NO administrative rights)
# - password required
# - account is temporary by design
#
# USE CASES
# ---------
# - short-term visitor access
# - temporary workstation sharing
# - troubleshooting with minimal privileges
#
# IMPORTANT
# ---------
# This script does NOT use the built-in Windows "Guest" account.
# The built-in Guest account is deprecated and insecure.
#
# PHILOSOPHY
# ----------
# - temporary access must be explicit and intentional
# - removal must be as easy and visible as creation
# - no persistent privilege creep is acceptable
#
# SCOPE
# -----
# MAY:
# - create a single, explicitly named local standard account
# - remove the same account on demand
#
# MUST NOT:
# - grant administrative privileges
# - modify other local or cloud identities
# - alter group policies or security baselines
#
# MODE
# ----
# MANUAL
# - Requires explicit human interaction
# - Prompts for credentials and confirmation
# - Must not be executed unattended or in CI
#
# SAFETY
# ------
# - Explicit, reversible actions only
# - No implicit privilege escalation
# - No reboot
#
# CONTRACT
# --------
# This script follows docs/SCRIPT-CONTRACT.md
# and the lifecycle model defined in docs/STRUCTURE.md
# ============================================================================


# -----------------------------------------------------------------------------
# Bootstrap
# -----------------------------------------------------------------------------

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptRoot\.."

. "$ProjectRoot\lib\common.ps1"


Assert-Administrator
Test-PowerShellVersion | Out-Null

Write-Section "Temporary Host Account"

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

$HostUserName = "guestlocal.TEMP"
$HostDescription = "Temporary host account (created on demand)"

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

function Host-Exists {
    return Get-LocalUser -Name $HostUserName -ErrorAction SilentlyContinue
}

function Create-Host {
    Write-Section "Creating host account"

    if (Host-Exists) {
        Write-Warn "Host account already exists. No action taken."
        return
    }

    $password = Read-Host "Enter password for $HostUserName" -AsSecureString

    New-LocalUser `
        -Name $HostUserName `
        -Password $password `
        -Description $HostDescription `
        -PasswordNeverExpires:$false `
        -UserMayNotChangePassword:$true

    # Ensure STANDARD user only
    Add-LocalGroupMember -Group "Users" -Member $HostUserName

    Write-Info "Host account '$HostUserName' created."
    Write-Warn "Remember to REMOVE this account after use."
}

function Remove-Host {
    Write-Section "Removing host account"

    if (-not (Host-Exists)) {
        Write-Info "Host account does not exist. Nothing to remove."
        return
    }

    Write-Warn "This will permanently DELETE user '$HostUserName'."
    $confirm = Read-Host "Type YES to confirm"

    if ($confirm -ne "YES") {
        Write-Info "Removal aborted by user."
        return
    }

    Remove-LocalUser -Name $HostUserName
    Write-Info "Host account '$HostUserName' removed."
}

# ---------------------------------------------------------------------------
# Main menu (explicit choice)
# ---------------------------------------------------------------------------

Write-Section "Choose action"

Write-Host "1 - Create temporary host account"
Write-Host "2 - Remove temporary host account"
Write-Host "0 - Exit"

$choice = Read-Host "Select action"

switch ($choice) {
    "1" { Create-Host }
    "2" { Remove-Host }
    "0" { Write-Info "No action taken." }
    default { Write-Warn "Invalid selection. No action taken." }
}

Write-Info "Host account script finished."
