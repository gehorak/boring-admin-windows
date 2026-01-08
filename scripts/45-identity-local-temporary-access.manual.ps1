# ============================================================================
# 45-identity-local-temporary-access.manual.ps1
#
# PURPOSE
# -------
# Manage temporary local access as an explicit, time-bound STATE
# on Windows 11 systems in SMB / non-domain environments.
#
# This script DOES NOT provide generic user management.
# It ensures that temporary access is either:
# - explicitly enabled, or
# - explicitly absent.
#
# LIFECYCLE
# ---------
# Stage: 40–49 — Identity & Access
#
# MODE
# ----
# MANUAL
# - Requires explicit human interaction
# - Must NOT be executed unattended or in CI
#
# TEMPORARY ACCESS MODEL (EXPECTED STATE)
# --------------------------------------
# - guest.TEMP : local STANDARD user
#   - no administrative rights
#   - password required
#   - existence is intentional and visible
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

# Initialize warning state for this script
$script:HadWarnings = $false


# ============================================================================
# 1. EXECUTION CONTEXT
# ============================================================================

Assert-Administrator
Test-PowerShellVersion | Out-Null

Write-Section "45-identity — Temporary Local Access (MANUAL)"


# ============================================================================
# 2. CONFIGURATION (EXPLICIT, REVIEWABLE)
# ============================================================================

$TempUserName    = "guest.TEMP"
$TempDescription = "Temporary local access account (manual)"


# ============================================================================
# 3. OBSERVE — CURRENT STATE
# ============================================================================
# Observation only. No decisions or changes here.
# ============================================================================

Write-Section "Observe current state"

try {
    $TempUser = Get-LocalUser -Name $TempUserName -ErrorAction Stop
    Write-Info "Temporary access account exists: $TempUserName (Enabled: $($TempUser.Enabled))"
}
catch {
    $TempUser = $null
    Write-Info "Temporary access account does not exist: $TempUserName"
}


# ============================================================================
# 4. DECIDE — OPERATOR INTENT
# ============================================================================
# Explicit choice of TARGET STATE.
# ============================================================================

Write-Section "Select target state"

Write-Host "1 - ENABLE temporary access (create account if missing)"
Write-Host "2 - DISABLE temporary access (remove account)"
Write-Host "0 - Exit without changes"

$choice = Read-Host "Select action"

switch ($choice) {

    # ------------------------------------------------------------------------
    # ENABLE temporary access
    # ------------------------------------------------------------------------
    "1" {
        if ($TempUser) {
            Write-WarnFlagged "Temporary access account already exists. No creation performed."
            break
        }

        Write-Section "Apply: Enable temporary access"

        $password = Read-Host "Enter password for $TempUserName" -AsSecureString

        try {
            New-LocalUser `
                -Name $TempUserName `
                -Password $password `
                -Description $TempDescription `
                -PasswordNeverExpires:$false `
                -UserMayNotChangePassword:$true `
                -ErrorAction Stop

            Add-LocalGroupMember -Group "Users" -Member $TempUserName -ErrorAction Stop

            Write-Info "Temporary access account created: $TempUserName"
            Write-WarnFlagged "Temporary access ENABLED. Remember to disable it after use."
        }
        catch {
            Exit-Fatal "Failed to enable temporary access account '$TempUserName'."
        }
    }

    # ------------------------------------------------------------------------
    # DISABLE temporary access
    # ------------------------------------------------------------------------
    "2" {
        if (-not $TempUser) {
            Write-WarnFlagged "Temporary access account does not exist. Nothing to disable."
            break
        }

        Write-Section "Apply: Disable temporary access"

        Write-Warn "This will PERMANENTLY delete local user '$TempUserName'."
        $confirm = Read-Host "Type YES to confirm"

        if ($confirm -ne "YES") {
            Write-WarnFlagged "Disable operation aborted by operator."
            break
        }

        try {
            Remove-LocalUser -Name $TempUserName -ErrorAction Stop
            Write-Info "Temporary access account removed: $TempUserName"
        }
        catch {
            Exit-Fatal "Failed to remove temporary access account '$TempUserName'."
        }
    }

    # ------------------------------------------------------------------------
    # NO ACTION
    # ------------------------------------------------------------------------
    "0" {
        Write-Info "No action taken."
    }

    default {
        Write-WarnFlagged "Invalid selection. No action taken."
    }
}


# ============================================================================
# 5. INTENTIONAL NON-ACTIONS
# ============================================================================

Write-Section "Intentional non-actions"

Write-Info "No administrative privileges were granted"
Write-Info "No other local or cloud identities were modified"
Write-Info "No policies or security baselines were changed"
Write-Info "No automatic expiration or scheduling is applied"


# ============================================================================
# 6. COMPLETION & EXIT STRATEGY
# ============================================================================

Write-Section "Summary"
Write-Info "Temporary access state handling completed."

Exit-Warn
