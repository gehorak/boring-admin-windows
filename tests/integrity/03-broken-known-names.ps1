[CmdletBinding()]
param()

Set-StrictMode -Version Latest

. "$PSScriptRoot\common.ps1"

$knownBrokenNames = @(
    '40-identity-local-accounts.manual.ps1',
    '45-identity-local-guest.manual.ps1',
    '50-host-identity.ps1',
    '31-software-packager-choco.ps1',
    '32-software-core-choco.ps1',
    '32-software-core-winget.ps1',
    '90-system-state-visibility.verify.ps1',
    'recovery-visibility.verify.ps1'
)

$files = Get-TrackedRepositoryFiles
$hits = New-Object System.Collections.Generic.List[object]

foreach ($file in $files) {
    if ((Format-RelativePath $file.FullName) -eq 'tests\integrity\03-broken-known-names.ps1') {
        continue
    }

    $content = Get-Content $file.FullName -Raw

    foreach ($name in $knownBrokenNames) {
        $pattern = '(?<![A-Za-z0-9_.-])' + [regex]::Escape($name) + '(?![A-Za-z0-9_.-])'
        if ([regex]::IsMatch($content, $pattern)) {
            $hits.Add([pscustomobject]@{
                File = Format-RelativePath $file.FullName
                Name = $name
            })
        }
    }
}

if ($hits.Count -eq 0) {
    Write-CheckResult -Check "broken-known-names" -Passed $true -Message "No known broken legacy names detected."
    exit 0
}

Write-CheckResult -Check "broken-known-names" -Passed $false -Message "$($hits.Count) known broken name reference(s) detected."
$hits | ForEach-Object {
    Write-Host (" - {0} -> {1}" -f $_.File, $_.Name)
}

exit 1
