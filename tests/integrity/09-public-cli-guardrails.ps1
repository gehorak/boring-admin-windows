[CmdletBinding()]
param()

Set-StrictMode -Version Latest

. "$PSScriptRoot\common.ps1"

$root = Get-RepositoryRoot
$issues = New-Object System.Collections.Generic.List[object]

$boundaryPowerShellFiles = @(
    "boring-admin.ps1",
    "core\lib\common.ps1",
    "core\lib\config.ps1"
)

foreach ($relativePath in $boundaryPowerShellFiles) {
    $fullPath = Join-Path $root $relativePath

    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        $issues.Add([pscustomobject]@{
            Type    = "boundary-file"
            Target  = $relativePath
            Details = "Required boundary file is missing."
        }) | Out-Null
        continue
    }

    $content = Get-Content -Raw -LiteralPath $fullPath

    if ($content -match 'Set-StrictMode\s+-Version\s+Latest') {
        $issues.Add([pscustomobject]@{
            Type    = "strict-mode"
            Target  = $relativePath
            Details = "Boundary PowerShell files must pin StrictMode instead of using Latest."
        }) | Out-Null
    }

    if ($content -notmatch 'Set-StrictMode\s+-Version\s+3\.0') {
        $issues.Add([pscustomobject]@{
            Type    = "strict-mode"
            Target  = $relativePath
            Details = "Boundary PowerShell files must pin Set-StrictMode -Version 3.0."
        }) | Out-Null
    }

    if ($content -notmatch "\`$ErrorActionPreference\s*=\s*'Stop'") {
        $issues.Add([pscustomobject]@{
            Type    = "error-action"
            Target  = $relativePath
            Details = "Boundary PowerShell files must set `$ErrorActionPreference = 'Stop'."
        }) | Out-Null
    }
}

$rootShellFiles = Get-ChildItem -Path $root -File | Where-Object {
    $_.Name -like "*.ps1" -or
    $_.Name -like "*.cmd" -or
    $_.Name -like "*.bat" -or
    $_.Name -like "*.sh" -or
    $_.Name -like "Makefile*"
}

$allowedRootShellSurface = @(
    "boring-admin.ps1",
    "Makefile"
)

foreach ($file in $rootShellFiles) {
    if ($file.Name -notin $allowedRootShellSurface) {
        $issues.Add([pscustomobject]@{
            Type    = "shell-surface"
            Target  = $file.Name
            Details = "Unexpected root shell entry surface."
        }) | Out-Null
    }
}

$makefilePath = Join-Path $root "Makefile"
if (-not (Test-Path -LiteralPath $makefilePath -PathType Leaf)) {
    $issues.Add([pscustomobject]@{
        Type    = "makefile"
        Target  = "Makefile"
        Details = "The public discovery Makefile is missing."
    }) | Out-Null
}
else {
    $makefileContent = Get-Content -Raw -LiteralPath $makefilePath
    $actualTargets = @(
        [regex]::Matches($makefileContent, '(?m)^(?<target>[A-Za-z0-9][A-Za-z0-9-]*):') |
            ForEach-Object { $_.Groups["target"].Value } |
            Sort-Object -Unique
    )
    $expectedTargets = @("help", "info", "check-env")

    foreach ($target in @($actualTargets | Where-Object { $_ -notin $expectedTargets })) {
        $issues.Add([pscustomobject]@{
            Type    = "makefile-target"
            Target  = "Makefile"
            Details = "Unexpected target: $target"
        }) | Out-Null
    }

    foreach ($target in @($expectedTargets | Where-Object { $_ -notin $actualTargets })) {
        $issues.Add([pscustomobject]@{
            Type    = "makefile-target"
            Target  = "Makefile"
            Details = "Missing required target: $target"
        }) | Out-Null
    }
}

if ($issues.Count -eq 0) {
    Write-CheckResult -Check "public-cli-guardrails" -Passed $true -Message "Boundary strict-mode pinning and the minimal root shell surface are intact."
    exit 0
}

Write-CheckResult -Check "public-cli-guardrails" -Passed $false -Message "$($issues.Count) public CLI guardrail issue(s) detected."
$issues | ForEach-Object {
    Write-Host (" - [{0}] {1} -> {2}" -f $_.Type, $_.Target, $_.Details)
}

exit 1
