# ============================================================================
# 10-bootstrap-orchestrator.ps1
#
# PURPOSE
# -------
# Orchestrate the OS bootstrap lifecycle stage by invoking
# strictly bounded bootstrap scripts in a defined order.
#
# This script coordinates execution.
# It does not directly implement configuration changes.
#
# LIFECYCLE
# ---------
# Stage: 10–19 — OS Bootstrap
#
# SCOPE
# -----
# - sequencing of bootstrap-stage scripts
# - enforcement of preconditions and execution order
# - propagation of failures (fail-fast)
#
# NON-GOALS
# ---------
# - direct system configuration
# - debloating or consumer noise removal
# - security hardening
# - performance tuning
#
# SAFETY
# ------
# - No direct system state changes
# - No implicit elevation or reboot
# - Acts only as an execution coordinator
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

Write-Section "Bootstrap"

# --- Enable long paths -------------------------------------------------------
Write-Info "Enabling Win32 long paths support"

New-ItemProperty `
  -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
  -Name "LongPathsEnabled" `
  -PropertyType DWord `
  -Value 1 `
  -Force | Out-Null

# --- Disable first logon animation ------------------------------------------
Write-Info "Disabling first logon animation"

New-ItemProperty `
  -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
  -Name "EnableFirstLogonAnimation" `
  -PropertyType DWord `
  -Value 0 `
  -Force | Out-Null

Write-Info "Bootstrap completed."
