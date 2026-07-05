[CmdletBinding()]
param()

Set-StrictMode -Version Latest

. "$PSScriptRoot\common.ps1"

$root = Get-RepositoryRoot
$issues = New-Object System.Collections.Generic.List[object]
$allowedMarkdownPaths = @(
    "README.md",
    "SECURITY.md",
    "LICENSE-SUMMARY.md",
    "COMMERCIAL.md",
    "TRADEMARKS.md",
    "docs/GETTING-STARTED.md",
    "docs/COMMANDS.md",
    "docs/COMMON-SCENARIOS.md",
    "docs/RECOVERY-PLAYBOOK.md",
    "docs/ANNUAL-MAINTENANCE.md",
    "docs/SOFTWARE.md",
    "docs/CONFIGURATION.md",
    "docs/CONTRIBUTING.md",
    "docs/TESTING.md",
    "docs/ARCHITECTURE.md",
    "docs/cs/README.md",
    "docs/cs/ZACINAME.md",
    "docs/cs/BEZNE-SCENARE.md",
    "docs/cs/BEZPECNE-POUZITI.md",
    "docs/cs/OBNOVA-A-STOP.md",
    "docs/cs/SLOVNIK.md"
)
$forbiddenPaths = @(
    ".github/CODEOWNERS",
    (".github/ISSUE_TEMPLATE/" + "bug-report.yml"),
    (".github/ISSUE_TEMPLATE/" + "documentation-feedback.yml"),
    "CHANGELOG.md",
    "CONTRIBUTING.md",
    "DISCLAIMER.md",
    "PROJECT-STATUS.md",
    "RELEASE-POLICY.md",
    "ROADMAP.md",
    "Makefile.audit",
    "Makefile.operational",
    ("config/" + "README.md"),
    ("config/profiles/" + "internal.example.json"),
    ("config/profiles/" + "public.sample.json"),
    ("config/schemas/" + "document-metadata.schema.json"),
    ("scripts/" + "README.md"),
    ("tests/" + "README.md"),
    ("tests/manual/" + "New-PostAuditValidationReport.ps1"),
    ("tests/vm/" + "Invoke-PostAuditScenario.ps1"),
    ("tests/vm/" + "Invoke-Scenario.ps1")
)
$forbiddenDocumentationPatterns = @(
    @{ Name = "internal"; Regex = '\binternal\b' },
    @{ Name = "private"; Regex = '\bprivate\b' },
    @{ Name = "handover"; Regex = '\bhandover\b' },
    @{ Name = "acceptance"; Regex = '\bacceptance\b' },
    @{ Name = "customer"; Regex = '\bcustomer\b' },
    @{ Name = "client"; Regex = '\bclient\b' },
    @{ Name = "service-delivery"; Regex = 'service delivery|service-delivery' },
    @{ Name = "governance"; Regex = '\bgovernance\b' },
    @{ Name = "roadmap"; Regex = '\broadmap\b' },
    @{ Name = "export-candidate"; Regex = 'export candidate|export-candidate' },
    @{ Name = "release-policy"; Regex = 'release policy|release-policy' },
    @{ Name = "audit-export"; Regex = 'audit export|audit-export' },
    @{ Name = "workstation-record"; Regex = 'workstation record|workstation-record' },
    @{ Name = "incident-classification"; Regex = 'incident classification|incident-classification' },
    @{ Name = "post-audit"; Regex = 'post-audit' }
)

$trackedFiles = Get-RepositoryFiles -Extensions @("*")
$trackedPaths = @(
    $trackedFiles |
    ForEach-Object { (Format-RelativePath $_.FullName) -replace '\\', '/' } |
    Sort-Object -Unique
)
$trackedMarkdownPaths = @(
    $trackedPaths |
    Where-Object { $_ -like "*.md" } |
    Sort-Object
)

foreach ($path in $allowedMarkdownPaths) {
    if ($path -notin $trackedMarkdownPaths) {
        $issues.Add([pscustomobject]@{
            Type   = "missing-allowed-markdown"
            Target = $path
        }) | Out-Null
    }
}

foreach ($path in $trackedMarkdownPaths) {
    if ($path -notin $allowedMarkdownPaths) {
        $issues.Add([pscustomobject]@{
            Type   = "unexpected-markdown"
            Target = $path
        }) | Out-Null
    }
}

foreach ($path in $forbiddenPaths) {
    if ($path -in $trackedPaths) {
        $issues.Add([pscustomobject]@{
            Type   = "forbidden-path"
            Target = $path
        }) | Out-Null
    }
}

$documentationScanPaths = @(
    $allowedMarkdownPaths | Where-Object { $_ -notin @("LICENSE-SUMMARY.md", "COMMERCIAL.md", "TRADEMARKS.md") }
)

foreach ($relativePath in $documentationScanPaths) {
    $fullPath = Join-Path $root ($relativePath -replace '/', '\')
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        continue
    }

    $content = Get-Content -Raw -LiteralPath $fullPath
    foreach ($pattern in $forbiddenDocumentationPatterns) {
        if ([regex]::IsMatch($content, $pattern.Regex, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)) {
            $issues.Add([pscustomobject]@{
                Type   = "forbidden-doc-term"
                Target = ("{0} -> {1}" -f $relativePath, $pattern.Name)
            }) | Out-Null
        }
    }
}

if ($issues.Count -eq 0) {
    Write-CheckResult -Check "public-repository-boundary" -Passed $true -Message "Tracked documentation matches the minimal public allowlist and avoids internal-operational wording."
    exit 0
}

Write-CheckResult -Check "public-repository-boundary" -Passed $false -Message "$($issues.Count) public-repository boundary issue(s) detected."
$issues | ForEach-Object {
    Write-Host (" - [{0}] {1}" -f $_.Type, $_.Target)
}

exit 1
