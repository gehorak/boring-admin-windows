[CmdletBinding()]
param()

Set-StrictMode -Version Latest

$minimumVersion = [version]"5.0.0"
$module = Get-Module -ListAvailable Pester |
    Sort-Object Version -Descending |
    Select-Object -First 1

if (-not $module) {
    Write-Host "[FAIL] Pester is not available in the current PowerShell installation." -ForegroundColor Red
    Write-Host "[INFO] Install or import Pester before running unit, contract, or smoke suites." -ForegroundColor Cyan
    exit 1
}

if ($module.Version -lt $minimumVersion) {
    Write-Host ("[FAIL] Pester version {0} is below the minimum supported version {1}." -f $module.Version, $minimumVersion) -ForegroundColor Red
    exit 1
}

Import-Module Pester -MinimumVersion $minimumVersion -ErrorAction Stop | Out-Null

[pscustomobject]@{
    Name    = $module.Name
    Version = $module.Version.ToString()
    Path    = $module.Path
}
