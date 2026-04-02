# ============================================================================
# 39-software-inventory.verify.ps1
#
# PURPOSE
# -------
# Provide read-only visibility into software transport presence
# and a compact workstation software inventory snapshot.
#
# This script does NOT install, remove, or configure software.
#
# LIFECYCLE
# ---------
# Stage: 30–39 — Software
#
# MODE
# ----
# VERIFY
# - Read-only
# - Safe to run repeatedly
# - No side effects
#
# EXIT MODEL
# ----------
# Variant A:
# - exit 0 : completed (with or without warnings)
# - exit 1 : fatal error only
#
# CONTRACT
# --------
# Follows docs/SCRIPT-CONTRACT.md and docs/STRUCTURE.md
# ============================================================================

[CmdletBinding()]
param(
    [ValidateSet("Text", "Json")]
    [string] $OutputFormat = "Text"
)


# ============================================================================
# 0. BOOTSTRAP
# ============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptRoot "..\..")
if (-not (Test-Path (Join-Path $ProjectRoot "core\lib\common.ps1"))) {
    $ProjectRoot = Resolve-Path (Join-Path $ScriptRoot "..\..\..")
}

. (Join-Path $ProjectRoot "core\lib\common.ps1")

$script:HadWarnings = $false
$warnings = [System.Collections.Generic.List[string]]::new()

function Add-InventoryWarning {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    $script:HadWarnings = $true
    $warnings.Add($Message) | Out-Null

    if ($OutputFormat -eq "Text") {
        Write-Warn $Message
    }
}

function Get-UninstallEntries {
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $entries = foreach ($path in $paths) {
        Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_.DisplayName) } |
            Select-Object DisplayName, DisplayVersion, Publisher
    }

    $entries |
        Sort-Object DisplayName -Unique
}

function Test-InventoryMarker {
    param(
        [Parameter(Mandatory)]
        [object[]] $Entries,

        [Parameter(Mandatory)]
        [string] $Label,

        [Parameter(Mandatory)]
        [string[]] $Patterns
    )

    $matchingEntries = @(
        $Entries | Where-Object {
            $displayName = $_.DisplayName
            foreach ($pattern in $Patterns) {
                if ($displayName -match $pattern) {
                    return $true
                }
            }
            return $false
        }
    )

    [pscustomobject]@{
        Label    = $Label
        Present  = ($matchingEntries.Count -gt 0)
        Matches  = @($matchingEntries | Select-Object -ExpandProperty DisplayName)
    }
}


# ============================================================================
# 1. EXECUTION CONTEXT
# ============================================================================

Assert-Administrator
Test-PowerShellVersion | Out-Null

$chocoCommand = Get-Command choco.exe -ErrorAction SilentlyContinue
$wingetCommand = Get-Command winget.exe -ErrorAction SilentlyContinue

$chocoVersion = $null
$wingetVersion = $null

if ($chocoCommand) {
    $chocoVersion = (& choco --version 2>$null)
}

if ($wingetCommand) {
    $wingetVersion = (& winget --version 2>$null)
}

$uninstallEntries = @(Get-UninstallEntries)

$markers = @(
    (Test-InventoryMarker -Entries $uninstallEntries -Label "PowerShell 7" -Patterns @("PowerShell 7", "^PowerShell$")),
    (Test-InventoryMarker -Entries $uninstallEntries -Label "Git" -Patterns @("^Git$", "Git version control")),
    (Test-InventoryMarker -Entries $uninstallEntries -Label "7-Zip" -Patterns @("7-Zip")),
    (Test-InventoryMarker -Entries $uninstallEntries -Label "KeePassXC" -Patterns @("KeePassXC")),
    (Test-InventoryMarker -Entries $uninstallEntries -Label "VLC" -Patterns @("^VLC media player", "^VLC$"))
)

if (-not $chocoCommand -and -not $wingetCommand) {
    Add-InventoryWarning "No supported package transport was detected."
}

$inventory = [pscustomobject]@{
    scope          = "software-inventory"
    generatedAt    = (Get-Date).ToString("s")
    computerName   = $env:COMPUTERNAME
    packageManager = [pscustomobject]@{
        chocolatey = [pscustomobject]@{
            present = [bool]$chocoCommand
            version = $chocoVersion
        }
        winget = [pscustomobject]@{
            present = [bool]$wingetCommand
            version = $wingetVersion
        }
    }
    inventory = [pscustomobject]@{
        uninstallEntryCount = $uninstallEntries.Count
        markers             = $markers
    }
    warnings       = @($warnings)
}


# ============================================================================
# 2. OUTPUT
# ============================================================================

if ($OutputFormat -eq "Json") {
    $inventory | ConvertTo-Json -Depth 6
    Exit-Warn
}

Write-Section "39-software — Inventory Visibility (VERIFY)"

Write-Section "Package transport"
if ($chocoCommand) {
    Write-Info "Chocolatey present: True"
    Write-Info "Chocolatey version: $chocoVersion"
}
else {
    Add-InventoryWarning "Chocolatey not detected."
}

if ($wingetCommand) {
    Write-Info "WinGet present    : True"
    Write-Info "WinGet version    : $wingetVersion"
}
else {
    Add-InventoryWarning "WinGet not detected."
}

Write-Section "Inventory summary"
Write-Info "Installed software entries detected: $($uninstallEntries.Count)"

foreach ($marker in $markers) {
    if ($marker.Present) {
        Write-Info "Marker present: $($marker.Label)"
    }
    else {
        Add-InventoryWarning "Marker missing: $($marker.Label)"
    }
}

Write-Section "Intentional non-actions"
Write-Info "No software was installed"
Write-Info "No software was removed"
Write-Info "No package manager configuration was changed"

Write-Section "Summary"
Write-Info "Software inventory visibility check completed."

Exit-Warn
