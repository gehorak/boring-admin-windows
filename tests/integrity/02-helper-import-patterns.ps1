[CmdletBinding()]
param()

Set-StrictMode -Version Latest

. "$PSScriptRoot\common.ps1"

$psFiles = Get-TrackedRepositoryFiles -Extensions @("*.ps1")
$issues = New-Object System.Collections.Generic.List[object]

$acceptedPatterns = @(
    '. "$ProjectRoot\core\lib\common.ps1"',
    '. (Join-Path $ProjectRoot "core\lib\common.ps1")',
    '. "$PSScriptRoot\common.ps1"'
)

foreach ($file in $psFiles) {
    $lines = Get-Content $file.FullName

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i].Trim()

        if ($line -match '^\.\s+.*common\.ps1"?$') {
            $accepted = $false
            foreach ($pattern in $acceptedPatterns) {
                if ($line -eq $pattern) {
                    $accepted = $true
                    break
                }
            }

            if (-not $accepted) {
                $issues.Add([pscustomobject]@{
                    File = Format-RelativePath $file.FullName
                    Line = $i + 1
                    Text = $line
                })
            }
        }
    }
}

if ($issues.Count -eq 0) {
    Write-CheckResult -Check "helper-import-patterns" -Passed $true -Message "No invalid common.ps1 import patterns detected."
    exit 0
}

Write-CheckResult -Check "helper-import-patterns" -Passed $false -Message "$($issues.Count) suspicious helper import pattern(s) detected."
$issues | ForEach-Object {
    Write-Host (" - {0}:{1} -> {2}" -f $_.File, $_.Line, $_.Text)
}

exit 1
