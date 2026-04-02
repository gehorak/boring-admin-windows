<#
===============================================================================
boring-admin-windows :: boring-admin.ps1

PURPOSE
-------
Provide a Windows-native, PowerShell-first operational entrypoint for the
repository without requiring GNU Make.

This script mirrors the intent of:
- Makefile              -> info / explorer / safe discovery
- Makefile.audit        -> read-only audit / verify / recovery visibility
- Makefile.operational  -> explicit apply / overlay entrypoints

This script EXISTS TO:
- expose repository capabilities in one Windows-native CLI
- reduce friction on Windows systems
- keep capability discovery close to execution
- preserve explicit operator control

This script DOES NOT:
- decide what should be run
- hide workflow transitions
- continue through write actions by habit
- replace documentation or operator judgment

DESIGN PRINCIPLES
-----------------
- explicit over implicit
- read-only discovery first
- verify != apply
- operator remains the authority
- readable in 5-10 years
===============================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string] $Layer,

    [Parameter(Position = 1)]
    [string] $Scope
)

Set-StrictMode -Version Latest


# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------

$RepositoryRoot = Split-Path -Parent $MyInvocation.MyCommand.Path


# -----------------------------------------------------------------------------
# Output helpers
# -----------------------------------------------------------------------------

function Write-MakeHeader {
    param(
        [Parameter(Mandatory)]
        [string] $Title
    )

    Write-Host ""
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ("-" * $Title.Length) -ForegroundColor DarkGray
    Write-Host ""
}

function Write-MakeInfo {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-Host "[INFO] $Message"
}

