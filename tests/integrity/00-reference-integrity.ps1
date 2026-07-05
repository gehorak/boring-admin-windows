[CmdletBinding()]
param()

Set-StrictMode -Version Latest

. "$PSScriptRoot\common.ps1"

$root = Get-RepositoryRoot
$results = New-Object System.Collections.Generic.List[object]
$files = Get-TrackedRepositoryFiles
$knownMissingTestReferences = @{
    "tests\unit\02-config.Tests.ps1" = @(
        "config/profiles/does-not-exist.json"
    )
}
$knownOptionalRepositoryReferences = @(
    "config\profiles\individual.local.json"
)

function Test-ReferenceCandidate {
    param(
        [Parameter(Mandatory)]
        [string] $Reference
    )

    if ($Reference -match '^(https?:\/\/|file:\/\/|app:\/\/|plugin:\/\/)') {
        return $false
    }

    if ($Reference -match '^\$') {
        return $false
    }

    if ($Reference -match '^(HKLM:|HKCU:|C:\\|\\\\\?\\)') {
        return $false
    }

    if ($Reference.Contains('<') -or $Reference.Contains('>')) {
        return $false
    }

    if ($Reference -match '\s') {
        return $false
    }

    if ($Reference -notmatch '[\\/]' -and $Reference -notmatch '^\.\.?[\\/]') {
        return $false
    }

    return $true
}

function Test-RegexEscapedReference {
    param(
        [Parameter(Mandatory)]
        [string] $Reference
    )

    return $Reference -match '\\[.^$+?()[\]{}|]'
}

function Test-KnownMissingTestReference {
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo] $File,

        [Parameter(Mandatory)]
        [string] $Reference
    )

    $relativePath = Format-RelativePath $File.FullName
    if (-not $knownMissingTestReferences.ContainsKey($relativePath)) {
        if ($relativePath -ieq "tests\integrity\00-reference-integrity.ps1") {
            foreach ($knownReferenceSet in $knownMissingTestReferences.Values) {
                if ($Reference -in $knownReferenceSet) {
                    return $true
                }
            }
        }

        return $false
    }

    return $Reference -in $knownMissingTestReferences[$relativePath]
}

function Test-KnownOptionalRepositoryReference {
    param(
        [Parameter(Mandatory)]
        [string] $Reference
    )

    $normalized = ($Reference -replace '/', '\').TrimStart('.').TrimStart('\')
    return $normalized -in $knownOptionalRepositoryReferences
}

function Resolve-ReferenceCandidate {
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo] $File,

        [Parameter(Mandatory)]
        [string] $Reference
    )

    $normalized = $Reference -replace '/', '\'

    if ($normalized -match '^\.\.?\\') {
        $base = Split-Path -Parent $File.FullName
        $fileRelativeCandidate = Join-Path $base $normalized
        if (Test-Path -LiteralPath $fileRelativeCandidate) {
            return $fileRelativeCandidate
        }

        if ($normalized -match '^\.[\\]') {
            return Join-Path $root ($normalized.Substring(2))
        }

        return $fileRelativeCandidate
    }

    if (($File.Extension -ieq ".md") -and ($normalized -notmatch '^[A-Za-z]:\\')) {
        $base = Split-Path -Parent $File.FullName

        if ($normalized -match '^\.\.?\\') {
            return Join-Path $base $normalized
        }

        $fileRelativeCandidate = Join-Path $base $normalized
        if (Test-Path -LiteralPath $fileRelativeCandidate) {
            return $fileRelativeCandidate
        }

        return Join-Path $root $normalized
    }

    return Join-Path $root $normalized
}

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $candidates = New-Object System.Collections.Generic.List[string]

    switch -Wildcard ($file.Name) {
        "*.md" {
            [regex]::Matches($content, '`([^`]+\.(?:md|ps1|json|ya?ml|txt))`') | ForEach-Object {
                $candidates.Add($_.Groups[1].Value)
            }

            [regex]::Matches($content, '\(([^)]+\.(?:md|ps1|json|ya?ml|txt))\)') | ForEach-Object {
                $candidates.Add($_.Groups[1].Value)
            }
        }
        "*.ps1" {
            [regex]::Matches($content, '["'']([./A-Za-z0-9_\\-][A-Za-z0-9_./\\-]*\.(?:md|ps1|json|ya?ml|txt))["'']') | ForEach-Object {
                $candidates.Add($_.Groups[1].Value)
            }
        }
        "Makefile*" {
            [regex]::Matches($content, '([./A-Za-z0-9_\\-][A-Za-z0-9_./\\-]*\.(?:md|ps1|json|ya?ml|txt))') | ForEach-Object {
                $candidates.Add($_.Groups[1].Value)
            }
        }
    }

    $candidates | Sort-Object -Unique | ForEach-Object {
        $reference = $_

        if (-not (Test-ReferenceCandidate -Reference $reference)) {
            return
        }

        if (Test-RegexEscapedReference -Reference $reference) {
            return
        }

        if (Test-KnownMissingTestReference -File $file -Reference $reference) {
            return
        }

        if (Test-KnownOptionalRepositoryReference -Reference $reference) {
            return
        }

        $resolved = Resolve-ReferenceCandidate -File $file -Reference $reference

        if (-not (Test-Path -LiteralPath $resolved)) {
            $results.Add([pscustomobject]@{
                Passed = $false
                File   = Format-RelativePath $file.FullName
                Ref    = $reference
            })
        }
    }
}

if ($results.Count -eq 0) {
    Write-CheckResult -Check "reference-integrity" -Passed $true -Message "No unresolved tracked-file references detected."
    exit 0
}

Write-CheckResult -Check "reference-integrity" -Passed $false -Message "$($results.Count) unresolved tracked-file reference(s) detected."
$results | ForEach-Object {
    Write-Host (" - {0} -> {1}" -f $_.File, $_.Ref)
}

exit 1
