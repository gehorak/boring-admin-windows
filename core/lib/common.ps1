# ============================================================================
# common.ps1
#
# PURPOSE
# -------
# Shared helper layer for boring-admin-windows scripts.
#
# This file is the single runtime helper source for:
# - execution assertions
# - console output vocabulary
# - warning and exit handling
# - selected registry/profile helpers
# - guarded system queries
#
# DESIGN RULES
# ------------
# - helper functions only
# - no auto-execution on import
# - safe for dot-sourcing
# - explicit calls only
# ============================================================================


# ============================================================================
# 1. EXECUTION ASSERTIONS
# ============================================================================

function Assert-Administrator {
    <#
    .SYNOPSIS
        Ensures the current session is elevated.
    #>

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Exit-Fatal "This script must be run as Administrator."
    }
}

function Test-PowerShellVersion {
    <#
    .SYNOPSIS
        Returns $true when running on PowerShell 7+.
    #>

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Warn "Running under Windows PowerShell 5.1. Some behavior may be limited."
        return $false
    }

    return $true
}


# ============================================================================
# 2. OUTPUT HELPERS
# ============================================================================

function Write-Section {
    param(
        [Parameter(Mandatory)]
        [string] $Title
    )

    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
}

function Write-SubSection {
    param(
        [Parameter(Mandatory)]
        [string] $Title
    )

    Write-Host ""
    Write-Host "-- $Title --" -ForegroundColor DarkCyan
}

function Write-Info {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-Host "[INFO] $Message" -ForegroundColor White
}

function Write-Warn {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-WarnFlagged {
    param(
        [Parameter(Mandatory)]
        [string] $Message,

        [Parameter(Position = 1)]
        [object] $Flag
    )

    $script:HadWarnings = $true

    if ($null -ne $Flag -and $Flag -is [ref]) {
        $Flag.Value = $true
    }

    Write-Warn $Message
}

function Write-OK {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-Host "[OK]   $Message" -ForegroundColor Green
}

function Write-Fail {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-Host "[FAIL] $Message" -ForegroundColor Red
}


# ============================================================================
# 3. EXIT HELPERS
# ============================================================================

function Exit-Warn {
    <#
    .SYNOPSIS
        Emits a warning summary when warnings were recorded and exits 0.
    #>

    if ($script:HadWarnings) {
        Write-Warn "Completed with warnings."
    }

    exit 0
}

function Exit-Fatal {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-Fail $Message
    exit 1
}

function Require-ManualConfirmation {
    <#
    .SYNOPSIS
        Requires explicit YES confirmation for state-changing MANUAL scripts.
    #>

    param(
        [string] $Prompt = "Type YES to continue",
        [string] $AbortMessage = "Operation aborted by operator."
    )

    $confirm = Read-Host $Prompt
    if ($confirm -ne "YES") {
        Write-WarnFlagged $AbortMessage
        Exit-Warn
    }
}


# ============================================================================
# 4. REGISTRY AND PROFILE HELPERS
# ============================================================================

function Mount-DefaultUserProfile {
    <#
    .SYNOPSIS
        Mounts the Default User hive to HKLM:\DefUser.
    #>

    $defaultHivePath = "C:\Users\Default\NTUSER.DAT"
    Write-Info "Mounting Default User profile hive."

    if (Test-Path "HKLM:\DefUser") {
        Write-Warn "Default User hive is already mounted or path is occupied."
        return
    }

    & reg.exe load "HKLM\DefUser" $defaultHivePath | Out-Null

    if ($LASTEXITCODE -ne 0) {
        Exit-Fatal "Failed to mount Default User profile hive."
    }
}

function Dismount-DefaultUserProfile {
    <#
    .SYNOPSIS
        Unmounts the Default User hive from HKLM:\DefUser.
    #>

    if (-not (Test-Path "HKLM:\DefUser")) {
        return
    }

    Write-Info "Dismounting Default User profile hive."

    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()

    & reg.exe unload "HKLM\DefUser" | Out-Null

    if ($LASTEXITCODE -ne 0) {
        Write-Warn "Failed to dismount Default User hive. It may still be locked."
    }
}

function Set-RegistryPreference {
    <#
    .SYNOPSIS
        Writes a registry value to HKCU and to HKLM:\DefUser when mounted.
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [string] $KeyPath,

        [Parameter(Mandatory)]
        [string] $ValueName,

        [Parameter(Mandatory)]
        $Value,

        [ValidateSet("DWord", "String", "ExpandString", "QWord")]
        [string] $ValueType = "DWord"
    )

    $targets = @("HKCU:\$KeyPath")

    if (Test-Path "HKLM:\DefUser") {
        $targets += "HKLM:\DefUser\$KeyPath"
    }

    foreach ($path in $targets) {
        if ($PSCmdlet.ShouldProcess("$path\$ValueName", "Set registry preference")) {
            if (-not (Test-Path $path)) {
                New-Item -Path $path -Force | Out-Null
            }

            New-ItemProperty `
                -Path $path `
                -Name $ValueName `
                -Value $Value `
                -PropertyType $ValueType `
                -Force | Out-Null

            Write-Info "Registry set: $path\$ValueName = $Value"
        }
    }
}


# ============================================================================
# 5. GUARDED SYSTEM QUERIES
# ============================================================================

function Try-GetMpComputerStatus {
    <#
    .SYNOPSIS
        Queries Defender status without blocking the caller indefinitely.
    #>

    param(
        [int] $TimeoutSec = 5
    )

    $job = Start-Job -ScriptBlock {
        Get-MpComputerStatus
    }

    try {
        if (Wait-Job -Job $job -Timeout $TimeoutSec) {
            return Receive-Job -Job $job
        }

        Write-Warn "Get-MpComputerStatus timed out after $TimeoutSec seconds."
        return $null
    }
    catch {
        Write-Warn "Get-MpComputerStatus failed."
        return $null
    }
    finally {
        if ($job) {
            Stop-Job -Job $job -ErrorAction SilentlyContinue | Out-Null
            Remove-Job -Job $job -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }
}