function Write-MakeWarn {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-MakeFail {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Write-MakeCommand {
    param(
        [Parameter(Mandatory)]
        [string] $Command,

        [string] $Description
    )

    if ($Description) {
        Write-Host ("  {0,-38} {1}" -f $Command, $Description)
        return
    }

    Write-Host "  $Command"
}


# -----------------------------------------------------------------------------
# Utility
# -----------------------------------------------------------------------------

function Resolve-RepoPath {
    param(
        [Parameter(Mandatory)]
        [string] $RelativePath
    )

    return Join-Path $RepositoryRoot $RelativePath
}

function Get-AuditOutputDirectory {
    $base = if ($env:TEMP) { $env:TEMP } else { [System.IO.Path]::GetTempPath() }
    $directory = Join-Path $base "boring-admin-windows\\audit"
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    return $directory
}

function Invoke-RepoScript {
    param(
        [Parameter(Mandatory)]
        [string] $RelativePath,

        [string[]] $ArgumentList = @()
    )

    $path = Resolve-RepoPath -RelativePath $RelativePath

    if (-not (Test-Path -LiteralPath $path)) {
        Write-MakeFail "Script not found: $RelativePath"
        exit 1
    }

    Write-Host ""
    Write-Host "Invoking script:" -ForegroundColor DarkGray
    Write-Host "  $RelativePath"
    Write-Host ""

    & $path @ArgumentList
    exit $LASTEXITCODE
}

function Show-PrimaryHelp {
    Write-MakeHeader "boring-admin-windows :: boring-admin.ps1"

    Write-Host "DISCOVERY / ENTRY:"
    Write-MakeCommand ".\boring-admin.ps1 help" "full entrypoint overview"
    Write-MakeCommand ".\boring-admin.ps1 info" "repository structure and authority hints"
    Write-MakeCommand ".\boring-admin.ps1 setup" "recommended first workstation setup path"
    Write-MakeCommand ".\boring-admin.ps1 check-env" "local tooling and shell check"
    Write-Host ""

    Write-Host "READ-ONLY PATHS:"
    Write-MakeCommand ".\boring-admin.ps1 audit help" "audit and verify surface"
    Write-MakeCommand ".\boring-admin.ps1 audit all" "full read-only audit"
    Write-MakeCommand ".\boring-admin.ps1 audit export" "machine-readable JSON aggregate"
    Write-MakeCommand ".\boring-admin.ps1 audit save" "save human-readable audit to file"
    Write-MakeCommand ".\boring-admin.ps1 audit summary" "short operator summary report"
    Write-MakeCommand ".\boring-admin.ps1 verify all" "alias for full read-only audit"
    Write-MakeCommand ".\boring-admin.ps1 verify security" "single scoped verify"
    Write-MakeCommand ".\boring-admin.ps1 verify software" "software transport and inventory visibility"
    Write-Host ""

    Write-Host "WRITE-CAPABLE PATHS:"
    Write-MakeCommand ".\boring-admin.ps1 operational help" "write-capable entrypoint overview"
    Write-MakeCommand ".\boring-admin.ps1 apply identity" "baseline identity changes"
    Write-MakeCommand ".\boring-admin.ps1 overlay software" "optional software overlay"
    Write-Host ""

    Write-Host "RULES:"
    Write-Host "  - Read first. Observe second. Act explicitly."
    Write-Host "  - No implicit verify -> apply chaining exists here."
    Write-Host "  - Aggregates remain read-only unless explicitly documented otherwise."
    Write-Host "  - Most verify scripts require an elevated shell."
    Write-Host ""
    Write-Host "RECOMMENDED NEXT STEPS:"
    Write-Host "  1. .\boring-admin.ps1 info"
    Write-Host "  2. .\boring-admin.ps1 setup"
    Write-Host "  3. .\boring-admin.ps1 audit all"
    Write-Host ""
}

function Show-Info {
    Write-MakeHeader "Repository Overview"

    Write-Host "Entry surfaces:"
    Write-Host "  Makefile              -> info / explorer / safe discovery"
    Write-Host "  Makefile.audit        -> audit / verify / recovery (read-only)"
    Write-Host "  Makefile.operational  -> apply / overlay (write-capable)"
    Write-Host "  boring-admin.ps1      -> Windows-native equivalent entrypoint"
    Write-Host ""

    Write-Host "Script layout:"
    Write-Host "  scripts/verify/*      -> observe system state"
    Write-Host "  scripts/apply/*       -> change baseline state"
    Write-Host "  scripts/overlay/*     -> optional software / UX"
    Write-Host "  scripts/migrate/*     -> bootstrap / one-time steps"
    Write-Host ""

    Write-Host "Documentation anchors:"
    Write-Host "  README.md"
    Write-Host "  docs/AUTHORITY.md"
    Write-Host "  docs/REPOSITORY-STATUS.md"
    Write-Host "  docs/BOUNDARIES.md"
    Write-Host "  docs/COMMANDS.md"
    Write-Host "  docs/FIRST-WORKSTATION-SETUP.md"
    Write-Host "  docs/STRUCTURE.md"
    Write-Host "  docs/ARCHITECTURE-v002.md"
    Write-Host ""

    Write-MakeInfo "No desired state is stored."
    Write-MakeInfo "The operator remains the authority."
    Write-MakeInfo "Use '.\boring-admin.ps1 audit export' for machine-readable JSON output."
    Write-MakeInfo "Use '.\boring-admin.ps1 audit save' to archive a text audit outside the repo."
}

function Show-SetupPath {
    Write-MakeHeader "First Workstation Setup Path"

    Write-Host "RECOMMENDED ORDER:"
    Write-Host "  1. check-env"
    Write-Host "  2. scripts\\migrate\\00-env-preflight.ps1"
    Write-Host "  3. scripts\\migrate\\10-bootstrap-orchestrator.ps1"
    Write-Host "  4. verify security -> apply security"
    Write-Host "  5. verify identity -> apply identity"
    Write-Host "  6. verify host -> apply host"
    Write-Host "  7. optional overlays"
    Write-Host "  8. verify all / audit all"
    Write-Host ""

    Write-Host "QUICK COMMANDS:"
    Write-Host "  .\\boring-admin.ps1 check-env"
    Write-Host "  .\\scripts\\migrate\\00-env-preflight.ps1"
    Write-Host "  .\\scripts\\migrate\\10-bootstrap-orchestrator.ps1"
    Write-Host "  .\\boring-admin.ps1 verify security"
    Write-Host "  .\\boring-admin.ps1 apply security"
    Write-Host "  .\\boring-admin.ps1 verify identity"
    Write-Host "  .\\boring-admin.ps1 apply identity"
    Write-Host "  .\\boring-admin.ps1 verify host"
    Write-Host "  .\\boring-admin.ps1 apply host"
    Write-Host "  .\\boring-admin.ps1 verify all"
    Write-Host ""

    Write-Host "REFERENCE:"
    Write-Host "  docs\\FIRST-WORKSTATION-SETUP.md"
    Write-Host ""
}

function Invoke-CheckEnv {
    Write-MakeHeader "Environment Check"

    Write-MakeInfo "Checking PowerShell availability..."
    Write-Host ("  PowerShell: {0}" -f $PSVersionTable.PSVersion)
    Write-Host ""

    Write-MakeInfo "Checking make availability..."
    $makeCommand = Get-Command make -ErrorAction SilentlyContinue
    if ($makeCommand) {
        Write-Host ("  make: {0}" -f $makeCommand.Source)
    }
    else {
        Write-MakeWarn "GNU Make not found in PATH."
    }

    Write-Host ""
    Write-MakeInfo "Environment check finished."
    Write-MakeInfo "Next step: '.\boring-admin.ps1 setup' or '.\boring-admin.ps1 audit all'"
}

function Show-AuditHelp {
    Write-MakeHeader "Audit / Verify / Recovery"

    Write-Host "READ-ONLY commands:"
    Write-MakeCommand ".\boring-admin.ps1 audit all" "run all verify scopes"
    Write-MakeCommand ".\boring-admin.ps1 audit export" "emit machine-readable JSON aggregate"
    Write-MakeCommand ".\boring-admin.ps1 audit save" "save human-readable audit to file"
    Write-MakeCommand ".\boring-admin.ps1 audit summary" "show short operator-facing summary"
    Write-MakeCommand ".\boring-admin.ps1 audit recovery" "recovery-only visibility"
    Write-MakeCommand ".\boring-admin.ps1 verify all" "alias for audit all"
    Write-MakeCommand ".\boring-admin.ps1 verify security" "security visibility snapshot"
    Write-MakeCommand ".\boring-admin.ps1 verify software" "software transport and inventory visibility"
    Write-MakeCommand ".\boring-admin.ps1 verify identity" "local identity visibility"
    Write-MakeCommand ".\boring-admin.ps1 verify host" "host identity visibility"
    Write-MakeCommand ".\boring-admin.ps1 verify system" "one-screen system audit"
    Write-MakeCommand ".\boring-admin.ps1 verify recovery" "recovery visibility and checklist references"
    Write-Host ""

    Write-Host "NOTES:"
    Write-Host "  - audit all runs all verify scopes"
    Write-Host "  - audit export emits a machine-readable JSON aggregate"
    Write-Host "  - audit save writes a text snapshot to the temp audit directory"
    Write-Host "  - audit summary compresses all verify scopes for fast human review"
    Write-Host "  - verify all is an alias for the same read-only aggregate"
    Write-Host "  - audit recovery is visibility only"
    Write-Host "  - no apply or overlay actions exist in this layer"
    Write-Host "  - most scoped verify commands require an elevated shell"
    Write-Host ""
}

function Show-OperationalHelp {
    Write-MakeHeader "Operational Apply / Overlay"

    Write-Host "WRITE-CAPABLE commands:"
    Write-MakeCommand ".\boring-admin.ps1 apply security" "baseline security changes"
    Write-MakeCommand ".\boring-admin.ps1 apply identity" "baseline identity changes"
    Write-MakeCommand ".\boring-admin.ps1 apply host" "baseline host identity changes"
    Write-MakeCommand ".\boring-admin.ps1 overlay software" "optional software lifecycle surface"
    Write-MakeCommand ".\boring-admin.ps1 overlay ux" "optional UX overlay surface"
    Write-Host ""

    Write-Host "NOTES:"
    Write-Host "  - apply changes baseline state"
    Write-Host "  - overlay is optional and non-baseline"
    Write-Host "  - no write aggregate is provided here"
    Write-Host "  - review audit output before applying changes"
    Write-Host "  - run these only from an elevated shell"
    Write-Host ""

    Write-Host "RECOMMENDED SAFETY FLOW:"
    Write-Host "  1. .\boring-admin.ps1 audit all"
    Write-Host "  2. choose exactly one apply or overlay scope"
    Write-Host "  3. rerun verify or audit after the change"
    Write-Host ""
}

function Invoke-VerifyScope {
    param(
        [Parameter(Mandatory)]
        [string] $VerifyScope
    )

    switch ($VerifyScope) {
        "all"      { Invoke-AuditAggregate -AuditAction "all" }
        "security" { Invoke-RepoScript "scripts/verify/security/29-security-visibility.verify.ps1" }
        "software" { Invoke-RepoScript "scripts/verify/software/39-software-inventory.verify.ps1" }
        "identity" { Invoke-RepoScript "scripts/verify/identity/46-identity-local-visibility.verify.ps1" }
        "host"     { Invoke-RepoScript "scripts/verify/host/55-host-identity-visibility.verify.ps1" }
        "system"   { Invoke-RepoScript "scripts/verify/system/90-system-state.verify.ps1" }
        "recovery" { Invoke-RepoScript "scripts/verify/recovery/60-recovery-visibility.verify.ps1" }
        default {
            Write-MakeFail "Unknown verify scope: $VerifyScope"
            exit 1
        }
    }
}

function Invoke-AuditExport {
    $verifyScopes = @(
        @{ Name = "security"; Path = "scripts/verify/security/29-security-visibility.verify.ps1" },
        @{ Name = "software"; Path = "scripts/verify/software/39-software-inventory.verify.ps1" },
        @{ Name = "identity"; Path = "scripts/verify/identity/46-identity-local-visibility.verify.ps1" },
        @{ Name = "host"; Path = "scripts/verify/host/55-host-identity-visibility.verify.ps1" },
        @{ Name = "system"; Path = "scripts/verify/system/90-system-state.verify.ps1" },
        @{ Name = "recovery"; Path = "scripts/verify/recovery/60-recovery-visibility.verify.ps1" }
    )

    $results = [System.Collections.Generic.List[object]]::new()

    foreach ($verifyScope in $verifyScopes) {
        $path = Resolve-RepoPath -RelativePath $verifyScope.Path

        if (-not (Test-Path -LiteralPath $path)) {
            Write-MakeFail "Script not found: $($verifyScope.Path)"
            exit 1
        }

        $jsonOutput = & $path -OutputFormat Json
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            exit $exitCode
        }

        try {
            $parsed = $jsonOutput | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-MakeFail "Unable to parse JSON output from $($verifyScope.Path)"
            exit 1
        }

        $results.Add([pscustomobject]@{
            scope = $verifyScope.Name
            data  = $parsed
        }) | Out-Null
    }

    [pscustomobject]@{
        scope        = "audit-export"
        generatedAt  = (Get-Date).ToString("s")
        computerName = $env:COMPUTERNAME
        results      = @($results)
    } | ConvertTo-Json -Depth 8
}

function Show-AuditSummary {
    $export = Invoke-AuditExport | ConvertFrom-Json -ErrorAction Stop
    $scopeSummaries = @()
    $totalWarnings = 0

    foreach ($result in $export.results) {
        $warningCount = @($result.data.warnings).Count
        $totalWarnings += $warningCount

        $scopeSummaries += [pscustomobject]@{
            scope        = $result.scope
            warningCount = $warningCount
        }
    }

    Write-MakeHeader "Operator Summary Report"
    Write-MakeInfo ("Generated at: {0}" -f $export.generatedAt)
    Write-MakeInfo ("Computer name: {0}" -f $export.computerName)
    Write-Host ""

    foreach ($summary in $scopeSummaries) {
        if ($summary.warningCount -gt 0) {
            Write-MakeWarn ("{0}: {1} warning(s)" -f $summary.scope, $summary.warningCount)
        }
        else {
            Write-MakeInfo ("{0}: no warnings" -f $summary.scope)
        }
    }

    Write-Host ""
    if ($totalWarnings -gt 0) {
        Write-MakeWarn ("Total warnings: {0}" -f $totalWarnings)
        Write-MakeInfo "Recommended next step: run '.\boring-admin.ps1 audit all' in an elevated shell and review the affected scopes."
    }
    else {
        Write-MakeInfo "Total warnings: 0"
        Write-MakeInfo "Recommended next step: archive the result with '.\boring-admin.ps1 audit save' if you need a human-readable record."
    }
}

function Save-AuditTextSnapshot {
    $verifyScripts = @(
        "scripts/verify/security/29-security-visibility.verify.ps1",
        "scripts/verify/software/39-software-inventory.verify.ps1",
        "scripts/verify/identity/46-identity-local-visibility.verify.ps1",
        "scripts/verify/host/55-host-identity-visibility.verify.ps1",
        "scripts/verify/system/90-system-state.verify.ps1",
        "scripts/verify/recovery/60-recovery-visibility.verify.ps1"
    )

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $outputDirectory = Get-AuditOutputDirectory
    $outputPath = Join-Path $outputDirectory ("audit-{0}.txt" -f $timestamp)
    $buffer = [System.Text.StringBuilder]::new()

    [void]$buffer.AppendLine("boring-admin-windows :: audit save")
    [void]$buffer.AppendLine(("GeneratedAt: {0}" -f (Get-Date).ToString("s")))
    [void]$buffer.AppendLine(("ComputerName: {0}" -f $env:COMPUTERNAME))
    [void]$buffer.AppendLine("")

    foreach ($relativePath in $verifyScripts) {
        $path = Resolve-RepoPath -RelativePath $relativePath

        if (-not (Test-Path -LiteralPath $path)) {
            Write-MakeFail "Script not found: $relativePath"
            exit 1
        }

        [void]$buffer.AppendLine(("[AUDIT] {0}" -f $relativePath))
        [void]$buffer.AppendLine(("=" * 72))

        $captured = (& $path *>&1 | Out-String)
        $exitCode = $LASTEXITCODE
        [void]$buffer.AppendLine($captured.TrimEnd())
        [void]$buffer.AppendLine("")

        if ($exitCode -ne 0) {
            exit $exitCode
        }
    }

    [System.IO.File]::WriteAllText($outputPath, $buffer.ToString(), [System.Text.Encoding]::UTF8)
    Write-MakeInfo ("Saved human-readable audit snapshot: {0}" -f $outputPath)
}

function Invoke-AuditAggregate {
    param(
        [Parameter(Mandatory)]
        [string] $AuditAction
    )

    switch ($AuditAction) {
        "all" {
            $verifyScripts = @(
                "scripts/verify/security/29-security-visibility.verify.ps1",
                "scripts/verify/software/39-software-inventory.verify.ps1",
                "scripts/verify/identity/46-identity-local-visibility.verify.ps1",
                "scripts/verify/host/55-host-identity-visibility.verify.ps1",
                "scripts/verify/system/90-system-state.verify.ps1",
                "scripts/verify/recovery/60-recovery-visibility.verify.ps1"
            )

            foreach ($relativePath in $verifyScripts) {
                $path = Resolve-RepoPath -RelativePath $relativePath

                if (-not (Test-Path -LiteralPath $path)) {
                    Write-MakeFail "Script not found: $relativePath"
                    exit 1
                }

                Write-Host ""
                Write-Host ("[AUDIT] {0}" -f $relativePath) -ForegroundColor DarkGray
                & $path

                if ($LASTEXITCODE -ne 0) {
                    exit $LASTEXITCODE
                }
            }

            exit 0
        }
        "recovery" {
            Invoke-VerifyScope -VerifyScope "recovery"
        }
        "export" {
            Invoke-AuditExport
            return
        }
        "save" {
            Save-AuditTextSnapshot
            return
        }
        "summary" {
            Show-AuditSummary
            return
        }
        "help" {
            Show-AuditHelp
            return
        }
        default {
            Write-MakeFail "Unknown audit action: $AuditAction"
            exit 1
        }
    }
}

function Invoke-ApplyScope {
    param(
        [Parameter(Mandatory)]
        [string] $ApplyScope
    )

    switch ($ApplyScope) {
        "security" { Invoke-RepoScript "scripts/apply/security/20-security-orchestrator.manual.ps1" }
        "identity" { Invoke-RepoScript "scripts/apply/identity/40-identity-local-orchestrator.manual.ps1" }
        "host"     { Invoke-RepoScript "scripts/apply/host/50-host-identity-orchestrator.manual.ps1" }
        default {
            Write-MakeFail "Unknown apply scope: $ApplyScope"
            exit 1
        }
    }
}

function Invoke-OverlayScope {
    param(
        [Parameter(Mandatory)]
        [string] $OverlayScope
    )

    switch ($OverlayScope) {
        "software" { Invoke-RepoScript "scripts/overlay/software/30-software-orchestrator.manual.ps1" }
        "ux"       { Invoke-RepoScript "scripts/overlay/ux/25-system-explorer-ux.manual.ps1" }
        default {
            Write-MakeFail "Unknown overlay scope: $OverlayScope"
            exit 1
        }
    }
}


# -----------------------------------------------------------------------------
# Dispatch
# -----------------------------------------------------------------------------

if (-not $Layer) {
    Show-PrimaryHelp
    return
}

switch ($Layer) {
    "help" {
        if ($Scope -eq "audit") {
            Show-AuditHelp
            return
        }

        if ($Scope -eq "operational") {
            Show-OperationalHelp
            return
        }

        Show-PrimaryHelp
        return
    }

    "info" {
        Show-Info
        return
    }

    "setup" {
        Show-SetupPath
        return
    }

    "check-env" {
        Invoke-CheckEnv
        return
    }

    "audit" {
        if (-not $Scope -or $Scope -eq "help") {
            Show-AuditHelp
            return
        }

        Invoke-AuditAggregate -AuditAction $Scope
    }

    "verify" {
        if (-not $Scope) {
            Show-AuditHelp
            return
        }

        Invoke-VerifyScope -VerifyScope $Scope
    }

    "apply" {
        if (-not $Scope) {
            Show-OperationalHelp
            return
        }

        Invoke-ApplyScope -ApplyScope $Scope
    }

    "overlay" {
        if (-not $Scope) {
            Show-OperationalHelp
            return
        }

        Invoke-OverlayScope -OverlayScope $Scope
    }

    "operational" {
        Show-OperationalHelp
        return
    }

    default {
        Write-MakeFail "Unknown layer: $Layer"
        Show-PrimaryHelp
        exit 1
    }
}
