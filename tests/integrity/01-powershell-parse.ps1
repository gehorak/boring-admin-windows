[CmdletBinding()]
param()

Set-StrictMode -Version Latest

. "$PSScriptRoot\common.ps1"

$psFiles = Get-TrackedRepositoryFiles -Extensions @("*.ps1")
$errors = New-Object System.Collections.Generic.List[object]

foreach ($file in $psFiles) {
    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors) > $null

    foreach ($err in $parseErrors) {
        $errors.Add([pscustomobject]@{
            File    = Format-RelativePath $file.FullName
            Message = $err.Message
        })
    }
}

if ($errors.Count -eq 0) {
    Write-CheckResult -Check "powershell-parse" -Passed $true -Message "All tracked PowerShell files parsed successfully."
    exit 0
}

Write-CheckResult -Check "powershell-parse" -Passed $false -Message "$($errors.Count) parse error(s) detected."
$errors | ForEach-Object {
    Write-Host (" - {0}: {1}" -f $_.File, $_.Message)
}

exit 1
