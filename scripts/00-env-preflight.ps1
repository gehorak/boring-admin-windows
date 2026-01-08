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


# ============================================================================
# 0. BOOTSTRAP
# ============================================================================
# Establish execution context and load runtime helpers.
# No system state must be modified in this section.
# ============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptRoot\.."

. "$ProjectRoot\lib\common.ps1"

# Initialize warning state for preflight context
$script:HadWarnings = $false

# ============================================================================
# 1. EXECUTION CONTEXT
# ============================================================================
# Ensure the script is running in a supported and safe runtime context.
# Fail-fast on unmet hard preconditions.
# ============================================================================

Assert-Administrator
Test-PowerShellVersion | Out-Null

Write-Section "00-env-preflight - Environment Check"


# ============================================================================
# 2. OPERATING SYSTEM CHECK
# ============================================================================
# Validate basic OS assumptions.
# Informational unless explicitly stated otherwise.
# ============================================================================

$os = Get-CimInstance Win32_OperatingSystem
Write-Info "OS: $($os.Caption) ($($os.Version))"

if ($os.Caption -notmatch "Windows 11") {
    Write-WarnFlagged "This repository is designed for Windows 11." -Flag $script:HadWarnings   
}

# ============================================================================
# 3. EXECUTION POLICY (INFORMATIONAL)
# ============================================================================
# Execution policy is observed only.
# No enforcement or modification is performed.
# ============================================================================

$policy = Get-ExecutionPolicy -Scope LocalMachine
Write-Info "ExecutionPolicy (LocalMachine): $policy"


# ============================================================================
# 4. DOMAIN MEMBERSHIP CHECK
# ============================================================================
# Domain-joined systems are outside the supported architecture.
# This is treated as a hard precondition failure.
# ============================================================================

$computerSystem = Get-CimInstance Win32_ComputerSystem


if ($computerSystem.PartOfDomain) {
    # Exit with error if domain-joined  Exit fatal, but log as warning for reporting
    Write-WarnFlagged "System is domain-joined. This repo assumes NO domain." -Flag $script:HadWarnings
} else {
    Write-Info "System is NOT domain-joined (expected)."
}

# ============================================================================
# 5. BITLOCKER CMDLETS AVAILABILITY (INFORMATIONAL)
# ============================================================================
# Verify presence of BitLocker tooling.
# This does not enforce BitLocker state.
# ============================================================================

try {
    Get-BitLockerVolume -ErrorAction Stop | Out-Null
    Write-Info "BitLocker cmdlets available."
} 
catch {
    Write-WarnFlagged "BitLocker cmdlets not available (unexpected on Win11 Pro)."
}

# ============================================================================
# 6. COMPLETION & EXIT STRATEGY
# ============================================================================
# Emit deterministic exit code based on observed warnings.
# ============================================================================

Write-Info "Environment check completed. No changes made."

Exit-Warn