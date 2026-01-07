# ============================================================================
# 10-bootstrap.ps1
#
# PURPOSE
# -------
# Apply minimal, long-term safe OS baseline configuration.
#
# NON-GOALS
# ---------
# - no performance tuning
# - no debloat
# - no security hardening
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
