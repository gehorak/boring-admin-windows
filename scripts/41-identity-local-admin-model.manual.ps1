# ============================================================================
# 41-identity-local-admin-model.manual.ps1
#
# PURPOSE
# -------
# Establish and maintain an explicit local administrator model
# for Windows 11 systems in SMB / non-domain environments.
#
# This script enforces the EXPECTED STATE of local administrators,
# not individual CRUD operations.
#
# LIFECYCLE
# ---------
# Stage: 40–49 — Identity & Access
#
# MODE
# ----
# MANUAL
# - Requires explicit human confirmation
# - Prompts for credentials
# - Must NOT be executed unattended or in CI
#
# ACCOUNT MODEL (EXPECTED STATE)
# ------------------------------
# - admin.LOCAL     : primary local administrator (ENABLED)
# - admin.RECOVERY  : break-glass administrator (DISABLED)
#
# EXIT MODEL
# ----------
# Variant A:
# - exit 0 : completed (with or without warnings)
# - exit 1 : fatal error only
#
# CONTRACT
# --------
# Follows docs/SCRIPT-CONTRACT.md and docs/STRUCTURE.md
# ============================================================================


# ============================================================================
# 0. BOOTSTRAP
# ============================================================================

$ScriptRoot  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptRoot\.."

. "$ProjectRoot\lib\common.ps1"

# Initialize warning state  
$script:HadWarnings = $false


# ============================================================================
# 1. EXECUTION CONTEXT
# ============================================================================

Assert-Administrator
Test-PowerShellVersion | Out-Null

Write-Section "41-identity — Local Administrator Model (MANUAL)"


# ============================================================================
# 2. CONFIGURATION (EXPLICIT, REVIEWABLE)
# ============================================================================

$PrimaryAdminName  = "admin.LOCAL"
$RecoveryAdminName = "admin.RECOVERY"


# ============================================================================
# 3. OBSERVE — CURRENT STATE
# ============================================================================
# Observation only. No decisions, no changes.
# ============================================================================

Write-Section "Observe current administrator state"

function Get-LocalUserSafe {
    param([string]$Name)

    try {
        return Get-LocalUser -Name $Name -ErrorAction Stop
    }
    catch {
        return $null
    }
}

$PrimaryAdmin  = Get-LocalUserSafe -Name $PrimaryAdminName
$RecoveryAdmin = Get-LocalUserSafe -Name $RecoveryAdminName

if ($PrimaryAdmin) {
    Write-Info "Primary admin exists: $PrimaryAdminName (Enabled: $($PrimaryAdmin.Enabled))"
} else {
    Write-Info "Primary admin does not exist: $PrimaryAdminName"
}

if ($RecoveryAdmin) {
    Write-Info "Recovery admin exists: $RecoveryAdminName (Enabled: $($RecoveryAdmin.Enabled))"
} else {
    Write-Info "Recovery admin does not exist: $RecoveryAdminName"
}


# ============================================================================
# 4. DECIDE — OPERATOR CONFIRMATION
# ============================================================================
# Identity changes require explicit human consent.
# ============================================================================

Write-Section "Confirm intent"

Write-Warn "This script will ENFORCE the local administrator model."
Write-Warn "Proceed only if you understand the identity implications."

$confirm = Read-Host "Type YES to continue"
if ($confirm -ne "YES") {
    Write-WarnFlagged "Operation aborted by operator."
    Exit-Warn
}


# ============================================================================
# 5. APPLY — PRIMARY ADMINISTRATOR (EXPECTED: ENABLED)
# ============================================================================

Write-Section "Apply admin model: Primary administrator"

if (-not $PrimaryAdmin) {

    Write-Info "Creating primary administrator: $PrimaryAdminName"
    $password = Read-Host "Enter password for $PrimaryAdminName" -AsSecureString

    try {
        New-LocalUser `
            -Name $PrimaryAdminName `
            -Password $password `
            -Description "Primary local administrator" `
            -PasswordNeverExpires:$false `
            -UserMayNotChangePassword:$true `
            -ErrorAction Stop

        Add-LocalGroupMember -Group "Administrators" -Member $PrimaryAdminName -ErrorAction Stop
        Write-Info "Primary administrator created and added to Administrators."
    }
    catch {
        Exit-Fatal "Failed to create primary administrator '$PrimaryAdminName'."
    }
}
elseif (-not $PrimaryAdmin.Enabled) {
    try {
        Enable-LocalUser -Name $PrimaryAdminName -ErrorAction Stop
        Write-Info "Primary administrator enabled."
    }
    catch {
        Exit-Fatal "Failed to enable primary administrator '$PrimaryAdminName'."
    }
}
else {
    Write-Info "Primary administrator already exists and is enabled."
}


# ============================================================================
# 6. APPLY — RECOVERY ADMINISTRATOR (EXPECTED: DISABLED)
# ============================================================================

Write-Section "Apply admin model: Recovery administrator"

if (-not $RecoveryAdmin) {

    Write-Info "Creating recovery administrator: $RecoveryAdminName"
    $password = Read-Host "Enter password for $RecoveryAdminName" -AsSecureString

    try {
        New-LocalUser `
            -Name $RecoveryAdminName `
            -Password $password `
            -Description "Recovery administrator (disabled)" `
            -PasswordNeverExpires:$false `
            -UserMayNotChangePassword:$true `
            -ErrorAction Stop

        Add-LocalGroupMember -Group "Administrators" -Member $RecoveryAdminName -ErrorAction Stop
        Disable-LocalUser -Name $RecoveryAdminName -ErrorAction Stop

        Write-Info "Recovery administrator created, added to Administrators, and disabled."
    }
    catch {
        Exit-Fatal "Failed to create recovery administrator '$RecoveryAdminName'."
    }
}
elseif ($RecoveryAdmin.Enabled) {
    try {
        Disable-LocalUser -Name $RecoveryAdminName -ErrorAction Stop
        Write-Info "Recovery administrator disabled."
    }
    catch {
        Exit-Fatal "Failed to disable recovery administrator '$RecoveryAdminName'."
    }
}
else {
    Write-Info "Recovery administrator already exists and is disabled."
}


# ============================================================================
# 7. VERIFY — ADMINISTRATORS GROUP VISIBILITY
# ============================================================================
# Visibility only. No automated removal.
# ============================================================================

Write-Section "Verify: Administrators group membership"

try {
    Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop |
        ForEach-Object {
            Write-Info "Administrator member: $($_.Name)"
        }
}
catch {
    Write-WarnFlagged "Unable to enumerate Administrators group."
}

Write-WarnFlagged "Verify manually that NO regular user accounts are administrators."


# ============================================================================
# 8. INTENTIONAL NON-ACTIONS
# ============================================================================

Write-Section "Intentional non-actions"

Write-Info "No Microsoft or cloud identities were modified"
Write-Info "No regular user accounts were altered"
Write-Info "No passwords were rotated automatically"
Write-Info "No account lockout or authentication policies were changed"


# ============================================================================
# 9. COMPLETION & EXIT STRATEGY
# ============================================================================

Write-Section "Summary"
Write-Info "Local administrator model enforcement completed."

Exit-Warn
