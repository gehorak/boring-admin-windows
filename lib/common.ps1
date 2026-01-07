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
        Write-Error "This script must be run as Administrator."
        exit 1
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

    Write-Host "[INFO] $Message"
}


function Write-Warn {
    param (
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Warning $Message
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
        Receive-Job $job
    }
    else {
        Stop-Job $job | Out-Null
        return $null
    }
}
