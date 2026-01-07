# ============================================================================
# 00-env-preflight.ps1
#
# PURPOSE
# -------
# Verify that the execution environment is safe and suitable
# for running boring-admin-windows lifecycle scripts.
#
# This script performs preflight checks only.
#
# LIFECYCLE
# ---------
# Stage: 00–09 — Environment & Safety
#
# SCOPE
# -----
# - execution privileges (administrator context)
# - PowerShell runtime version and capabilities
# - basic platform assumptions
#
# NON-GOALS
# ---------
# - system configuration
# - security policy changes
# - software installation
#
# SAFETY
# ------
# - This script makes NO changes to system state
# - Read-only execution
# - Fail-fast behavior on unmet preconditions
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

Write-Section "Environment Check"

# --- OS Version --------------------------------------------------------------
$os = Get-CimInstance Win32_OperatingSystem
Write-Info "OS: $($os.Caption) ($($os.Version))"

if ($os.Caption -notmatch "Windows 11") {
    Write-Warn "This repository is designed for Windows 11."
}

# --- Execution Policy --------------------------------------------------------
$policy = Get-ExecutionPolicy -Scope LocalMachine
Write-Info "ExecutionPolicy (LocalMachine): $policy"

# --- Domain Membership -------------------------------------------------------
$computerSystem = Get-CimInstance Win32_ComputerSystem
if ($computerSystem.PartOfDomain) {
    Write-Warn "System is domain-joined. This repo assumes NO domain."
} else {
    Write-Info "System is NOT domain-joined (expected)."
}

# --- BitLocker presence (informational) -------------------------------------
try {
    $bl = Get-BitLockerVolume -ErrorAction Stop
    Write-Info "BitLocker cmdlets available."
} catch {
    Write-Warn "BitLocker cmdlets not available (unexpected on Win11 Pro)."
}

Write-Info "Environment check completed. No changes made."
