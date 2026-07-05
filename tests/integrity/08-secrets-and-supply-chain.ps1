[CmdletBinding()]
param()

Set-StrictMode -Version Latest

. "$PSScriptRoot\common.ps1"

$root = Get-RepositoryRoot
$issues = New-Object System.Collections.Generic.List[object]
$trackedFiles = Get-TrackedRepositoryFiles -Extensions @("*.md", "*.ps1", "*.json", "*.yml", "*.yaml", "*.txt", "Makefile*")
$secretPatterns = @(
    @{ Name = "private-key-block"; Regex = '-----BEGIN [A-Z ]*PRIVATE KEY-----' },
    @{ Name = "github-classic-token"; Regex = 'ghp_[A-Za-z0-9]{20,}' },
    @{ Name = "github-fine-grained-token"; Regex = 'github_pat_[A-Za-z0-9_]{20,}' },
    @{ Name = "aws-access-key"; Regex = 'AKIA[0-9A-Z]{16}' },
    @{ Name = "aws-session-key"; Regex = 'ASIA[0-9A-Z]{16}' },
    @{ Name = "slack-token"; Regex = 'xox[baprs]-[A-Za-z0-9-]{10,}' }
)
$forbiddenScriptTransportPatterns = @(
    @{ Name = "remote-script-execution"; Regex = 'Invoke-Expression' },
    @{ Name = "remote-chocolatey-bootstrap"; Regex = 'https://community\.chocolatey\.org/install\.ps1' }
)

foreach ($file in $trackedFiles) {
    $relativePath = Format-RelativePath $file.FullName
    if ($relativePath -eq "tests\integrity\08-secrets-and-supply-chain.ps1") {
        continue
    }

    $content = Get-Content -Raw -LiteralPath $file.FullName

    foreach ($pattern in $secretPatterns) {
        if ([regex]::IsMatch($content, $pattern.Regex)) {
            $issues.Add([pscustomobject]@{
                Type    = "secret-pattern"
                Target  = $relativePath
                Details = $pattern.Name
            }) | Out-Null
        }
    }

    if ($file.Extension -ieq ".ps1") {
        foreach ($pattern in $forbiddenScriptTransportPatterns) {
            if ([regex]::IsMatch($content, $pattern.Regex)) {
                $issues.Add([pscustomobject]@{
                    Type    = "supply-chain-script"
                    Target  = $relativePath
                    Details = "Forbidden bootstrap pattern present: $($pattern.Name)"
                }) | Out-Null
            }
        }
    }
}

$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) {
    & git -C $root ls-files --error-unmatch "config/profiles/individual.local.json" *> $null
    if ($LASTEXITCODE -eq 0) {
        $issues.Add([pscustomobject]@{
            Type    = "tracked-secret-path"
            Target  = "config\profiles\individual.local.json"
            Details = "Local writable profile path must remain untracked."
        }) | Out-Null
    }
}

