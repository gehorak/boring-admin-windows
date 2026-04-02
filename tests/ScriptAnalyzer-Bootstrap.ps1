[CmdletBinding()]
param()

Set-StrictMode -Version Latest

$minimumVersion = [version]"1.21.0"
$module = Get-Module -ListAvailable PSScriptAnalyzer |
    Sort-Object Version -Descending |
    Select-Object -First 1

if (-not $module) {
    Write-Host "[FAIL] PSScriptAnalyzer is not available in the current PowerShell installation." -ForegroundColor Red
    Write-Host "[INFO] Install or import PSScriptAnalyzer before running the lint suite." -ForegroundColor Cyan
    exit 1
}

if ($module.Version -lt $minimumVersion) {
    Write-Host ("[FAIL] PSScriptAnalyzer version {0} is below the minimum supported version {1}." -f $module.Version, $minimumVersion) -ForegroundColor Red
    exit 1
}

Import-Module PSScriptAnalyzer -MinimumVersion $minimumVersion -ErrorAction Stop | Out-Null

[pscustomobject]@{
    Name    = $module.Name
    Version = $module.Version.ToString()
    Path    = $module.Path
}
