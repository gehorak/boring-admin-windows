# ============================================================================
# 40-host.ps1
#
# PURPOSE
# -------
# Create or remove a TEMPORARY local guest-style account on demand.
#
# USE CASES
# ---------
# - short-term visitor
# - temporary workstation sharing
# - troubleshooting with minimal privileges
#
# ACCOUNT MODEL
# -------------
# - local account
# - standard user (NO admin rights)
# - password required
# - account is temporary by design
#
# IMPORTANT
# ---------
# This is NOT the built-in Windows "Guest" account.
# That account is deprecated and insecure.
#
# PHILOSOPHY
# ----------
# - temporary access should be explicit
# - removal should be as easy as creation
# - no persistent privilege creep
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

$HostUserName = "host.temp"
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