$workflowPath = Join-Path $root ".github\workflows\qa.yml"
$qaBootstrapPath = Join-Path $root "tests\Install-QADependencies.ps1"
if (-not (Test-Path -LiteralPath $workflowPath -PathType Leaf)) {
    $issues.Add([pscustomobject]@{
        Type    = "workflow"
        Target  = ".github\workflows\qa.yml"
        Details = "QA workflow is missing."
    }) | Out-Null
}
else {
    $workflowContent = Get-Content -Raw -LiteralPath $workflowPath

    $requiredWorkflowPatterns = @(
        '08-secrets-and-supply-chain.ps1',
        'tests\qa-dependencies.json',
        'Install-Module PSScriptAnalyzer -Scope CurrentUser -Repository PSGallery -Force -RequiredVersion',
        'Install-Module Pester -Scope CurrentUser -Repository PSGallery -Force -RequiredVersion'
    )
    $requiredWorkflowRegexPatterns = @(
        @{
            Name  = "actions-checkout-pinned-sha"
            Regex = 'actions/checkout@[0-9a-f]{40}'
        }
    )

    foreach ($pattern in $requiredWorkflowPatterns) {
        if (-not $workflowContent.Contains($pattern)) {
            $issues.Add([pscustomobject]@{
                Type    = "workflow"
                Target  = ".github\workflows\qa.yml"
                Details = "Missing required pattern: $pattern"
            }) | Out-Null
        }
    }

    foreach ($pattern in $requiredWorkflowRegexPatterns) {
        if (-not [regex]::IsMatch($workflowContent, $pattern.Regex)) {
            $issues.Add([pscustomobject]@{
                Type    = "workflow"
                Target  = ".github\workflows\qa.yml"
                Details = "Missing required workflow guardrail: $($pattern.Name)"
            }) | Out-Null
        }
    }

    if ([regex]::IsMatch($workflowContent, 'actions/checkout@v[0-9]+')) {
        $issues.Add([pscustomobject]@{
            Type    = "workflow"
            Target  = ".github\workflows\qa.yml"
            Details = "actions/checkout must be pinned to a full commit SHA, not a moving version tag."
        }) | Out-Null
    }

    if ($workflowContent.Contains("-SkipPublisherCheck")) {
        $issues.Add([pscustomobject]@{
            Type    = "workflow"
            Target  = ".github\workflows\qa.yml"
            Details = "QA bootstrap must not rely on -SkipPublisherCheck."
        }) | Out-Null
    }

    if ($workflowContent.Contains("Set-PSRepository -Name PSGallery -InstallationPolicy Trusted")) {
        $issues.Add([pscustomobject]@{
            Type    = "workflow"
            Target  = ".github\workflows\qa.yml"
            Details = "QA bootstrap must not mutate PSGallery trust policy."
        }) | Out-Null
    }
}

if (-not (Test-Path -LiteralPath $qaBootstrapPath -PathType Leaf)) {
    $issues.Add([pscustomobject]@{
        Type    = "qa-bootstrap"
        Target  = "tests\Install-QADependencies.ps1"
        Details = "Local QA bootstrap script is missing."
    }) | Out-Null
}
else {
    $qaBootstrapContent = Get-Content -Raw -LiteralPath $qaBootstrapPath

    $requiredBootstrapPatterns = @(
        '[CmdletBinding(SupportsShouldProcess = $true)]',
        'tests\qa-dependencies.json',
        'Install-Module $moduleName -Scope CurrentUser -Repository PSGallery -Force -RequiredVersion $requiredVersion'
    )

    foreach ($pattern in $requiredBootstrapPatterns) {
        if (-not $qaBootstrapContent.Contains($pattern)) {
            $issues.Add([pscustomobject]@{
                Type    = "qa-bootstrap"
                Target  = "tests\Install-QADependencies.ps1"
                Details = "Missing required pattern: $pattern"
            }) | Out-Null
        }
    }

    foreach ($forbiddenPattern in @(
        "-SkipPublisherCheck",
        "ExecutionPolicy Bypass",
        "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted"
    )) {
        if ($qaBootstrapContent.Contains($forbiddenPattern)) {
            $issues.Add([pscustomobject]@{
                Type    = "qa-bootstrap"
                Target  = "tests\Install-QADependencies.ps1"
                Details = "Forbidden pattern present: $forbiddenPattern"
            }) | Out-Null
        }
    }
}

if ($issues.Count -eq 0) {
    Write-CheckResult -Check "secrets-and-supply-chain" -Passed $true -Message "No tracked secret patterns and no QA bootstrap supply-chain guardrail issues detected."
    exit 0
}

Write-CheckResult -Check "secrets-and-supply-chain" -Passed $false -Message "$($issues.Count) secret or supply-chain issue(s) detected."
$issues | ForEach-Object {
    Write-Host (" - [{0}] {1} -> {2}" -f $_.Type, $_.Target, $_.Details)
}

exit 1
