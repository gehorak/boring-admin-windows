[CmdletBinding()]
param()

Set-StrictMode -Version Latest

$dependencyPath = Join-Path $PSScriptRoot "qa-dependencies.json"
$dependencies = Get-Content -Raw -LiteralPath $dependencyPath | ConvertFrom-Json -ErrorAction Stop
$requiredVersion = [version]$dependencies.modules.PSScriptAnalyzer.requiredVersion
$module = Get-Module -ListAvailable PSScriptAnalyzer |
    Where-Object { $_.Version -eq $requiredVersion } |
    Select-Object -First 1

if (-not $module) {
    Write-Host ("[FAIL] PSScriptAnalyzer {0} is not available in the current PowerShell installation." -f $requiredVersion) -ForegroundColor Red
    Write-Host "[INFO] Install the exact pinned version before running the lint suite." -ForegroundColor Cyan
    exit 1
}

if ($module.Version -ne $requiredVersion) {
    Write-Host ("[FAIL] PSScriptAnalyzer version {0} does not match the pinned version {1}." -f $module.Version, $requiredVersion) -ForegroundColor Red
    exit 1
}

Import-Module PSScriptAnalyzer -RequiredVersion $requiredVersion -ErrorAction Stop | Out-Null

[pscustomobject]@{
    Name    = $module.Name
    Version = $module.Version.ToString()
    Path    = $module.Path
}
