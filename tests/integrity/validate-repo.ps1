[CmdletBinding()]
param()

Set-StrictMode -Version Latest

$checks = @(
    "00-reference-integrity.ps1",
    "01-powershell-parse.ps1",
    "02-helper-import-patterns.ps1",
    "03-broken-known-names.ps1",
    "04-verify-apply-separation.ps1",
    "05-public-ready-surface.ps1",
    "08-secrets-and-supply-chain.ps1",
    "09-public-cli-guardrails.ps1",
    "13-public-repository-boundary.ps1",
    "14-czech-onboarding-guidance.ps1"
)

$failed = $false

Write-Host ""
Write-Host "=== public integrity validation baseline ===" -ForegroundColor Cyan
Write-Host ""

foreach ($check in $checks) {
    $path = Join-Path $PSScriptRoot $check

    Write-Host ("-> Running {0}" -f $check) -ForegroundColor DarkGray
    & $path

    if ($LASTEXITCODE -ne 0) {
        $failed = $true
    }

    Write-Host ""
}

if ($failed) {
    Write-Host "[FAIL] integrity validation detected unresolved issues." -ForegroundColor Red
    exit 1
}

Write-Host "[PASS] integrity validation passed." -ForegroundColor Green
exit 0
