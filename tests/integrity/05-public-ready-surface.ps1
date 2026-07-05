[CmdletBinding()]
param()

Set-StrictMode -Version Latest

. "$PSScriptRoot\common.ps1"

$root = Get-RepositoryRoot
$requiredPaths = @(
    ".gitignore",
    "README.md",
    "SECURITY.md",
    "LICENSE",
    "LICENSE-SUMMARY.md",
    "COMMERCIAL.md",
    "TRADEMARKS.md",
    "PSScriptAnalyzerSettings.psd1",
    "boring-admin.ps1",
    "Makefile",
    ".github\workflows\qa.yml",
    "config\profiles\individual.example.json",
    "config\schemas\profile.schema.json",
    "docs\GETTING-STARTED.md",
    "docs\COMMANDS.md",
    "docs\COMMON-SCENARIOS.md",
    "docs\RECOVERY-PLAYBOOK.md",
    "docs\ANNUAL-MAINTENANCE.md",
    "docs\SOFTWARE.md",
    "docs\CONFIGURATION.md",
    "docs\CONTRIBUTING.md",
    "docs\TESTING.md",
    "docs\ARCHITECTURE.md",
    "docs\cs\README.md",
    "docs\cs\ZACINAME.md",
    "docs\cs\BEZNE-SCENARE.md",
    "docs\cs\BEZPECNE-POUZITI.md",
    "docs\cs\OBNOVA-A-STOP.md",
    "docs\cs\SLOVNIK.md",
    "tests\Invoke-Tests.ps1"
)

$missing = New-Object System.Collections.Generic.List[string]

foreach ($relativePath in $requiredPaths) {
    $fullPath = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        $missing.Add($relativePath) | Out-Null
    }
}

$gitignorePath = Join-Path $root ".gitignore"
$gitignoreContent = if (Test-Path -LiteralPath $gitignorePath -PathType Leaf) {
    Get-Content -Raw -LiteralPath $gitignorePath
}
else {
    ""
}

$requiredGitignorePatterns = @(
    'config/profiles/individual\.local\.json',
    'config/profiles/\*\.local\.json',
    '\.codex/',
    '\.vscode/',
    'artifacts/',
    '\.tmp/'
)
$missingIgnoreRules = @(
    $requiredGitignorePatterns | Where-Object { $gitignoreContent -notmatch $_ }
)

if ($missing.Count -eq 0 -and $missingIgnoreRules.Count -eq 0) {
    Write-CheckResult -Check "public-ready-surface" -Passed $true -Message "Required minimal public files and local-only ignore rules are present."
    exit 0
}

if ($missing.Count -gt 0) {
    Write-Host "[FAIL] Missing required public-facing files:" -ForegroundColor Red
    $missing | ForEach-Object {
        Write-Host (" - {0}" -f $_)
    }
}

if ($missingIgnoreRules.Count -gt 0) {
    Write-Host "[FAIL] .gitignore is missing required local-only path protection rules:" -ForegroundColor Red
    $missingIgnoreRules | ForEach-Object {
        Write-Host (" - {0}" -f $_)
    }
}

exit 1
