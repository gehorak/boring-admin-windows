[CmdletBinding()]
param(
    [ValidateSet("all", "lint", "integrity", "unit", "contract", "smoke")]
    [string] $Suite = "all"
)

Set-StrictMode -Version Latest

$TestRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$PesterBootstrap = Join-Path $TestRoot "Pester-Bootstrap.ps1"
$ScriptAnalyzerLint = Join-Path $TestRoot ".\lint\Invoke-Lint.ps1"

function Invoke-LintSuite {
    if (-not (Test-Path -LiteralPath $ScriptAnalyzerLint)) {
        Write-Host "[FAIL] Lint suite entrypoint not found: tests\\lint\\Invoke-Lint.ps1" -ForegroundColor Red
        return 1
    }

    Write-Host ""
    Write-Host "Running lint suite..." -ForegroundColor Cyan
    & $ScriptAnalyzerLint
    if ((Get-Variable LASTEXITCODE -ErrorAction SilentlyContinue) -and $LASTEXITCODE -ne 0) {
        if (Get-Variable LASTEXITCODE -ErrorAction SilentlyContinue) {
            return $LASTEXITCODE
        }

        return 1
    }

    return 0
}

function Invoke-IntegritySuite {
    $validationScript = Join-Path $TestRoot ".\integrity\validate-repo.ps1"

    if (-not (Test-Path -LiteralPath $validationScript)) {
        Write-Host "[FAIL] Integrity validation entrypoint not found: tests\\integrity\\validate-repo.ps1" -ForegroundColor Red
        return 1
    }

    Write-Host ""
    Write-Host "Running integrity validation..." -ForegroundColor Cyan
    & $validationScript
    if ((Get-Variable LASTEXITCODE -ErrorAction SilentlyContinue) -and $LASTEXITCODE -ne 0) {
        if (Get-Variable LASTEXITCODE -ErrorAction SilentlyContinue) {
            return $LASTEXITCODE
        }

        return 1
    }

    return 0
}

function Invoke-PesterSuite {
    param(
        [Parameter(Mandatory)]
        [string] $RelativePath
    )

    $suitePath = Join-Path $TestRoot $RelativePath

    if (-not (Test-Path -LiteralPath $suitePath)) {
        Write-Host "[FAIL] Test suite path not found: $RelativePath" -ForegroundColor Red
        return 1
    }

    if (-not (Test-Path -LiteralPath $PesterBootstrap)) {
        Write-Host "[FAIL] Pester bootstrap script not found: tests\\Pester-Bootstrap.ps1" -ForegroundColor Red
        return 1
    }

    $pesterInfo = & $PesterBootstrap
    if ((Get-Variable LASTEXITCODE -ErrorAction SilentlyContinue) -and $LASTEXITCODE -ne 0) {
        if (Get-Variable LASTEXITCODE -ErrorAction SilentlyContinue) {
            return $LASTEXITCODE
        }

        return 1
    }

    Write-Host ""
    Write-Host ("Using Pester {0}" -f $pesterInfo.Version) -ForegroundColor DarkGray
    Write-Host ("Running Pester suite: {0}" -f $RelativePath) -ForegroundColor Cyan
    $result = Invoke-Pester -Path $suitePath -PassThru

    if ($result.FailedCount -gt 0) {
        return 1
    }

    return 0
}

switch ($Suite) {
    "all" {
        Write-Host ""
        Write-Host "boring-admin-windows :: tests" -ForegroundColor Cyan
        Write-Host "Running the current minimum QA baseline." -ForegroundColor Cyan
        $failures = 0

        foreach ($suiteName in @("lint", "integrity", "smoke", "unit", "contract")) {
            switch ($suiteName) {
                "lint"      { $exitCode = Invoke-LintSuite }
                "integrity" { $exitCode = Invoke-IntegritySuite }
                "smoke"     { $exitCode = Invoke-PesterSuite -RelativePath "smoke" }
                "unit"      { $exitCode = Invoke-PesterSuite -RelativePath "unit" }
                "contract"  { $exitCode = Invoke-PesterSuite -RelativePath "contract" }
            }

            if ($exitCode -ne 0) {
                $failures++
            }
        }

        if ($failures -gt 0) {
            exit 1
        }

        exit 0
    }
    "lint" {
        exit (Invoke-LintSuite)
    }
    "integrity" {
        exit (Invoke-IntegritySuite)
    }
    "unit" {
        exit (Invoke-PesterSuite -RelativePath "unit")
    }
    "contract" {
        exit (Invoke-PesterSuite -RelativePath "contract")
    }
    "smoke" {
        exit (Invoke-PesterSuite -RelativePath "smoke")
    }
}
