# ============================================================================
# 40-identity-local-orchestrator.manual.ps1
#
# PURPOSE
# -------
# Provide a human-oriented entry point to the local identity model
# for Windows 11 systems in SMB / non-domain environments.
#
# This script DOES NOT change system state.
# It explains the identity model, shows current visibility,
# and guides the operator to the correct MANUAL scripts.
#
# LIFECYCLE
# ---------
# Stage: 40–49 — Identity & Access
#
# MODE
# ----
# MANUAL
# - Read-only
# - No identity changes
# - No prompts for credentials
# - Safe to run repeatedly
#
# ROLE
# ----
# - Identity overview
# - Operator guidance
# - Explicit navigation
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

Write-Section "40-identity — Local Identity Orchestrator (MANUAL)"


# ============================================================================
# 2. IDENTITY MODEL OVERVIEW
# ============================================================================

Write-Section "Identity model overview"

Write-Info "This system follows a minimal, explicit LOCAL identity model:"
Write-Info "- No domain membership"
Write-Info "- No cloud identity management"
Write-Info "- No automated identity lifecycle"
Write-Info "- All identity changes are MANUAL and reviewable"

Write-Host ""
Write-Info "Expected administrator model:"
Write-Info "- admin.LOCAL    : primary local administrator (ENABLED)"
Write-Info "- admin.RECOVERY : break-glass administrator (DISABLED)"

Write-Host ""
Write-Info "Temporary access model:"
Write-Info "- guest.TEMP     : local STANDARD user"
Write-Info "- Exists only when explicitly enabled"
Write-Info "- Must be removed after use"


# ============================================================================
# 3. CURRENT VISIBILITY (READ-ONLY)
# ============================================================================
# Lightweight visibility without enforcement.
# ============================================================================

Write-Section "Current local identity visibility"

# --- Local administrators ----------------------------------------------------

Write-Info "Local Administrators group members:"

try {
    Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop |
        ForEach-Object {
            Write-Info " - $($_.Name)"
        }
}
catch {
    Write-WarnFlagged "Unable to enumerate local Administrators group."
}

# --- Managed local accounts --------------------------------------------------

Write-Host ""
Write-Info "Managed local accounts status:"

foreach ($name in @("admin.LOCAL", "admin.RECOVERY", "guest.TEMP")) {
    try {
        $u = Get-LocalUser -Name $name -ErrorAction Stop
        Write-Info " - $name : exists (Enabled: $($u.Enabled))"
    }
    catch {
        Write-Info " - $name : does not exist"
    }
}


# ============================================================================
# 4. OPERATOR GUIDANCE
# ============================================================================
# Explicit navigation to MANUAL scripts.
# ============================================================================

Write-Section "Available MANUAL identity actions"

Write-Info "To ENFORCE the local administrator model:"
Write-Info "  -> Run: 41-identity-local-admin-model.manual.ps1"

Write-Host ""
Write-Info "To ENABLE or DISABLE temporary local access:"
Write-Info "  -> Run: 45-identity-local-temporary-access.manual.ps1"

Write-Host ""
Write-Info "To VIEW detailed identity visibility (read-only):"
Write-Info "  -> Run: 46-identity-local-visibility.verify.ps1"


# ============================================================================
# 5. INTENTIONAL NON-ACTIONS
# ============================================================================

Write-Section "Intentional non-actions"

Write-Info "No local users were created, modified, or removed"
Write-Info "No group memberships were changed"
Write-Info "No passwords were requested"
Write-Info "No cloud or domain identities were touched"


# ============================================================================
# 6. COMPLETION & EXIT STRATEGY
# ============================================================================

Write-Section "Summary"
Write-Info "Identity orchestrator completed. No changes were made."

Exit-Warn
