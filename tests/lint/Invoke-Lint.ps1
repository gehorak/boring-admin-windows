[CmdletBinding()]
param()

Set-StrictMode -Version Latest

$LintRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$TestRoot = Split-Path -Parent $LintRoot
$RepositoryRoot = Split-Path -Parent $TestRoot
$bootstrapPath = Join-Path $TestRoot "ScriptAnalyzer-Bootstrap.ps1"
$settingsPath = Join-Path $RepositoryRoot "PSScriptAnalyzerSettings.psd1"

if (-not (Test-Path -LiteralPath $bootstrapPath)) {
    Write-Host "[FAIL] ScriptAnalyzer bootstrap script not found: tests\\ScriptAnalyzer-Bootstrap.ps1" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -LiteralPath $settingsPath)) {
    Write-Host "[FAIL] Analyzer settings not found: PSScriptAnalyzerSettings.psd1" -ForegroundColor Red
    exit 1
}

$analyzerInfo = & $bootstrapPath
if ((Get-Variable LASTEXITCODE -ErrorAction SilentlyContinue) -and $LASTEXITCODE -ne 0) {
    if (Get-Variable LASTEXITCODE -ErrorAction SilentlyContinue) {
        exit $LASTEXITCODE
    }

    exit 1
}

$pathsToAnalyze = @(
    (Join-Path $RepositoryRoot "boring-admin.ps1"),
    (Join-Path $RepositoryRoot "core"),
    (Join-Path $RepositoryRoot "scripts"),
    (Join-Path $RepositoryRoot "tests")
) | Where-Object { Test-Path -LiteralPath $_ }

Write-Host ""
Write-Host ("Using PSScriptAnalyzer {0}" -f $analyzerInfo.Version) -ForegroundColor DarkGray
Write-Host "Running lint suite..." -ForegroundColor Cyan

$results = foreach ($pathToAnalyze in $pathsToAnalyze) {
    Invoke-ScriptAnalyzer `
        -Path $pathToAnalyze `
        -Recurse `
        -Settings $settingsPath `
        -Severity @("Error", "Warning")
}

$results = @($results)

if ($results.Count -gt 0) {
    Write-Host ""
    $results |
        Sort-Object ScriptName, Line, RuleName |
        Format-Table RuleName, Severity, ScriptName, Line, Message -AutoSize

    Write-Host ""
    Write-Host ("[FAIL] PSScriptAnalyzer found {0} issue(s)." -f $results.Count) -ForegroundColor Red
    exit 1
}

Write-Host "[OK]   Lint completed without analyzer findings." -ForegroundColor Green
exit 0
