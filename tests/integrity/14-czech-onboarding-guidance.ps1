[CmdletBinding()]
param()

Set-StrictMode -Version Latest

. "$PSScriptRoot\common.ps1"

$root = Get-RepositoryRoot
$issues = New-Object System.Collections.Generic.List[object]
$documentContracts = @(
    @{
        Path     = "docs\cs\README.md"
        Patterns = @(
            'První bezpečný krok',
            'Když si nejsi jistý, zastav se.',
            'Tohle není druhá autorita'
        )
    },
    @{
        Path     = "docs\cs\ZACINAME.md"
        Patterns = @(
            'Tenhle projekt je pro člověka, který:',
            'Tenhle projekt není pro:',
            '## Rozdíl mezi `check`, `plan` a `apply`',
            'Nezačínej `apply`.'
        )
    },
    @{
        Path     = "docs\cs\BEZPECNE-POUZITI.md"
        Patterns = @(
            'nejdřív `check`,',
            'neobcházej Execution Policy',
            'Když si nejsi jistý,'
        )
    },
    @{
        Path     = "docs\cs\BEZNE-SCENARE.md"
        Patterns = @(
            '## Převzetí existujícího počítače',
            '## Nový nebo přeinstalovaný počítač',
            '## Roční kontrola'
        )
    },
    @{
        Path     = "docs\cs\OBNOVA-A-STOP.md"
        Patterns = @(
            '## Před rizikovějším zásahem',
            '## Kdy máš přestat',
            '## Kdy vyhledat odbornou pomoc',
            'existuje záloha'
        )
    },
    @{
        Path     = "docs\cs\SLOVNIK.md"
        Patterns = @(
            '## Baseline',
            '## Overlay',
            '## Drift',
            '## Recovery'
        )
    }
)

foreach ($contract in $documentContracts) {
    $documentPath = Join-Path $root $contract.Path

    if (-not (Test-Path -LiteralPath $documentPath -PathType Leaf)) {
        $issues.Add([pscustomobject]@{
            Type    = "missing-file"
            Target  = $contract.Path
            Details = "<file missing>"
        }) | Out-Null
        continue
    }

    $content = Get-Content -Raw -LiteralPath $documentPath
    foreach ($pattern in $contract.Patterns) {
        if (-not $content.Contains($pattern)) {
            $issues.Add([pscustomobject]@{
                Type    = "missing-pattern"
                Target  = $contract.Path
                Details = $pattern
            }) | Out-Null
        }
    }

    if ($content -notmatch '[áéíóúůýčďěňřšťžÁÉÍÓÚŮÝČĎĚŇŘŠŤŽ]') {
        $issues.Add([pscustomobject]@{
            Type    = "missing-diacritics"
            Target  = $contract.Path
            Details = "Czech documentation should contain natural Czech diacritics."
        }) | Out-Null
    }
}

if ($issues.Count -eq 0) {
    Write-CheckResult -Check "czech-onboarding-guidance" -Passed $true -Message "Czech onboarding remains practical, safe, and written in natural Czech."
    exit 0
}

Write-CheckResult -Check "czech-onboarding-guidance" -Passed $false -Message "$($issues.Count) Czech onboarding issue(s) detected."
$issues | ForEach-Object {
    Write-Host (" - [{0}] {1} -> {2}" -f $_.Type, $_.Target, $_.Details)
}

exit 1
