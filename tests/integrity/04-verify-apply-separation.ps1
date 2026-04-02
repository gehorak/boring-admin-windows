[CmdletBinding()]
param()

Set-StrictMode -Version Latest

. "$PSScriptRoot\common.ps1"

$root = Get-RepositoryRoot
$verifyRoot = Join-Path $root "scripts\verify"
$verifyFiles = Get-ChildItem -Path $verifyRoot -Recurse -File -Filter *.ps1 -ErrorAction SilentlyContinue
$violations = New-Object System.Collections.Generic.List[object]

$forbiddenPatterns = @(
    'scripts/apply/',
    'scripts\apply\',
    'scripts/overlay/',
    'scripts\overlay\',
    'Invoke-Script "scripts/apply/',
    'Invoke-Script "scripts\apply\',
    'Invoke-Script "scripts/overlay/',
    'Invoke-Script "scripts\overlay\'
)

foreach ($file in $verifyFiles) {
    $content = Get-Content $file.FullName -Raw

    foreach ($pattern in $forbiddenPatterns) {
        if ($content.Contains($pattern)) {
            $violations.Add([pscustomobject]@{
                File    = Format-RelativePath $file.FullName
                Pattern = $pattern
            })
        }
    }
}

if ($violations.Count -eq 0) {
    Write-CheckResult -Check "verify-apply-separation" -Passed $true -Message "No direct verify -> apply/overlay references detected."
    exit 0
}

Write-CheckResult -Check "verify-apply-separation" -Passed $false -Message "$($violations.Count) verify/apply separation violation(s) detected."
$violations | ForEach-Object {
    Write-Host (" - {0} -> {1}" -f $_.File, $_.Pattern)
}

exit 1
