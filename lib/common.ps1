# ============================================================================
# common.ps1
#
# PURPOSE
# -------
# Shared helper functions for boring-admin-windows scripts.
#
# This file defines the SINGLE source of truth for:
# - runtime assertions
# - output vocabulary
# - exit semantics
# - guarded system queries
#
# DESIGN PRINCIPLES
# -----------------
# - Helpers only (NO auto-execution)
# - No side effects on import
# - Explicit calls required
# - Safe for dot-sourcing
#
# EXIT SEMANTICS (VARIANT A)
# -------------------------
# - exit 0 : success (with or without warnings)
# - exit 1 : fatal error
#
# Warnings are INFORMATIONAL only.
# They NEVER control execution flow.
# ============================================================================


# ============================================================================
# 0. RUNTIME STATE
# ============================================================================
# Shared state flags used by SAFE / VERIFY scripts.
# Must be initialized by the caller script.
# ============================================================================

# Expected:
# $script:HadWarnings = $false


# ============================================================================
# 1. RUNTIME ASSERTIONS
# ============================================================================
# Hard preconditions required for correct execution.
# ============================================================================

function Assert-Administrator {
    <#
    .SYNOPSIS
        Ensures the current PowerShell session runs with administrative privileges.

    .BEHAVIOR
        - Terminates execution on failure.
        - This is a HARD requirement, not advisory.
    #>

    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Exit-Fatal "This script must be run as Administrator."
        
    }
}

function Test-PowerShellVersion {
    <#
    .SYNOPSIS
        Checks whether the script is running under PowerShell 7+.

    .BEHAVIOR
        - Returns $true / $false for caller
        - Emits WARNING only (no termination)
        - NEVER terminates execution
    #>

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Warn "Running under Windows PowerShell 5.1 — limited functionality."
        return $false
    }

    return $true
}


# ============================================================================
# 2. OUTPUT HELPERS (UNIFIED VOCABULARY)
# ============================================================================
# All script output MUST go through these helpers.
# ============================================================================

function Write-Section {
    param (
        [Parameter(Mandatory)]
        [string]$Title
    )

    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
}


function Write-Info {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "[INFO] $Message" -ForegroundColor White
}


function Write-Warn {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-WarnFlagged {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    # Caller is responsible for initializing $script:HadWarnings
    $script:HadWarnings = $true
    Write-Warn $Message
}

function Write-OK {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "[OK]   $Message"
}

function Write-Fail {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "[FAIL] $Message"
}

# ============================================================================
# 3. EXIT HELPERS
# ============================================================================
# Exit codes follow PowerShell / OS semantics strictly.
# ============================================================================

function Exit-Warn {
   <#
    .BEHAVIOR
        - Emits warning summary if warnings occurred
        - ALWAYS exits with code 0
    #>

    if ($script:HadWarnings) {
        Write-Warn "Completed with warnings."
    }

    exit 0
}

function Exit-Fatal {}
    <#
    .BEHAVIOR
    #>
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Fail $Message" -ForegroundColor Red
    exit 1
}
    

# ============================================================================
# 4. REGISTRY & PROFILE HELPERS
# ============================================================================
# Orchestration helpers with explicit side effects.
# ============================================================================

function Mount-DefaultUserProfile {
    <#
    .SYNOPSIS
        Mounts Default User NTUSER.DAT to HKLM:\DefUser.
    #>

    Write-Info "Mounting Default User profile hive."

    $defaultHivePath = "C:\Users\Default\NTUSER.DAT"
    
    if (Test-Path "HKLM:\DefUser") {
        Write-Warn "Default User hive already mounted or path occupied."
        return
    }

    reg load "HKLM\DefUser" $defaultHivePath | Out-Null

    if ($LASTEXITCODE -ne 0) {
        Exit-Fatal "Failed to mount Default User profile hive."
    }
}


function Dismount-DefaultUserProfile {
    <#
    .SYNOPSIS
        Safely unmounts Default User registry hive.    
    #>
    
    Write-Info "Dismounting Default User profile hive."
    
    # Garbage collection for handle
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()

    reg unload "HKLM\DefUser" | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "Failed to dismount Default User hive. It might be locked."
    }
}


function Set-RegistryPreference {
    <#
    .SYNOPSIS
        Writes a registry value to:
        - HKCU (current user)
        - HKLM:\DefUser (if mounted)
    #>

    param (
        [Parameter(Mandatory)] [string]$KeyPath,
        [Parameter(Mandatory)] [string]$ValueName,
        [Parameter(Mandatory)] $Value,
        [ValidateSet("DWord","String","ExpandString","QWord")]
        [string]$ValueType = "DWord"
    )

    $targets = @("HKCU:\$KeyPath")

    if (Test-Path "HKLM:\DefUser") {
        $targets += "HKLM:\DefUser\$KeyPath"
    }

    foreach ($path in $targets) {
    
        # Zajistime, ze existuje cela cesta ke klici
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        
        Set-ItemProperty `
            -Path $path `
            -Name $ValueName `
            -Value $Value `
            -Type $ValueType `
            -Force | Out-Null

        Write-Info "Registry set: $path\$ValueName = $Value"
    }
}

# ============================================================================
# 5. GUARDED SYSTEM QUERIES
# ============================================================================
# Queries that must never block or crash the caller.
# ============================================================================

function Try-GetMpComputerStatus {
    <#
    .SYNOPSIS
        Non-blocking Defender status query.

    .BEHAVIOR
        - Executes query in isolated job
        - Returns $null on timeout
        - NEVER blocks caller
    #>

    param (
        [int]$TimeoutSec = 5
    )

    $job = Start-Job {
        Get-MpComputerStatus
    }

    if (Wait-Job $job -Timeout $TimeoutSec) {
        $result = Receive-Job $job
        Remove-Job $job | Out-Null
        return $result
    }

    Stop-Job $job | Out-Null
    Remove-Job $job | Out-Null
    
    Write-Warn "Get-MpComputerStatus timed out after $TimeoutSec seconds.
    