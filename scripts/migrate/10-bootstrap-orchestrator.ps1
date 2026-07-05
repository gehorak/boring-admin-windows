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
# This script follows docs/ARCHITECTURE.md
# and the lifecycle model defined in docs/ARCHITECTURE.md
# ============================================================================

[CmdletBinding()]
param(
    [switch] $WhatIf
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# ============================================================================
# 0. BOOTSTRAP
# ============================================================================
# Establish execution context and load runtime helpers.
# ============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptRoot "..\..")
if (-not (Test-Path (Join-Path $ProjectRoot "core\lib\common.ps1"))) {
    $ProjectRoot = Resolve-Path (Join-Path $ScriptRoot "..\..\..")
}

. (Join-Path $ProjectRoot "core\lib\common.ps1")

# Initialize warning state for orchestration.
$script:HadWarnings = $false
$null = Initialize-BoringAdminApplyResult -Target "bootstrap"

# ============================================================================
# 1. EXECUTION CONTEXT
# ============================================================================
# Ensure safe execution context before orchestration begins.
# ============================================================================

Assert-Administrator
Test-PowerShellVersion | Out-Null

Write-Section "10-bootstrap-orchestrator - Orchestration"

# ============================================================================
# 2. BOOTSTRAP EXECUTION SEQUENCE
# ============================================================================
# Execute bootstrap-stage scripts in a strict, explicit order.
# This orchestrator does NOT interpret results.
# It propagates exit codes transparently.
# ============================================================================

try {
    $BootstrapSequence = @(
        "11-bootstrap-system-features.safe.ps1"
    )
    $movedOutOfBootstrap = @(
        "15-bootstrap-consumer-noise.safe.ps1"
    )

    Add-BoringAdminApplyDetail -Name "executed_scripts" -Value $BootstrapSequence
    Add-BoringAdminApplyDetail -Name "moved_out_of_bootstrap" -Value $movedOutOfBootstrap
    Add-BoringAdminApplyDetail -Name "what_if" -Value ([bool]$WhatIf)

    foreach ($ScriptName in $BootstrapSequence) {
        $ScriptPath = Join-Path $ScriptRoot $ScriptName

        if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
            throw "Required bootstrap script is missing: $ScriptName"
        }

        Write-Info "Executing bootstrap stage script: $ScriptName"

        & $ScriptPath -WhatIf:$WhatIf
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            throw "Bootstrap script '$ScriptName' exited with code $exitCode."
        }
    }

    Add-BoringAdminApplyDetail -Name "summary" -Value "Bootstrap now applies only bounded baseline prerequisites. Consumer noise reduction is no longer part of the public bootstrap path."
    Write-Info "Bootstrap orchestration completed."
    Write-BoringAdminApplyResult
    Exit-Warn
}
catch {
    Register-BoringAdminApplyResultState -Result "failed"
    Add-BoringAdminApplyWarning $_.Exception.Message
    Write-BoringAdminApplyResult
    Exit-Fatal $_.Exception.Message
}
