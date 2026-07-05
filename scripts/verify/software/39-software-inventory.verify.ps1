# ============================================================================
# 39-software-inventory.verify.ps1
#
# PURPOSE
# -------
# Provide read-only visibility into the configured software baseline and the
# currently observed installation state for the active package manager.
#
# This script does NOT install, remove, or configure software.
#
# CONTRACT
# --------
# Follows docs/ARCHITECTURE.md and docs/ARCHITECTURE.md
# ============================================================================

[CmdletBinding()]
param(
    [ValidateSet("Text", "Json")]
    [string] $OutputFormat = "Text"
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptRoot "..\..")
if (-not (Test-Path (Join-Path $ProjectRoot "core\lib\common.ps1"))) {
    $ProjectRoot = Resolve-Path (Join-Path $ScriptRoot "..\..\..")
}

. (Join-Path $ProjectRoot "core\lib\common.ps1")
. (Join-Path $ProjectRoot "core\lib\config.ps1")
. (Join-Path $ProjectRoot "core\lib\software-inventory.ps1")

$script:HadWarnings = $false
$warnings = [System.Collections.Generic.List[string]]::new()
$config = Import-BoringAdminConfigOrFail

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

Test-PowerShellVersion | Out-Null

$packageManager = Get-BoringAdminSoftwarePackageManager -Config $config
$baselinePackages = @(Get-BoringAdminSoftwarePackageList -Config $config -PackageClass baseline -PackageManager $packageManager)
$chocoCommand = Get-Command choco.exe -ErrorAction SilentlyContinue
$wingetCommand = Get-Command winget.exe -ErrorAction SilentlyContinue
$chocoVersion = if ($chocoCommand) { (& choco.exe --version 2>$null | Out-String).Trim() } else { $null }
$wingetVersion = if ($wingetCommand) { (& winget.exe --version 2>$null | Out-String).Trim() } else { $null }
$baselineInventory = [System.Collections.Generic.List[object]]::new()

if ($packageManager -eq "choco" -and -not $chocoCommand) {
    Add-InventoryWarning "Configured package manager 'choco' is not available in PATH."
}

if ($packageManager -eq "winget" -and -not $wingetCommand) {
    Add-InventoryWarning "Configured package manager 'winget' is not available in PATH."
}

foreach ($package in $baselinePackages) {
    $queryResult = switch ($packageManager) {
        "choco" {
            if ($chocoCommand) {
                Get-BoringAdminChocolateyPackageState -PackageId $package.id -ExpectedVersion $package.version
            }
            else {
                [pscustomobject]@{
                    Success = $false
                    State   = "unknown"
                    Version = $null
                    Error   = "Chocolatey is not available in PATH."
                    Source  = "choco"
                }
            }
        }
        "winget" {
            if ($wingetCommand) {
                Get-BoringAdminWinGetPackageState -PackageId $package.id -ExpectedVersion $package.version
            }
            else {
                [pscustomobject]@{
                    Success = $false
                    State   = "unknown"
                    Version = $null
                    Error   = "WinGet is not available in PATH."
                    Source  = "winget"
                }
            }
        }
    }

    $observedVersion = $queryResult.Version
    $status = [string]$queryResult.State

    if (-not $queryResult.Success) {
        Add-InventoryWarning ("Unable to verify package '{0}': {1}" -f $package.id, $queryResult.Error)
    }
    elseif ($status -ne "present") {
        Add-InventoryWarning ("Baseline package '{0}' is {1}. Expected version: {2}." -f $package.id, $status, $package.version)
    }

    $baselineInventory.Add([pscustomobject]@{
        id                = $package.id
        expectedVersion   = $package.version
        observedVersion   = $observedVersion
        required          = [bool]$package.required
        source            = $package.source
        reviewedPublisher = $package.reviewedPublisher
        status            = $status
    }) | Out-Null
}

$inventory = [pscustomobject]@{
    scope          = "software-inventory"
    generatedAt    = Get-Rfc3339Timestamp
    computerName   = $env:COMPUTERNAME
    packageManager = [pscustomobject]@{
        configured = $packageManager
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
        baselinePackageCount = $baselinePackages.Count
        baselinePackages     = @($baselineInventory)
    }
    warnings       = @($warnings)
}

if ($OutputFormat -eq "Json") {
    $inventory | ConvertTo-Json -Depth 8
    Exit-Warn
}

Write-Section "39-software - Inventory Visibility (VERIFY)"
Write-Section "Configured transport"
Write-Info "Configured package manager: $packageManager"
Write-Info "Chocolatey present       : $([bool]$chocoCommand)"
if ($chocoVersion) {
    Write-Info "Chocolatey version       : $chocoVersion"
}

Write-Info "WinGet present           : $([bool]$wingetCommand)"
if ($wingetVersion) {
    Write-Info "WinGet version           : $wingetVersion"
}

Write-Section "Baseline package state"
foreach ($package in $baselineInventory) {
    Write-Info ("{0} -> expected={1}; observed={2}; status={3}" -f $package.id, $package.expectedVersion, $(if ($package.observedVersion) { $package.observedVersion } else { "<missing>" }), $package.status)
}

Write-Section "Intentional non-actions"
Write-Info "No software was installed"
Write-Info "No software was removed"
Write-Info "No package manager configuration was changed"

Write-Section "Summary"
Write-Info "Software inventory visibility check completed."
Exit-Warn
