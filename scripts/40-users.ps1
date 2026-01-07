# ============================================================================
# 30-users.ps1
#
# PURPOSE
# -------
# Establish a sane local account model for Windows 11
# in SMB / no-domain environments.
#
# ACCOUNT MODEL
# -------------
# - admin.local      : primary local administrator (enabled)
# - admin.recovery   : emergency admin (disabled)
# - users            : Microsoft accounts, standard users
#
# PHILOSOPHY
# ----------
# - admin account is NEVER used for daily work
# - users NEVER receive admin rights
# - recovery access exists but is dormant
#
# THIS SCRIPT DOES:
# -----------------
# - verify local admin accounts
# - create missing admin accounts
# - enforce group membership
#
# THIS SCRIPT DOES NOT:
# ---------------------
# - create Microsoft accounts
# - convert user account types
# - reset passwords automatically
#
# WHY
# ---
# Identity decisions must remain explicit and traceable.
# ============================================================================

# -----------------------------------------------------------------------------
# Bootstrap
# -----------------------------------------------------------------------------

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptRoot\.."

. "$ProjectRoot\lib\common.ps1"


Assert-Administrator
Test-PowerShellVersion | Out-Null

Write-Section "Local User Accounts Baseline"

# ---------------------------------------------------------------------------
# Configuration (explicit, readable)
# ---------------------------------------------------------------------------

$PrimaryAdminName   = "admin.local"
$RecoveryAdminName  = "admin.recovery"

# ---------------------------------------------------------------------------
# Helper: ensure local admin exists
# ---------------------------------------------------------------------------

function Ensure-LocalAdmin {
    param (
        [string]$UserName,
        [string]$Description,
        [bool]$Enabled
    )

    $user = Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue

    if (-not $user) {
        Write-Info "Creating local admin account: $UserName"

        $password = Read-Host "Enter password for $UserName" -AsSecureString

        New-LocalUser `
            -Name $UserName `
            -Password $password `
            -Description $Description `
            -PasswordNeverExpires:$false `
            -UserMayNotChangePassword:$true

        Add-LocalGroupMember -Group "Administrators" -Member $UserName
    }
    else {
        Write-Info "Local admin account exists: $UserName"
    }

    # Enforce enabled / disabled state
    if ($Enabled) {
        Enable-LocalUser -Name $UserName
        Write-Info "Account enabled: $UserName"
    }
    else {
        Disable-LocalUser -Name $UserName
        Write-Info "Account disabled: $UserName"
    }
}

# ---------------------------------------------------------------------------
# 1) Primary local administrator
# ---------------------------------------------------------------------------
# WHY
# ---
# This is the only account allowed to perform system administration.
# It must be local, not tied to cloud identity.
# ---------------------------------------------------------------------------

Write-Section "Primary local administrator"

Ensure-LocalAdmin `
    -UserName $PrimaryAdminName `
    -Description "Primary local administrator" `
    -Enabled $true

# ---------------------------------------------------------------------------
# 2) Recovery administrator (disabled)
# ---------------------------------------------------------------------------
# WHY
# ---
# Provides break-glass access if:
# - admin.local password is lost
# - user profile is corrupted
#
# Account is DISABLED by default to reduce attack surface.
# ---------------------------------------------------------------------------

Write-Section "Recovery administrator (break-glass)"

Ensure-LocalAdmin `
    -UserName $RecoveryAdminName `
    -Description "Recovery administrator (disabled)" `
    -Enabled $false

# ---------------------------------------------------------------------------
# 3) Verify local Administrators group
# ---------------------------------------------------------------------------
# WHY
# ---
# Privilege creep is common in SMB environments.
# Visibility is more important than automation here.
# ---------------------------------------------------------------------------

Write-Section "Administrators group membership"

$admins = Get-LocalGroupMember -Group "Administrators"

foreach ($admin in $admins) {
    Write-Info "Administrator member: $($admin.Name)"
}

Write-Warn "Verify manually that NO regular user accounts are administrators."

# ---------------------------------------------------------------------------
# 4) Explicit non-actions (DOCUMENTATION)
# ---------------------------------------------------------------------------
# WHY
# ---
# This script intentionally avoids managing cloud identities.
# ---------------------------------------------------------------------------

Write-Section "Intentional non-actions"

Write-Info "Microsoft accounts are NOT created by this script"
Write-Info "User privilege changes are NOT automated"
Write-Info "Password rotation is a MANUAL process"
Write-Info "Account lockout policies are NOT modified"

Write-Info "Local user baseline completed."
