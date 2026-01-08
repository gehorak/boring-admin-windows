# ============================================================================
# 10-bootstrap-orchestrator.ps1
#
# PURPOSE
# -------
# Orchestrate the OS bootstrap lifecycle stage by invoking
# strictly bounded bootstrap scripts in a defined order.
#
# This script coordinates execution only.
# It does not implement configuration changes.
#
# LIFECYCLE
# ---------
# Stage: 10–19 — OS Bootstrap
#
# SCOPE
# -----
# - sequencing of bootstrap-stage scripts
# - enforcement of execution order
# - transparent propagation of exit codes
#
# NON-GOALS
# ---------
# - direct system configuration
# - policy decisions
# - error interpretation or remediation
#
# SAFETY
# ------
# - No direct system state changes
# - Acts only as an execution coordinator
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
# ============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptRoot\.."

. "$ProjectRoot\lib\common.ps1"

# Initialize warning state for orchestration.
$script:HadWarnings = $false

# ============================================================================
# 1. EXECUTION CONTEXT
# ============================================================================
# Ensure safe execution context before orchestration begins.
# ============================================================================

Assert-Administrator
Test-PowerShellVersion | Out-Null

Write-Section "10-bootstrap-orchestrator - Orchestration"

# ============================================================================
# 2. PRE-ORCHESTRATION SETUP
# ============================================================================
# Perform required setup steps needed for downstream scripts.
# These helpers are considered orchestration primitives.
# ============================================================================

Mount-DefaultUserProfile

# ============================================================================
# 3. BOOTSTRAP EXECUTION SEQUENCE
# ============================================================================
# Execute bootstrap-stage scripts in a strict, explicit order.
# This orchestrator does NOT interpret results.
# It propagates exit codes transparently.
# ============================================================================



$BootstrapSequence = @(
        "11-bootstrap-system-features.safe.ps1",
        "15-bootstrap-consumer-noise.safe.ps1"
)

foreach ($ScriptName in $BootstrapSequence) {

    $ScriptPath = Join-Path $ScriptRoot $ScriptName
        
    if (-not (Test-Path $ScriptPath)) {
        Write-WarnFlagged "Skipping missing bootstrap script: $ScriptName"
        continue
    }
    
    Write-Info "Executing bootstrap stage script: $ScriptName"

    & $ScriptPath
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        Write-Fail "Bootstrap script '$ScriptName' exited with code $exitCode."
        Exit-Fatal "Bootstrap phase failed due to script error."
    }   
}

# ============================================================================
# 4. CLEANUP
# ============================================================================
# Ensure orchestration-related temporary state is cleaned up.
# This section must execute regardless of earlier outcomes.
# ============================================================================

Dismount-DefaultUserProfile

# ============================================================================
# 5. COMPLETION & EXIT STRATEGY
# ============================================================================
# Exit deterministically based on observed warnings.
# ============================================================================

Write-Info "Bootstrap orchestration completed."

Exit-Warn