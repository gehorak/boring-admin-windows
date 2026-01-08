# ============================================================================
# 11-bootstrap-system-features.safe.ps1
#
# PURPOSE
# -------
# Apply core Windows system-level feature flags required
# for a predictable and supportable environment.
#
# LIFECYCLE
# ---------
# Stage: 10–19 — OS Bootstrap
#
# SCOPE
# -----
# - Enable Win32 Long Paths
# - Disable First Logon Animation
#
# SAFETY
# ------
# - Idempotent (safe to run repeatedly)
# - No reboots initiated
# - Supports -WhatIf
#
# CONTRACT
# --------
# This script follows docs/SCRIPT-CONTRACT.md
# and the lifecycle model defined in docs/STRUCTURE.md
# ============================================================================


[CmdletBinding(SupportsShouldProcess = $true)]
param()


# ============================================================================
# 0. BOOTSTRAP
# ============================================================================
# Establish execution context and load runtime helpers.
# ============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptRoot\.."

. "$ProjectRoot\lib\common.ps1"

# Initialize warning state for this script
$script:HadWarnings = $false

# ============================================================================
# 1. EXECUTION CONTEXT
# ============================================================================
# Ensure administrative privileges before applying system changes.
# ============================================================================

Assert-Administrator

Write-Section "11-bootstrap-system-features - System Features"

# ============================================================================
# 2. ENABLE WIN32 LONG PATHS
# ============================================================================
# Requirement:
# Prevent MAX_PATH related failures in deep directory trees.
# ============================================================================

$FsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
$FsValueName = "LongPathsEnabled"
$DesiredFs   = 1


$currentFs = Get-ItemPropertyValue `
    -Path $FsPath `
    -Name $FsValueName `
    -ErrorAction Stop

if ($currentFs -eq $DesiredFs) {
    Write-Info "Win32 Long Paths already enabled (HKLM)"
    }
else {
    if ($PSCmdlet.ShouldProcess("HKLM FileSystem", "Enable Win32 long paths")) {
        Set-ItemProperty `
          -Path $FsPath `
          -Name $FsValueName `
          -PropertyType DWord `
          -Value $DesiredFs `
          -Force | Out-Null

        Write-Info "Enabled Win32 Long Paths (HKLM)"
    } 
} 

# ============================================================================
# 3. DISABLE FIRST LOGON ANIMATION
# ============================================================================
# Requirement:
# Reduce first-login noise and delay for new user profiles.
# ============================================================================

$LogonPolicyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$AnimValueName  = "EnableFirstLogonAnimation"
$DesiredAnim    = 0

if (-not (Test-Path $LogonPolicyPath)) {
    if ($PSCmdlet.ShouldProcess("HKLM Policies\\System", "Create policy key")) {
        New-Item -Path $LogonPolicyPath -Force | Out-Null
        Write-Info "Created logon policy registry path."
    }
}

$currentAnim = Get-ItemPropertyValue `
    -Path $LogonPolicyPath `
    -Name $AnimValueName `
    -ErrorAction Stop

if ($currentAnim -eq $DesiredAnim) {
    Write-Info "First logon animation already disabled."
}
else {
    if ($PSCmdlet.ShouldProcess("HKLM Logon Policy", "Disable first logon animation")) {
        Set-ItemProperty `
            -Path $LogonPolicyPath `
            -Name $AnimValueName `
            -Value $DesiredAnim `
            -Type DWord `
            -Force | Out-Null

        Write-Info "First logon animation disabled."
    }
}

# ============================================================================
# 4. COMPLETION & EXIT STRATEGY
# ============================================================================
# SAFE script exits deterministically via unified helper.
# ============================================================================

Write-Info "System features bootstrap completed."

Exit-Warn