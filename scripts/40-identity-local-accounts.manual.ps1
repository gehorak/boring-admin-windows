# ============================================================================
# 40-identity-local-accounts.manual.ps1
#
# PURPOSE
# -------
# Establish and enforce a minimal, explicit local account model
# for Windows 11 systems in SMB / non-domain environments.
#
# This script defines who is allowed to administer the system
# and how emergency access is handled.
#
# LIFECYCLE
# ---------
# Stage: 40–49 — Identity & Access
#
# RISK CLASS
# ----------
# HIGH
# Identity changes directly affect system ownership and access.
#
# ACCOUNT MODEL
# -------------
# - admin.local      : primary local administrator (enabled)
# - admin.recovery   : break-glass administrator (disabled)
# - users            : Microsoft accounts, standard users
#
# PHILOSOPHY
# ----------
# - administrative accounts are NEVER used for daily work
# - standard users NEVER receive administrative rights
# - recovery access exists but remains dormant
#
# SCOPE
# -----
# MAY:
# - verify presence and state of local administrator accounts
# - create explicitly defined local admin accounts
# - enforce Administrators group membership for managed accounts
#
# MUST NOT:
# - create or manage Microsoft / cloud identities
# - automatically convert user account types
# - rotate or reset passwords without human interaction
# - apply account lockout or authentication policy
#
# MODE
# ----
# MANUAL
# - Requires explicit human interaction
# - Prompts for credentials
# - Must not be executed unattended or in CI
#
# SAFETY
# ------
# - Explicit, reviewable actions only
# - No hidden or implicit identity changes
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

Write-Section "Local User Accounts Baseline"

# ---------------------------------------------------------------------------
# Configuration (explicit, readable)
# ---------------------------------------------------------------------------

$PrimaryAdminName   = "admin.LOCAL"
$RecoveryAdminName  = "admin.RECOVERY"

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
