[CmdletBinding(SupportsShouldProcess = $true)]
param()

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$TestRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepositoryRoot = Split-Path -Parent $TestRoot
$DependenciesManifestRelativePath = "tests\qa-dependencies.json"
$dependenciesPath = Join-Path $RepositoryRoot $DependenciesManifestRelativePath

if (-not (Test-Path -LiteralPath $dependenciesPath -PathType Leaf)) {
    Write-Host ("[FAIL] QA dependency manifest not found: {0}" -f $DependenciesManifestRelativePath) -ForegroundColor Red
    exit 1
}

$repository = Get-PSRepository -Name "PSGallery" -ErrorAction SilentlyContinue
if (-not $repository) {
    Write-Host "[FAIL] PSGallery is not available in the current PowerShell session." -ForegroundColor Red
    exit 1
}

$dependencies = Get-Content -Raw -LiteralPath $dependenciesPath | ConvertFrom-Json -ErrorAction Stop
$moduleOrder = @("PSScriptAnalyzer", "Pester")

foreach ($moduleName in $moduleOrder) {
    $moduleConfig = $dependencies.modules.PSObject.Properties[$moduleName]
    if (-not $moduleConfig) {
        Write-Host ("[FAIL] Module '{0}' is missing from {1}." -f $moduleName, $DependenciesManifestRelativePath) -ForegroundColor Red
        exit 1
    }

    $requiredVersion = [string]$moduleConfig.Value.requiredVersion
    if ([string]::IsNullOrWhiteSpace($requiredVersion)) {
        Write-Host ("[FAIL] Module '{0}' does not declare requiredVersion in {1}." -f $moduleName, $DependenciesManifestRelativePath) -ForegroundColor Red
        exit 1
    }

    Write-Host ("[INFO] Ensuring {0} {1} is available in CurrentUser scope." -f $moduleName, $requiredVersion) -ForegroundColor Cyan

    $installedModule = Get-Module -ListAvailable $moduleName |
        Where-Object { $_.Version -eq [version]$requiredVersion } |
        Select-Object -First 1

    if (-not $installedModule) {
        if ($PSCmdlet.ShouldProcess("$moduleName $requiredVersion", "Install QA dependency in CurrentUser scope")) {
            Install-Module $moduleName -Scope CurrentUser -Repository PSGallery -Force -RequiredVersion $requiredVersion -ErrorAction Stop
            $installedModule = Get-Module -ListAvailable $moduleName |
                Where-Object { $_.Version -eq [version]$requiredVersion } |
                Select-Object -First 1

            if (-not $installedModule) {
                Write-Host ("[FAIL] Installed module '{0}' did not resolve to required version {1}." -f $moduleName, $requiredVersion) -ForegroundColor Red
                exit 1
            }
        }
        else {
            Write-Host ("[INFO] Would install {0} {1} in CurrentUser scope." -f $moduleName, $requiredVersion) -ForegroundColor Cyan
            continue
        }
    }

    Write-Host ("[OK]   {0} {1} is available." -f $moduleName, $requiredVersion) -ForegroundColor Green
}

Write-Host "[OK]   QA dependencies are ready." -ForegroundColor Green
exit 0
