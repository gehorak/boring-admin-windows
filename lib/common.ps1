# ============================================================================
# common.ps1
#
# Shared helper functions for boring-admin-windows scripts.
#
# DESIGN PRINCIPLES
# -----------------
# - Helpers only (NO auto-execution)
# - No side effects on import
# - Explicit calls required
# - Safe for dot-sourcing
#
# This file intentionally contains:
# - assertions
# - formatting helpers
# - guarded system queries
#
# It intentionally does NOT:
# - modify system state
# - emit output on load
# - make policy decisions
# ============================================================================


# ---------------------------------------------------------------------------
# Runtime assertions
# ---------------------------------------------------------------------------


function Assert-Administrator {
    <#
    .SYNOPSIS
        Ensures the current PowerShell session runs with administrative privileges.

    .WHY
        Many system-level operations silently fail or partially succeed
        when executed without elevation.

    .BEHAVIOR
        - Terminates execution if not elevated.
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

    .WHY
        Windows PowerShell 5.1 lacks:
        - reliable LocalAccounts behavior
        - consistent module availability
        - modern language/runtime features

    .BEHAVIOR
        - Returns $true if PS >= 7
        - Emits WARNING only (no termination)

    .NOTE
        This is an ADVISORY check.
        The caller decides whether to continue or abort.
    #>

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Warn "Running under Windows PowerShell 5.1 — limited functionality."
        return $false
    }

    return $true
}


# ---------------------------------------------------------------------------
# Output helpers (UX consistency)
# ---------------------------------------------------------------------------

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
        [string]$Message,

        [Parameter(Mandatory)]
        [ref]$Flag
    )

    $Flag.Value = $true
    Write-Warn $Message
}

function Write-OK {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "[OK]   $Message" -ForegroundColor Green
}

function Exit-Warn {
    exit 2
}

function Exit-Fatal {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host "[FAIL] $Message" -ForegroundColor Red
    exit 1
}


# ---------------------------------------------------------------------------
# Registry & Profile Helpers (Default User Injection)
# ---------------------------------------------------------------------------


function Mount-DefaultUserProfile {
    <#
    .SYNOPSIS
        Mounts the Default User registry hive (NTUSER.DAT) to HKLM:\DefUser.
    #>
    Write-Info "Mounting Default User Profile Hive..."
    $defaultHivePath = "C:\Users\Default\NTUSER.DAT"
    
    if (Test-Path "HKLM:\DefUser") {
        Write-Warn "Default User hive already mounted or path occupied."
        return
    }

    # Pouziti reg.exe pro spolehlive namontovani
    reg load "HKLM\DefUser" $defaultHivePath | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Exit-Fatal "Failed to mount Default User hive."
    }
}


function Dismount-DefaultUserProfile {
    <#
    .SYNOPSIS
        Dismounts the Default User registry hive and ensures all changes are flushed.
    #>
    Write-Info "Dismounting Default User Profile Hive..."
    
    # Garbage collection k uvolneni handle, pokud by nejaky PS proces drzel cestu
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
        Zapíše hodnotu do HKCU aktuálního uživatele i do namontovaného Default User profilu.
    #>
    param (
        [Parameter(Mandatory)] [string]$KeyPath,    # Relativní cesta (např. "Software\Microsoft\...")
        [Parameter(Mandatory)] [string]$ValueName,
        [Parameter(Mandatory)] $Value,
        [string]$ValueType = "DWord"
    )

    $targets = @("HKCU:\$KeyPath")
    if (Test-Path "HKLM:\DefUser") {
        $targets += "HKLM:\DefUser\$KeyPath"
    }

    foreach ($path in $targets) {
        # Zajistíme, že existuje celá cesta ke klíči
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        
        Set-ItemProperty -Path $path -Name $ValueName -Value $Value -Type $ValueType -Force | Out-Null
        Write-Info "Registry updated: $path\$ValueName = $Value"
    }
}

# ---------------------------------------------------------------------------
# Guarded system queries
# ---------------------------------------------------------------------------

function Try-GetMpComputerStatus {
    <#
    .SYNOPSIS
        Safely queries Windows Defender status with timeout protection.

    .WHY
        Get-MpComputerStatus uses Defender CIM provider which is known to:
        - hang during MSI installs
        - block under Tamper Protection
        - never throw terminating errors

    .BEHAVIOR
        - Executes query in isolated job
        - Returns $null on timeout
        - NEVER blocks caller

    .USAGE
        $mp = Try-GetMpComputerStatus
        if ($mp) { ... }
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
    else {
        Stop-Job $job | Out-Null
        Remove-Job $job | Out-Null
        Write-Warn "Get-MpComputerStatus timed out after $TimeoutSec seconds."
        return $null
    }
}
