<#
.SYNOPSIS
Public PowerShell entrypoint for the current boring-admin-windows surface.

.DESCRIPTION
Exposes the current public CLI contract and explicit compatibility
entrypoints for the active `v002` repository surface.

.PARAMETER CliArgs
Passes the public `help`, `version`, `check`, `plan`, and `apply` arguments
through the repository boundary parser.

.EXAMPLE
.\boring-admin.ps1 check

Runs the read-only aggregated workstation check.

.EXAMPLE
.\boring-admin.ps1 plan host --profile .\config\profiles\individual.local.json

Builds a read-only host plan against the explicit local profile.

.EXAMPLE
.\boring-admin.ps1 apply software --profile .\config\profiles\individual.local.json --change-id INC-1234

Runs the public write-capable software apply path with an explicit change
record.

.NOTES
Write-capable public operations require `--change-id`.
Use `--json` only on the supported read-only surfaces.
Public exit codes are summarized in docs/COMMANDS.md.
#>

<#
===============================================================================
boring-admin-windows :: boring-admin.ps1

PURPOSE
-------
Provide a Windows-native, PowerShell-first operational entrypoint for the
repository without requiring GNU Make.

This script mirrors the intent of:
- Makefile              -> safe discovery

This script EXISTS TO:
- expose the current public CLI contract in one Windows-native CLI
- keep read-only and write-capable boundaries explicit
- preserve migration visibility as the public contract narrows

This script DOES NOT:
- redefine repository architecture
- hide write-capable transitions
- pretend compatibility entrypoints are the preferred long-term public surface
===============================================================================
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $CliArgs = @()
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$RepositoryRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $RepositoryRoot "core\lib\common.ps1")
. (Join-Path $RepositoryRoot "core\lib\config.ps1")
. (Join-Path $RepositoryRoot "core\lib\software-inventory.ps1")

$BoringAdminSurfaceVersion = "v002"
$BoringAdminContractVersion = "sprint7"
$script:RunId = Get-BoringAdminRunId
$script:ApplyAuditLogPath = $null
$script:CliOptions = [pscustomobject]@{
    Json      = $false
    Quiet     = $false
    Verbose   = $false
    DryRun    = $false
    Help      = $false
    Version   = $false
    Summary   = $false
    Save      = $false
    Profile   = $null
    ChangeId  = $null
}
$script:EntryPointCmdlet = $PSCmdlet

$script:PublicExitCodes = @{
    Success      = 0
    Input        = 2
    Config       = 3
    Environment  = 4
    Permission   = 5
    Runtime      = 6
    CheckFailed  = 8
    PlanChanges  = 10
    Partial      = 11
    Unsupported  = 12
}

function Write-MakeHeader {
    param(
        [Parameter(Mandatory)]
        [string] $Title
    )

    if ($script:CliOptions.Quiet) {
        return
    }

    Write-Host ""
    Write-BoringAdminHost $Title -ForegroundColor Cyan
    Write-BoringAdminHost ("-" * $Title.Length) -ForegroundColor DarkGray
    Write-Host ""
}

function Write-MakeInfo {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    if ($script:CliOptions.Quiet) {
        return
    }

    Write-Host "[INFO] $Message"
}

function Write-MakeWarn {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-BoringAdminHost "[WARN] $Message" -ForegroundColor Yellow
}

function Write-MakeFail {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-BoringAdminHost "[FAIL] $Message" -ForegroundColor Red
}

function Write-MakeCommand {
    param(
        [Parameter(Mandatory)]
        [string] $Command,

        [string] $Description
    )

    if ($Description) {
        Write-BoringAdminHost ("  {0,-42} {1}" -f $Command, $Description)
        return
    }

    Write-BoringAdminHost "  $Command"
}

function Get-DefaultNextAction {
    param(
        [Parameter(Mandatory)]
        [string] $ErrorId
    )

    switch -Regex ($ErrorId) {
        '^config\.invalid_profile$' { return "Run check config --profile <path>." }
        '^apply\.change_id_required$' { return "Repeat apply with --change-id <approved-reference>." }
        '^apply\.administrator_required$' { return "Open an elevated PowerShell session and retry." }
        '^apply\.security\.unsupported$' { return "Use the documented read-only check target instead." }
        '^check\.(scope_failed|target_failed)$' { return "Review the target output and resolve the named prerequisite before apply." }
        '^plan\.target_required$' { return "Repeat the command with an explicit plan target." }
        '^plan\.unknown_target$' { return "Run .\boring-admin.ps1 help and choose a documented plan target." }
        '^check\.unknown_target$' { return "Run .\boring-admin.ps1 help and choose a documented check target." }
        '^apply\.unknown_target$' { return "Run .\boring-admin.ps1 help and choose a documented apply target." }
        '^top_level\.unknown_command$' { return "Run .\boring-admin.ps1 help to see the supported public commands." }
        '^cli\.invalid_argument$' { return "Review the command syntax with .\boring-admin.ps1 help and retry." }
        '^apply\.result_(missing|invalid_json)$' { return "Inspect the child script output and rerun the change only after the apply-result path is fixed." }
        '^apply\.record_write_failed$' { return "Inspect the apply audit JSONL and fix workstation-record write access before retrying." }
        '^apply\.child_failed$' { return "Inspect the child script output and workstation record before retrying the change." }
        '^apply\.reboot_pending$' { return "Reboot the workstation, run .\boring-admin.ps1 check, and retry only after reboot markers are cleared." }
        '^apply\.confirmation_declined$' { return "Review the plan and repeat apply only after approval is available." }
        default { return "Review the error details and rerun only after the named problem is resolved." }
    }
}

function Resolve-RepoPath {
    param(
        [Parameter(Mandatory)]
        [string] $RelativePath
    )

    return Join-Path $RepositoryRoot $RelativePath
}

function Get-CheckOutputDirectory {
    return Get-BoringAdminCheckRecordDirectory
}

function Get-CheckFixtureDirectory {
    if ([string]::IsNullOrWhiteSpace($env:BORING_ADMIN_VERIFY_FIXTURE_DIR)) {
        return $null
    }

    return [System.IO.Path]::GetFullPath($env:BORING_ADMIN_VERIFY_FIXTURE_DIR)
}

function Get-CheckFixtureResult {
    param(
        [Parameter(Mandatory)]
        [string] $Scope
    )

    $fixtureDirectory = Get-CheckFixtureDirectory
    if (-not $fixtureDirectory) {
        return $null
    }

    $fixturePath = Join-Path $fixtureDirectory ("{0}.json" -f $Scope)
    if (-not (Test-Path -LiteralPath $fixturePath -PathType Leaf)) {
        Exit-BoringAdminFailure `
            -Message "Check fixture not found: $fixturePath" `
            -ErrorId "check.fixture_missing" `
            -ExitCode $script:PublicExitCodes.Runtime `
            -Scope "check-error"
    }

    try {
        return Get-Content -Raw -LiteralPath $fixturePath | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Exit-BoringAdminFailure `
            -Message "Unable to parse check fixture: $fixturePath" `
            -ErrorId "check.fixture_invalid_json" `
            -ExitCode $script:PublicExitCodes.Runtime `
            -Scope "check-error"
    }
}

function Get-PlanFixtureResult {
    param(
        [Parameter(Mandatory)]
        [string] $Scope
    )

    return Get-CheckFixtureResult -Scope $Scope
}

function Get-ApplyAuditDirectory {
    return Get-BoringAdminApplyAuditDirectory
}

function Convert-ToSafeFileComponent {
    param(
        [Parameter(Mandatory)]
        [string] $Value
    )

    $invalidPattern = ('[{0}]' -f [regex]::Escape(([string]::Join('', [System.IO.Path]::GetInvalidFileNameChars()))))
    return ([regex]::Replace($Value, $invalidPattern, '-')).Trim()
}

function Get-ApplyResultDirectory {
    $directory = Join-Path (Get-BoringAdminRecordRoot) "apply-results"
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    return $directory
}

function Get-ApplyResultPath {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    return Join-Path (Get-ApplyResultDirectory) ("apply-result-{0}-{1}.json" -f $timestamp, $script:RunId)
}

function Get-WorkstationRecordPath {
    param(
        [Parameter(Mandatory)]
        [string] $Target,

        [Parameter(Mandatory)]
        [string] $ChangeId
    )

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $safeTarget = Convert-ToSafeFileComponent -Value $Target
    $safeChangeId = Convert-ToSafeFileComponent -Value $ChangeId
    return Join-Path (Get-BoringAdminRecordRoot) ("{0}-{1}-{2}.json" -f $timestamp, $safeTarget, $safeChangeId)
}

function Get-RepositoryGitContext {
    $gitCommand = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCommand) {
        return [pscustomobject]@{
            branch = $null
            commit = $null
        }
    }

    $branch = (& $gitCommand.Source -C $RepositoryRoot branch --show-current 2>$null | Out-String).Trim()
    $commit = (& $gitCommand.Source -C $RepositoryRoot rev-parse HEAD 2>$null | Out-String).Trim()

    return [pscustomobject]@{
        branch = if ($branch) { $branch } else { $null }
        commit = if ($commit) { $commit } else { $null }
    }
}

function Invoke-WithTemporaryEnvironment {
    param(
        [hashtable] $Variables = @{},

        [scriptblock] $ScriptBlock
    )

    $originalValues = @{}

    try {
        foreach ($key in $Variables.Keys) {
            $originalValues[$key] = [System.Environment]::GetEnvironmentVariable($key, "Process")
            [System.Environment]::SetEnvironmentVariable($key, [string]$Variables[$key], "Process")
        }

        return & $ScriptBlock
    }
    finally {
        foreach ($key in $Variables.Keys) {
            [System.Environment]::SetEnvironmentVariable($key, $originalValues[$key], "Process")
        }
    }
}

function Get-CurrentEventId {
    return Get-BoringAdminEventId
}

function Get-StructuredSuccessRecord {
    param(
        [Parameter(Mandatory)]
        [string] $Command,

        [string] $Target,

        [int] $ExitCode = 0,

        [string] $Message = "Completed successfully.",

        [string] $ChangeId,

        [hashtable] $Data,

        [ValidateSet("info", "warn", "error")]
        [string] $Severity = "info"
    )

    $record = [ordered]@{
        command     = $Command
        target      = $Target
        generatedAt = Get-Rfc3339Timestamp
        run_id      = $script:RunId
        event_id    = Get-CurrentEventId
        severity    = $Severity
        exit_code   = $ExitCode
        message     = $Message
    }

    if ($ChangeId) {
        $record.change_id = $ChangeId
    }

    if ($Data) {
        $record.data = [pscustomobject]$Data
    }

    return [pscustomobject]$record
}

function Exit-BoringAdminFailure {
    param(
        [Parameter(Mandatory)]
        [string] $Message,

        [Parameter(Mandatory)]
        [string] $ErrorId,

        [Parameter(Mandatory)]
        [int] $ExitCode,

        [string] $Scope = "boring-admin-error",

        [string] $ChangeId,

        [string] $NextAction
    )

    if (-not $NextAction) {
        $NextAction = Get-DefaultNextAction -ErrorId $ErrorId
    }

    if ($script:CliOptions.Json) {
        Get-StructuredErrorRecord `
            -ErrorId $ErrorId `
            -Message $Message `
            -ExitCode $ExitCode `
            -Scope $Scope `
            -RunId $script:RunId `
            -EventId (Get-CurrentEventId) `
            -ChangeId $ChangeId `
            -NextAction $NextAction |
            ConvertTo-Json -Depth 6
    }
    else {
        Write-MakeFail $Message
        Write-MakeInfo ("run_id: {0}" -f $script:RunId)
        if ($ChangeId) {
            Write-MakeInfo ("change_id: {0}" -f $ChangeId)
        }
        Write-MakeInfo ("error_id: {0}" -f $ErrorId)
        Write-MakeInfo ("exit_code: {0}" -f $ExitCode)
        if ($NextAction) {
            Write-MakeInfo ("next_action: {0}" -f $NextAction)
        }
    }

    exit $ExitCode
}

function Write-LegacyAliasNotice {
    param(
        [Parameter(Mandatory)]
        [string] $LegacyCommand,

        [Parameter(Mandatory)]
        [string] $PublicCommand
    )

    if ($script:CliOptions.Json) {
        return
    }

    Write-MakeWarn ("Legacy alias '{0}' is kept for compatibility. Prefer '{1}'." -f $LegacyCommand, $PublicCommand)
}

function Get-PreferredPowerShellExe {
    $currentProcessPath = (Get-Process -Id $PID).Path
    if ($currentProcessPath) {
        return $currentProcessPath
    }

    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) {
        return $pwsh.Source
    }

    return "powershell.exe"
}

function Invoke-WithProfileContext {
    param(
        [string] $ProfilePath,

        [hashtable] $AdditionalEnvironment = @{},

        [scriptblock] $ScriptBlock
    )

    $variables = @{}
    if ($ProfilePath) {
        $variables["BORING_ADMIN_PROFILE"] = $ProfilePath
    }

    foreach ($key in $AdditionalEnvironment.Keys) {
        $variables[$key] = $AdditionalEnvironment[$key]
    }

    return Invoke-WithTemporaryEnvironment -Variables $variables -ScriptBlock $ScriptBlock
}

function Invoke-RepoScriptProcess {
    param(
        [Parameter(Mandatory)]
        [string] $RelativePath,

        [string[]] $ArgumentList = @(),

        [string] $ProfilePath,

        [hashtable] $AdditionalEnvironment = @{}
    )

    $path = Resolve-RepoPath -RelativePath $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Exit-BoringAdminFailure `
            -Message "Script not found: $RelativePath" `
            -ErrorId "top_level.script_not_found" `
            -ExitCode $script:PublicExitCodes.Runtime
    }

    $psExe = Get-PreferredPowerShellExe
    $commandArgs = @("-NoProfile", "-File", $path) + $ArgumentList

    Invoke-WithProfileContext -ProfilePath $ProfilePath -AdditionalEnvironment $AdditionalEnvironment -ScriptBlock {
        & $psExe @commandArgs
    } | Out-Null

    return $LASTEXITCODE
}

function Invoke-RepoScriptProcessCapture {
    param(
        [Parameter(Mandatory)]
        [string] $RelativePath,

        [string[]] $ArgumentList = @(),

        [string] $ProfilePath,

        [hashtable] $AdditionalEnvironment = @{}
    )

    $path = Resolve-RepoPath -RelativePath $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Exit-BoringAdminFailure `
            -Message "Script not found: $RelativePath" `
            -ErrorId "top_level.script_not_found" `
            -ExitCode $script:PublicExitCodes.Runtime
    }

    $psExe = Get-PreferredPowerShellExe
    $commandArgs = @("-NoProfile", "-File", $path) + $ArgumentList

    $output = Invoke-WithProfileContext -ProfilePath $ProfilePath -AdditionalEnvironment $AdditionalEnvironment -ScriptBlock {
        & $psExe @commandArgs 2>&1 | Out-String
    }

    return [pscustomobject]@{
        Output   = $output
        ExitCode = $LASTEXITCODE
    }
}

function Get-CheckExportObject {
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
        $parsed = Get-CheckFixtureResult -Scope $verifyScope.Name

        if (-not $parsed) {
            $capture = Invoke-RepoScriptProcessCapture `
                -RelativePath $verifyScope.Path `
                -ArgumentList @("-OutputFormat", "Json") `
                -ProfilePath $script:CliOptions.Profile

            if ($capture.ExitCode -ne 0) {
                Exit-BoringAdminFailure `
                    -Message "Check failed while collecting JSON for scope '$($verifyScope.Name)'." `
                    -ErrorId "check.scope_failed" `
                    -ExitCode $script:PublicExitCodes.CheckFailed `
                    -Scope "check-error"
            }

            try {
                $parsed = $capture.Output | ConvertFrom-Json -ErrorAction Stop
            }
            catch {
                Exit-BoringAdminFailure `
                    -Message "Unable to parse JSON output for scope '$($verifyScope.Name)'." `
                    -ErrorId "check.invalid_json" `
                    -ExitCode $script:PublicExitCodes.Runtime `
                    -Scope "check-error"
            }
        }

        $results.Add([pscustomobject]@{
            scope = $verifyScope.Name
            data  = $parsed
        }) | Out-Null
    }

    return [pscustomobject]@{
        scope        = "check-export"
        generatedAt  = Get-Rfc3339Timestamp
        computerName = $env:COMPUTERNAME
        results      = @($results)
    }
}

function Save-CheckTextSnapshot {
    $verifyScripts = @(
        "scripts/verify/security/29-security-visibility.verify.ps1",
        "scripts/verify/software/39-software-inventory.verify.ps1",
        "scripts/verify/identity/46-identity-local-visibility.verify.ps1",
        "scripts/verify/host/55-host-identity-visibility.verify.ps1",
        "scripts/verify/system/90-system-state.verify.ps1",
        "scripts/verify/recovery/60-recovery-visibility.verify.ps1"
    )

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $outputDirectory = Get-CheckOutputDirectory
    $outputPath = Join-Path $outputDirectory ("check-{0}.txt" -f $timestamp)
    $buffer = [System.Text.StringBuilder]::new()

    [void]$buffer.AppendLine("boring-admin-windows :: check")
    [void]$buffer.AppendLine(("GeneratedAt: {0}" -f (Get-Rfc3339Timestamp)))
    [void]$buffer.AppendLine(("RunId: {0}" -f $script:RunId))
    [void]$buffer.AppendLine(("ComputerName: {0}" -f $env:COMPUTERNAME))
    [void]$buffer.AppendLine("")

    foreach ($relativePath in $verifyScripts) {
        $capture = Invoke-RepoScriptProcessCapture -RelativePath $relativePath -ProfilePath $script:CliOptions.Profile
        if ($capture.ExitCode -ne 0) {
            Exit-BoringAdminFailure `
                -Message "Check snapshot failed while running '$relativePath'." `
                -ErrorId "check.snapshot_failed" `
                -ExitCode $script:PublicExitCodes.CheckFailed
        }

        [void]$buffer.AppendLine(("[CHECK] {0}" -f $relativePath))
        [void]$buffer.AppendLine(("=" * 72))
        [void]$buffer.AppendLine($capture.Output.TrimEnd())
        [void]$buffer.AppendLine("")
    }

    [System.IO.File]::WriteAllText($outputPath, $buffer.ToString(), [System.Text.Encoding]::UTF8)
    Write-MakeInfo ("Saved read-only check snapshot: {0}" -f $outputPath)
}

function Show-Version {
    if ($script:CliOptions.Json) {
        Get-StructuredSuccessRecord `
            -Command "version" `
            -ExitCode $script:PublicExitCodes.Success `
            -Message "Version surface." `
            -Data @{
                tool                 = "boring-admin-windows"
                architecture_surface = $BoringAdminSurfaceVersion
                public_contract      = $BoringAdminContractVersion
            } |
            ConvertTo-Json -Depth 6
        return
    }

    Write-Host ("boring-admin-windows {0}" -f $BoringAdminSurfaceVersion)
}

function Show-PublicHelp {
    if ($script:CliOptions.Json) {
        Get-StructuredSuccessRecord `
            -Command "help" `
            -ExitCode $script:PublicExitCodes.Success `
            -Message "Public CLI contract." `
            -Data @{
                usage = "boring-admin.ps1 <command> [target] [options]"
                commands = @(
                    @{ name = "help"; description = "Show help" }
                    @{ name = "version"; description = "Show version" }
                    @{ name = "check"; description = "Validate inputs, environment, and read-only state" }
                    @{ name = "plan"; description = "Show planned changes without modifying state" }
                    @{ name = "apply"; description = "Apply explicit changes" }
                )
                options = @("--help", "--version", "--json", "--quiet", "--verbose", "--dry-run", "--profile", "--change-id")
            } |
            ConvertTo-Json -Depth 6
        return
    }

    Write-MakeHeader "boring-admin-windows :: Public CLI"
    Write-Host "Usage:"
    Write-Host "  .\boring-admin.ps1 <command> [target] [options]"
    Write-Host ""
    Write-Host "Commands:"
    Write-MakeCommand ".\boring-admin.ps1 help" "Show help"
    Write-MakeCommand ".\boring-admin.ps1 version" "Show version"
    Write-MakeCommand ".\boring-admin.ps1 check [target]" "Validate inputs, environment, and read-only state"
    Write-MakeCommand ".\boring-admin.ps1 plan <target>" "Show planned changes"
    Write-MakeCommand ".\boring-admin.ps1 apply <target>" "Apply explicit changes"
    Write-Host ""
    Write-Host "Targets:"
    Write-Host "  check: all, security, software, identity, host, system, recovery, env, config"
    Write-Host "  plan : bootstrap, identity, host, software, ux, consumer-noise, security"
    Write-Host "  apply: bootstrap, identity, host, software, ux, consumer-noise, security"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  --help       Show help"
    Write-Host "  --version    Show version"
    Write-Host "  --json       Output machine-readable JSON where supported"
    Write-Host "  --quiet      Reduce non-essential terminal output"
    Write-Host "  --verbose    Show additional boundary metadata"
    Write-Host "  --dry-run    For apply, show the corresponding plan instead of changing state"
    Write-Host "  --profile    Explicit configuration profile path"
    Write-Host "  --change-id  Required external change reference for apply"
    Write-Host ""
    Write-Host "Notes:"
    Write-Host "  - help, version, check, and plan are read-only."
    Write-Host "  - apply is the only public write-capable verb."
    Write-Host "  - check --save remains non-mutating to workstation configuration but writes local evidence under %ProgramData%\BoringAdmin\records\checks."
    Write-Host "  - apply requires --change-id and follows the documented exit-code contract in docs/COMMANDS.md."
    Write-Host "  - compatibility entrypoints are intentionally omitted from this help surface."
    Write-Host "  - signing, SBOM, and provenance are not claimed as solved by this surface."
    Write-Host ""
}

function Show-LegacyInfo {
    Write-LegacyAliasNotice -LegacyCommand "info" -PublicCommand "help"
    Write-MakeHeader "Repository Overview"
    Write-Host "Entry surfaces:"
    Write-Host "  Makefile              -> safe discovery"
    Write-Host "  boring-admin.ps1      -> public boundary entrypoint"
    Write-Host ""
    Write-Host "Documentation anchors:"
    Write-Host "  README.md"
    Write-Host "  docs/GETTING-STARTED.md"
    Write-Host "  docs/COMMANDS.md"
    Write-Host "  docs/CONFIGURATION.md"
    Write-Host "  docs/ARCHITECTURE.md"
    Write-Host ""
    Write-MakeInfo ("Current public architecture surface: {0}" -f $BoringAdminSurfaceVersion)
}

function Show-LegacySetup {
    Write-LegacyAliasNotice -LegacyCommand "setup" -PublicCommand "plan"
    Write-MakeHeader "Legacy Setup Guidance"
    Write-Host "Use public read-only planning and checks first:"
    Write-Host "  .\boring-admin.ps1 check env"
    Write-Host "  .\boring-admin.ps1 check config --profile <path>"
    Write-Host "  .\boring-admin.ps1 plan bootstrap"
    Write-Host "  .\boring-admin.ps1 check security"
    Write-Host "  .\boring-admin.ps1 plan identity --profile <path>"
    Write-Host "  .\boring-admin.ps1 plan host --profile <path>"
    Write-Host "  .\boring-admin.ps1 apply bootstrap --change-id <id>"
    Write-Host "  .\boring-admin.ps1 check"
    Write-Host ""
    Write-Host "For the supported onboarding path, refer to docs/GETTING-STARTED.md"
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
}

function Test-ExplicitProfileRequired {
    param(
        [Parameter(Mandatory)]
        [string] $Target
    )

    return $Target -in @("identity", "host", "software")
}

function Resolve-ProfileForReadOnlyUse {
    if (-not $script:CliOptions.Profile) {
        return $null
    }

    try {
        $config = Import-BoringAdminConfig -ProfilePath $script:CliOptions.Profile
        return $config.resolvedProfilePath
    }
    catch {
        Exit-BoringAdminFailure `
            -Message $_.Exception.Message `
            -ErrorId "config.invalid_profile" `
            -ExitCode $script:PublicExitCodes.Config
    }
}

function Resolve-ProfileForWriteUse {
    param(
        [Parameter(Mandatory)]
        [string] $Target
    )

    if (-not (Test-ExplicitProfileRequired -Target $Target)) {
        return $null
    }

    if (-not $script:CliOptions.Profile) {
        Exit-BoringAdminFailure `
            -Message ("apply {0} requires an explicit --profile path." -f $Target) `
            -ErrorId "apply.profile_required" `
            -ExitCode $script:PublicExitCodes.Input `
            -ChangeId $script:CliOptions.ChangeId
    }

    try {
        $config = Import-BoringAdminConfig -ProfilePath $script:CliOptions.Profile
        Assert-BoringAdminWritableProfile -Config $config -Operation ("apply {0}" -f $Target)
        return $config.resolvedProfilePath
    }
    catch {
        Exit-BoringAdminFailure `
            -Message $_.Exception.Message `
            -ErrorId "config.invalid_profile" `
            -ExitCode $script:PublicExitCodes.Config `
            -ChangeId $script:CliOptions.ChangeId
    }
}

function Get-PlanSpec {
    param(
        [Parameter(Mandatory)]
        [string] $Target
    )

    switch ($Target) {
        "bootstrap" {
            return [pscustomobject]@{
                target                    = "bootstrap"
                classification            = "baseline"
                write_capable             = $true
                requires_profile          = $false
                requires_admin            = $true
                requires_confirm          = $true
                requires_boundary_confirm = $true
                legacy_surface            = "scripts/migrate/10-bootstrap-orchestrator.ps1"
                script_path               = "scripts/migrate/10-bootstrap-orchestrator.ps1"
                summary                   = "Apply the bounded workstation bootstrap sequence through the public boundary."
            }
        }
        "identity" {
            return [pscustomobject]@{
                target                    = "identity"
                classification            = "baseline"
                write_capable             = $true
                requires_profile          = $true
                requires_admin            = $true
                requires_confirm          = $true
                requires_boundary_confirm = $false
                legacy_surface            = "apply identity"
                script_path               = "scripts/apply/identity/41-identity-local-admin-model.manual.ps1"
                summary                   = "Enforce the configured local administrator model."
            }
        }
        "host" {
            return [pscustomobject]@{
                target                    = "host"
                classification            = "baseline"
                write_capable             = $true
                requires_profile          = $true
                requires_admin            = $true
                requires_confirm          = $true
                requires_boundary_confirm = $false
                legacy_surface            = "apply host"
                script_path               = "scripts/apply/host/51-host-identity-core.manual.ps1"
                summary                   = "Apply configured computer name, time zone, and system locale."
            }
        }
        "software" {
            return [pscustomobject]@{
                target                    = "software"
                classification            = "optional"
                write_capable             = $true
                requires_profile          = $true
                requires_admin            = $true
                requires_confirm          = $true
                requires_boundary_confirm = $false
                legacy_surface            = "overlay software"
                script_path               = "scripts/overlay/software/32-software-baseline.manual.ps1"
                summary                   = "Install the profile-defined software baseline through the active package manager."
            }
        }
        "ux" {
            return [pscustomobject]@{
                target                    = "ux"
                classification            = "optional"
                write_capable             = $true
                requires_profile          = $false
                requires_admin            = $true
                requires_confirm          = $true
                requires_boundary_confirm = $false
                legacy_surface            = "overlay ux"
                script_path               = "scripts/overlay/ux/25-system-explorer-ux.manual.ps1"
                summary                   = "Apply the optional UX baseline for human-factor safety."
            }
        }
        "consumer-noise" {
            return [pscustomobject]@{
                target                    = "consumer-noise"
                classification            = "optional"
                write_capable             = $true
                requires_profile          = $false
                requires_admin            = $true
                requires_confirm          = $true
                requires_boundary_confirm = $true
                legacy_surface            = "public apply consumer-noise"
                script_path               = "scripts/overlay/15-consumer-noise.manual.ps1"
                summary                   = "Apply the optional consumer-noise reduction overlay through the public boundary."
            }
        }
        "security" {
            return [pscustomobject]@{
                target                    = "security"
                classification            = "read-only"
                write_capable             = $false
                requires_profile          = $false
                requires_admin            = $false
                requires_confirm          = $false
                requires_boundary_confirm = $false
                legacy_surface            = "review security"
                script_path               = "scripts/apply/security/21-security-baseline.manual.ps1"
                summary                   = "Security remains a read-only review surface in v002. No write-capable security apply flow exists."
            }
        }
        default { return $null }
    }
}

function Get-PlanChangeRecord {
    param(
        [Parameter(Mandatory)]
        [string] $Id,

        [Parameter(Mandatory)]
        [string] $Kind,

        [Parameter(Mandatory)]
        [string] $Action,

        $Current,

        $Desired,

        [hashtable] $AdditionalData = @{}
    )

    $record = [ordered]@{
        id      = $Id
        kind    = $Kind
        action  = $Action
        current = $Current
        desired = $Desired
    }

    foreach ($key in $AdditionalData.Keys) {
        $record[$key] = $AdditionalData[$key]
    }

    return [pscustomobject]$record
}

function Get-RegistryValueOrNull {
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [string] $Name
    )

    try {
        return Get-ItemPropertyValue -LiteralPath $Path -Name $Name -ErrorAction Stop
    }
    catch {
        return $null
    }
}

function Get-PlanOutcomeExitCode {
    param(
        [Parameter(Mandatory)]
        [string] $PlanKind,

        [Parameter(Mandatory)]
        [int] $ChangeCount,

        [Parameter(Mandatory)]
        [string] $StateDetermination,

        [string[]] $BlockingConditions = @()
    )

    if ($PlanKind -eq "capability-preview") {
        return $script:PublicExitCodes.Success
    }

    if (@($BlockingConditions).Count -gt 0 -and $StateDetermination -ne "complete") {
        return $script:PublicExitCodes.Environment
    }

    if ($ChangeCount -gt 0) {
        return $script:PublicExitCodes.PlanChanges
    }

    return $script:PublicExitCodes.Success
}

function Get-PublicPlanOutcome {
    param(
        [Parameter(Mandatory)]
        [psobject] $Spec,

        [psobject] $Config
    )

    $fixtureDirectory = Get-CheckFixtureDirectory
    $changes = [System.Collections.Generic.List[object]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $blockingConditions = [System.Collections.Generic.List[string]]::new()
    $planKind = "state-diff"
    $stateDetermination = "complete"

    switch ($Spec.target) {
        "bootstrap" {
            $planKind = "capability-preview"
            $stateDetermination = "unavailable"
            $warnings.Add("Bootstrap plan is intentionally a capability preview in v002.") | Out-Null
            $warnings.Add("Review bootstrap preconditions with check env before apply.") | Out-Null
        }
        "security" {
            $planKind = "capability-preview"
            $stateDetermination = "unavailable"
            $warnings.Add("Security remains a read-only review surface in v002.") | Out-Null
            $warnings.Add("No write-capable security apply flow exists.") | Out-Null
        }
        "host" {
            $hostData = if ($fixtureDirectory) {
                (Get-PlanFixtureResult -Scope "host").host
            }
            else {
                $hostIdentity = Get-BoringAdminHostIdentitySettings -Config $Config
                $currentTimeZone = $null
                $currentSystemLocale = $null

                try {
                    $currentTimeZone = (Get-TimeZone).Id
                }
                catch {
                    $currentTimeZone = $null
                }

                try {
                    $currentSystemLocale = (Get-WinSystemLocale).Name
                }
                catch {
                    $currentSystemLocale = $null
                }

                [pscustomobject]@{
                    current = [pscustomobject]@{
                        computerName = $env:COMPUTERNAME
                        timeZone     = $currentTimeZone
                        systemLocale = $currentSystemLocale
                    }
                    desired = $hostIdentity
                    pendingRebootSignals = @(Get-BoringAdminPendingRebootSignals)
                }
            }

            if ($null -eq $hostData.current.timeZone -or $null -eq $hostData.current.systemLocale) {
                $stateDetermination = "partial"
                $blockingConditions.Add("Host state could not be read completely.") | Out-Null
            }

            if ($hostData.current.computerName -and $hostData.desired.computerName -and $hostData.current.computerName -ine $hostData.desired.computerName) {
                $changes.Add((Get-PlanChangeRecord -Id "host.computer_name" -Kind "setting" -Action "rename-computer" -Current $hostData.current.computerName -Desired $hostData.desired.computerName)) | Out-Null
            }

            if ($hostData.current.timeZone -and $hostData.desired.timeZone -and $hostData.current.timeZone -ne $hostData.desired.timeZone) {
                $changes.Add((Get-PlanChangeRecord -Id "host.time_zone" -Kind "setting" -Action "set-time-zone" -Current $hostData.current.timeZone -Desired $hostData.desired.timeZone)) | Out-Null
            }

            if ($hostData.current.systemLocale -and $hostData.desired.systemLocale -and $hostData.current.systemLocale -ne $hostData.desired.systemLocale) {
                $changes.Add((Get-PlanChangeRecord -Id "host.system_locale" -Kind "setting" -Action "set-system-locale" -Current $hostData.current.systemLocale -Desired $hostData.desired.systemLocale)) | Out-Null
            }

            if (@($hostData.pendingRebootSignals).Count -gt 0) {
                $blockingConditions.Add("Pending reboot markers are present.") | Out-Null
            }
        }
        "identity" {
            $identityData = if ($fixtureDirectory) {
                (Get-PlanFixtureResult -Scope "identity").identity
            }
            else {
                $identitySettings = Get-BoringAdminIdentitySettings -Config $Config
                $administratorsGroupName = Get-BoringAdminAdministratorsGroupName
                $administratorsGroup = @()

                try {
                    $administratorsGroup = @(
                        Get-LocalGroupMember -Group $administratorsGroupName -ErrorAction Stop |
                            ForEach-Object { [string]$_.Name }
                    )
                }
                catch {
                    $stateDetermination = "partial"
                    $blockingConditions.Add("Administrators group membership could not be enumerated.") | Out-Null
                }

                $managedAccounts = @(
                    [pscustomobject]@{ name = $identitySettings.primaryAdminName; expectedEnabled = $true },
                    [pscustomobject]@{ name = $identitySettings.recoveryAdminName; expectedEnabled = $false }
                )

                $managedStates = foreach ($account in $managedAccounts) {
                    try {
                        $user = Get-LocalUser -Name $account.name -ErrorAction Stop
                        [pscustomobject]@{
                            name            = $account.name
                            exists          = $true
                            enabled         = [bool]$user.Enabled
                            expectedEnabled = [bool]$account.expectedEnabled
                        }
                    }
                    catch {
                        [pscustomobject]@{
                            name            = $account.name
                            exists          = $false
                            enabled         = $null
                            expectedEnabled = [bool]$account.expectedEnabled
                        }
                    }
                }

                [pscustomobject]@{
                    administratorsGroupName = $administratorsGroupName
                    administratorsGroup     = @($administratorsGroup | ForEach-Object { [pscustomobject]@{ name = $_ } })
                    managedAccounts         = @($managedStates)
                }
            }

            $expectedAccounts = @(
                [pscustomobject]@{ name = $Config.accounts.primaryAdminName; expectedEnabled = $true },
                [pscustomobject]@{ name = $Config.accounts.recoveryAdminName; expectedEnabled = $false }
            )

            $administratorMembers = @($identityData.administratorsGroup | ForEach-Object { [string]$_.name })
            if ($administratorMembers.Count -eq 0) {
                $stateDetermination = "partial"
                $blockingConditions.Add("Administrators group membership is unavailable or empty.") | Out-Null
            }

            foreach ($account in $expectedAccounts) {
                $managedAccount = @($identityData.managedAccounts | Where-Object { $_.name -eq $account.name })[0]
                if (-not $managedAccount -or -not $managedAccount.exists) {
                    $changes.Add((Get-PlanChangeRecord -Id ("identity.{0}.exists" -f $account.name) -Kind "local-user" -Action "create-user" -Current "missing" -Desired "present")) | Out-Null
                }
                elseif ([bool]$managedAccount.enabled -ne [bool]$account.expectedEnabled) {
                    $changes.Add((Get-PlanChangeRecord -Id ("identity.{0}.enabled" -f $account.name) -Kind "local-user" -Action "set-enabled" -Current ([bool]$managedAccount.enabled) -Desired ([bool]$account.expectedEnabled))) | Out-Null
                }

                $isAdministrator = $administratorMembers | Where-Object { $_ -imatch ("(^|\\){0}$" -f [regex]::Escape($account.name)) }
                if (-not $isAdministrator) {
                    $changes.Add((Get-PlanChangeRecord -Id ("identity.{0}.administrators_membership" -f $account.name) -Kind "group-membership" -Action "add-to-administrators" -Current "absent" -Desired "present")) | Out-Null
                }
            }

            $unexpectedMembers = @(
                $administratorMembers | Where-Object {
                    $memberName = $_
                    -not ($expectedAccounts | Where-Object { $memberName -imatch ("(^|\\){0}$" -f [regex]::Escape($_.name)) })
                }
            )
            if ($unexpectedMembers.Count -gt 0) {
                $warnings.Add("Unexpected administrator members remain and require manual review.") | Out-Null
            }
        }
        "software" {
            $softwareData = if ($fixtureDirectory) {
                Get-PlanFixtureResult -Scope "software"
            }
            else {
                $packageManager = Get-BoringAdminSoftwarePackageManager -Config $Config
                $baselinePackages = @(Get-BoringAdminSoftwarePackageList -Config $Config -PackageClass baseline -PackageManager $packageManager)
                $packageResults = [System.Collections.Generic.List[object]]::new()
                $chocoCommand = Get-Command choco.exe -ErrorAction SilentlyContinue
                $wingetCommand = Get-Command winget.exe -ErrorAction SilentlyContinue

                foreach ($package in $baselinePackages) {
                    $queryResult = switch ($packageManager) {
                        "choco" {
                            if ($chocoCommand) { Get-BoringAdminChocolateyPackageState -PackageId $package.id -ExpectedVersion $package.version } else { [pscustomobject]@{ Success = $false; State = "unknown"; Version = $null; Error = "Chocolatey is not available in PATH."; Source = "choco" } }
                        }
                        "winget" {
                            if ($wingetCommand) { Get-BoringAdminWinGetPackageState -PackageId $package.id -ExpectedVersion $package.version } else { [pscustomobject]@{ Success = $false; State = "unknown"; Version = $null; Error = "WinGet is not available in PATH."; Source = "winget" } }
                        }
                    }

                    $packageResults.Add([pscustomobject]@{
                        id                = $package.id
                        expectedVersion   = $package.version
                        observedVersion   = $queryResult.Version
                        required          = [bool]$package.required
                        source            = $package.source
                        reviewedPublisher = $package.reviewedPublisher
                        status            = $queryResult.State
                        queryError        = $queryResult.Error
                    }) | Out-Null
                }

                [pscustomobject]@{
                    packageManager = [pscustomobject]@{
                        configured = $packageManager
                        chocolatey = [pscustomobject]@{ present = [bool]$chocoCommand }
                        winget     = [pscustomobject]@{ present = [bool]$wingetCommand }
                    }
                    inventory = [pscustomobject]@{
                        baselinePackages = @($packageResults)
                    }
                    warnings = @()
                }
            }

            $configuredManager = [string]$softwareData.packageManager.configured
            $activeManagerPresent = switch ($configuredManager) {
                "choco" { [bool]$softwareData.packageManager.chocolatey.present }
                "winget" { [bool]$softwareData.packageManager.winget.present }
                default { $false }
            }

            if (-not $activeManagerPresent) {
                $stateDetermination = "partial"
                $blockingConditions.Add(("Configured package manager '{0}' is not available in PATH." -f $configuredManager)) | Out-Null
            }

            foreach ($package in @($softwareData.inventory.baselinePackages)) {
                if ($package.PSObject.Properties["queryError"] -and $package.queryError) {
                    $stateDetermination = "partial"
                    $blockingConditions.Add(("Package '{0}' could not be verified: {1}" -f $package.id, $package.queryError)) | Out-Null
                    continue
                }

                if ($package.status -eq "unknown") {
                    $stateDetermination = "partial"
                    $blockingConditions.Add(("Package '{0}' could not be verified." -f $package.id)) | Out-Null
                    continue
                }

                if ($package.status -eq "present") {
                    continue
                }

                $changes.Add((Get-PlanChangeRecord -Id ("software.{0}" -f $package.id) -Kind "package" -Action "install-or-update" -Current $(if ($package.observedVersion) { $package.observedVersion } else { "missing" }) -Desired $package.expectedVersion -AdditionalData @{
                    required       = [bool]$package.required
                    package_manager = $configuredManager
                    source         = $package.source
                })) | Out-Null
            }
        }
        "ux" {
            $uxData = if ($fixtureDirectory) {
                Get-PlanFixtureResult -Scope "ux"
            }
            else {
                [pscustomobject]@{
                    scope    = "ux-plan"
                    registry = @(
                        [pscustomobject]@{ path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; name = "HideFileExt"; current = Get-RegistryValueOrNull -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt"; desired = 0 },
                        [pscustomobject]@{ path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; name = "Hidden"; current = Get-RegistryValueOrNull -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden"; desired = 1 },
                        [pscustomobject]@{ path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; name = "LaunchTo"; current = Get-RegistryValueOrNull -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo"; desired = 1 },
                        [pscustomobject]@{ path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; name = "FullPathAddress"; current = Get-RegistryValueOrNull -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "FullPathAddress"; desired = 1 },
                        [pscustomobject]@{ path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"; name = "DisallowShaking"; current = Get-RegistryValueOrNull -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DisallowShaking"; desired = 1 }
                    )
                    warnings = @()
                }
            }

            foreach ($entry in @($uxData.registry)) {
                if ($entry.current -ne $entry.desired) {
                    $changes.Add((Get-PlanChangeRecord -Id ("ux.{0}" -f $entry.name) -Kind "registry" -Action "set-registry-value" -Current $entry.current -Desired $entry.desired -AdditionalData @{
                        path       = $entry.path
                        value_name = $entry.name
                    })) | Out-Null
                }
            }
        }
        "consumer-noise" {
            $consumerData = if ($fixtureDirectory) {
                Get-PlanFixtureResult -Scope "consumer-noise"
            }
            else {
                if (-not (Test-IsAdministrator)) {
                    $stateDetermination = "partial"
                    $blockingConditions.Add("consumer-noise plan requires an elevated session to enumerate all-users AppX state.") | Out-Null
                    [pscustomobject]@{
                        appx     = @()
                        registry = @()
                        warnings = @("consumer-noise state assessment is intentionally blocked until the session is elevated.")
                    }
                }
                else {
                    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                    [pscustomobject]@{
                        appx = @(
                            "Microsoft.Clipchamp",
                            "MicrosoftTeams",
                            "Microsoft.XboxApp",
                            "Microsoft.XboxGamingOverlay",
                            "Microsoft.XboxGameOverlay",
                            "Microsoft.XboxSpeechToTextOverlay",
                            "Microsoft.Xbox.TCUI",
                            "Microsoft.BingNews",
                            "Microsoft.BingWeather",
                            "Microsoft.GetHelp",
                            "Microsoft.Getstarted",
                            "Microsoft.People",
                            "Microsoft.WindowsFeedbackHub"
                        ) | ForEach-Object {
                            [pscustomobject]@{
                                id           = $_
                                installed    = [bool](Get-AppxPackage -AllUsers -Name $_ -ErrorAction SilentlyContinue)
                                provisioned  = [bool](Get-AppxProvisionedPackage -Online | Where-Object DisplayName -EQ $_)
                            }
                        }
                        registry = @(
                            [pscustomobject]@{ path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; name = "DisableConsumerFeatures"; current = Get-RegistryValueOrNull -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableConsumerFeatures"; desired = 1 },
                            [pscustomobject]@{ path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; name = "DisableTailoredExperiencesWithDiagnosticData"; current = Get-RegistryValueOrNull -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableTailoredExperiencesWithDiagnosticData"; desired = 1 },
                            [pscustomobject]@{ path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; name = "SubscribedContent-338388Enabled"; current = Get-RegistryValueOrNull -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled"; desired = 0 },
                            [pscustomobject]@{ path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; name = "SubscribedContent-338389Enabled"; current = Get-RegistryValueOrNull -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled"; desired = 0 },
                            [pscustomobject]@{ path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; name = "SubscribedContent-338393Enabled"; current = Get-RegistryValueOrNull -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338393Enabled"; desired = 0 },
                            [pscustomobject]@{ path = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"; name = "AllowNewsAndInterests"; current = Get-RegistryValueOrNull -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests"; desired = 0 },
                            [pscustomobject]@{ path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat"; name = "ChatIcon"; current = Get-RegistryValueOrNull -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" -Name "ChatIcon"; desired = 3 },
                            [pscustomobject]@{ path = $registryPath; name = "HideFileExt"; current = Get-RegistryValueOrNull -Path $registryPath -Name "HideFileExt"; desired = 0 },
                            [pscustomobject]@{ path = $registryPath; name = "LaunchTo"; current = Get-RegistryValueOrNull -Path $registryPath -Name "LaunchTo"; desired = 1 }
                        )
                        warnings = @()
                    }
                }
            }

            foreach ($app in @($consumerData.appx)) {
                if ($app.installed) {
                    $changes.Add((Get-PlanChangeRecord -Id ("consumer-noise.appx.installed.{0}" -f $app.id) -Kind "appx-package" -Action "remove-installed-package" -Current "present" -Desired "absent")) | Out-Null
                }

                if ($app.provisioned) {
                    $changes.Add((Get-PlanChangeRecord -Id ("consumer-noise.appx.provisioned.{0}" -f $app.id) -Kind "appx-provisioned-package" -Action "remove-provisioned-package" -Current "present" -Desired "absent")) | Out-Null
                }
            }

            foreach ($entry in @($consumerData.registry)) {
                if ($entry.current -ne $entry.desired) {
                    $changes.Add((Get-PlanChangeRecord -Id ("consumer-noise.registry.{0}" -f $entry.name) -Kind "registry" -Action "set-registry-value" -Current $entry.current -Desired $entry.desired -AdditionalData @{
                        path       = $entry.path
                        value_name = $entry.name
                    })) | Out-Null
                }
            }
        }
    }

    $changeCount = $changes.Count
    $exitCode = Get-PlanOutcomeExitCode -PlanKind $planKind -ChangeCount $changeCount -StateDetermination $stateDetermination -BlockingConditions @($blockingConditions)
    $severity = if ($exitCode -eq $script:PublicExitCodes.Success) { "info" } else { "warn" }
    $message = if ($planKind -eq "capability-preview") {
        "Capability preview only."
    }
    elseif ($exitCode -eq $script:PublicExitCodes.Environment) {
        "Plan blocked by incomplete state determination."
    }
    elseif ($changeCount -gt 0) {
        "Plan found concrete changes."
    }
    else {
        "Plan found no changes."
    }

    return [pscustomobject]@{
        ExitCode           = $exitCode
        Severity           = $severity
        Message            = $message
        PlanKind           = $planKind
        ChangeCount        = $changeCount
        Changes            = @($changes)
        Warnings           = @($warnings)
        BlockingConditions = @($blockingConditions)
        StateDetermination = $stateDetermination
    }
}

function Write-ApplyAuditEvent {
    param(
        [Parameter(Mandatory)]
        [string] $Severity,

        [Parameter(Mandatory)]
        [string] $Message,

        [hashtable] $Data
    )

    if (-not $script:ApplyAuditLogPath) {
        return
    }

    $eventRecord = Get-StructuredEventRecord `
        -RunId $script:RunId `
        -Severity $Severity `
        -Message $Message `
        -Scope "apply-audit" `
        -Command "apply" `
        -Target $script:CurrentTarget `
        -ChangeId $script:CliOptions.ChangeId `
        -Data $Data

    Add-Content -LiteralPath $script:ApplyAuditLogPath -Value ($eventRecord | ConvertTo-Json -Compress -Depth 6) -Encoding utf8
}

function Try-Read-ApplyResultRecord {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return [pscustomobject]@{
            Success = $false
            Record  = $null
            ErrorId = "apply.result_missing"
            Message = "Apply result record was not created: $Path"
        }
    }

    try {
        return [pscustomobject]@{
            Success = $true
            Record  = (Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json -ErrorAction Stop)
            ErrorId = $null
            Message = $null
        }
    }
    catch {
        return [pscustomobject]@{
            Success = $false
            Record  = $null
            ErrorId = "apply.result_invalid_json"
            Message = "Unable to parse apply result record: $Path"
        }
    }
}

function Complete-BoringAdminPublicApply {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Target,

        [string] $ProfilePath,

        [Parameter(Mandatory)]
        [string] $ChangeId,

        [Parameter(Mandatory)]
        [int] $ChildExitCode,

        [Parameter(Mandatory)]
        [string] $ApplyResultPath,

        [Parameter(Mandatory)]
        [string] $AuditPath,

        [Parameter(Mandatory)]
        [string] $RunId
    )

    $previousRunId = $script:RunId
    $previousAuditPath = $script:ApplyAuditLogPath
    try {
        $script:RunId = $RunId
        $script:ApplyAuditLogPath = $AuditPath

        $applyResult = $null
        if ($ChildExitCode -ne 0) {
            $applyResult = Get-ApplyFailureResult `
                -Target $Target `
                -FailureStage "child-execution" `
                -ErrorId "apply.child_failed" `
                -Message ("Apply child script exited with code {0}." -f $ChildExitCode) `
                -NextAction (Get-DefaultNextAction -ErrorId "apply.child_failed") `
                -ChildExitCode $ChildExitCode
        }
        else {
            $readResult = Try-Read-ApplyResultRecord -Path $ApplyResultPath
            if (-not $readResult.Success) {
                $applyResult = Get-ApplyFailureResult `
                    -Target $Target `
                    -FailureStage "result-read" `
                    -ErrorId $readResult.ErrorId `
                    -Message $readResult.Message `
                    -NextAction (Get-DefaultNextAction -ErrorId $readResult.ErrorId)
            }
            else {
                $applyResult = $readResult.Record
            }
        }

        $publicExitCode = Get-PublicApplyExitCode -ApplyResult $applyResult

        try {
            $recordPath = Write-WorkstationRecord `
                -Target $Target `
                -ProfilePath $ProfilePath `
                -ChangeId $ChangeId `
                -ExitCode $publicExitCode `
                -ApplyResult $applyResult
        }
        catch {
            Write-ApplyAuditEvent -Severity "error" -Message "Workstation record write failed." -Data @{
                child_exit_code = $ChildExitCode
                failure_stage   = "record-write"
                error_id        = "apply.record_write_failed"
                message         = $_.Exception.Message
            }

            throw
        }

        $finalSeverity = if ([string]$applyResult.result -eq "failed") { "error" } else { "info" }
        $finalMessage = if ([string]$applyResult.result -eq "failed") { "Apply failed." } else { "Apply completed." }
        Write-ApplyAuditEvent -Severity $finalSeverity -Message $finalMessage -Data @{
            child_exit_code    = $ChildExitCode
            result             = $applyResult.result
            reboot_required    = $applyResult.reboot_required
            failure_stage      = if ($applyResult.PSObject.Properties["failure_stage"]) { $applyResult.failure_stage } else { $null }
            error_id           = if ($applyResult.PSObject.Properties["error_id"]) { $applyResult.error_id } else { $null }
            workstation_record = $recordPath
        }

        return [pscustomobject]@{
            ApplyResult     = $applyResult
            PublicExitCode  = $publicExitCode
            WorkstationPath = $recordPath
        }
    }
    finally {
        $script:RunId = $previousRunId
        $script:ApplyAuditLogPath = $previousAuditPath
    }
}

function Get-PublicApplyExitCode {
    param(
        [Parameter(Mandatory)]
        [psobject] $ApplyResult
    )

    switch ([string]$ApplyResult.result) {
        "completed" { return $script:PublicExitCodes.Success }
        "partial" { return $script:PublicExitCodes.Partial }
        "manual-verification-required" { return $script:PublicExitCodes.Partial }
        "failed" { return $script:PublicExitCodes.Runtime }
        default { return $script:PublicExitCodes.Runtime }
    }
}

function Get-ApplyFailureResult {
    param(
        [Parameter(Mandatory)]
        [string] $Target,

        [Parameter(Mandatory)]
        [string] $FailureStage,

        [Parameter(Mandatory)]
        [string] $ErrorId,

        [Parameter(Mandatory)]
        [string] $Message,

        [Parameter(Mandatory)]
        [string] $NextAction,

        [int] $ChildExitCode
    )

    $details = [ordered]@{}
    if ($PSBoundParameters.ContainsKey("ChildExitCode")) {
        $details.child_exit_code = [int]$ChildExitCode
    }

    return [pscustomobject]@{
        target                      = $Target
        result                      = "failed"
        reboot_required             = $false
        ready_for_next_step         = $false
        block_next_step_until_reboot = $false
        warnings                    = @()
        failed_items                = @()
        optional_failed_items       = @()
        child_exit_code             = if ($PSBoundParameters.ContainsKey("ChildExitCode")) { [int]$ChildExitCode } else { $null }
        failure_stage               = $FailureStage
        error_id                    = $ErrorId
        message                     = $Message
        next_action                 = $NextAction
        details                     = [pscustomobject]$details
    }
}

function Get-PublicCommandText {
    $parts = @(".\boring-admin.ps1", "apply", $script:CurrentTarget, "--change-id", $script:CliOptions.ChangeId)

    if ($script:CliOptions.Profile) {
        $parts += @("--profile", $script:CliOptions.Profile)
    }

    if ($script:CliOptions.DryRun) {
        $parts += "--dry-run"
    }

    return ($parts -join " ")
}

function Test-BoringAdminShouldProcess {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [string] $Target,

        [Parameter(Mandatory)]
        [string] $Action,

        [System.Management.Automation.PSCmdlet] $InvocationCmdlet
    )

    $activeCmdlet = if ($script:EntryPointCmdlet) {
        $script:EntryPointCmdlet
    }
    else {
        $InvocationCmdlet
    }

    if ($null -eq $activeCmdlet) {
        return (-not [bool]$WhatIfPreference)
    }

    try {
        return $activeCmdlet.ShouldProcess($Target, $Action)
    }
    catch [System.NullReferenceException] {
        return (-not [bool]$WhatIfPreference)
    }
}

function Get-PublicApplyPrecheck {
    param(
        [Parameter(Mandatory)]
        [psobject] $Spec
    )

    $pendingRebootSignals = @(Get-BoringAdminPendingRebootSignals)
    if ($pendingRebootSignals.Count -gt 0) {
        return [pscustomobject]@{
            Allowed    = $false
            ErrorId    = "apply.reboot_pending"
            ExitCode   = $script:PublicExitCodes.Environment
            Message    = ("Apply target '{0}' is blocked because pending reboot markers are already present." -f $Spec.target)
            NextAction = Get-DefaultNextAction -ErrorId "apply.reboot_pending"
            AuditData  = @{
                reason                 = "pending-reboot"
                pending_reboot_signals = @($pendingRebootSignals)
            }
        }
    }

    return [pscustomobject]@{
        Allowed    = $true
        ErrorId    = $null
        ExitCode   = $script:PublicExitCodes.Success
        Message    = $null
        NextAction = $null
        AuditData  = @{}
    }
}

function Write-WorkstationRecord {
    param(
        [Parameter(Mandatory)]
        [string] $Target,

        [string] $ProfilePath,

        [Parameter(Mandatory)]
        [string] $ChangeId,

        [Parameter(Mandatory)]
        [int] $ExitCode,

        [Parameter(Mandatory)]
        [psobject] $ApplyResult
    )

    $gitContext = Get-RepositoryGitContext
    $profileHash = if ($ProfilePath) { Get-FileSha256Hex -Path $ProfilePath } else { $null }
    $recordPath = Get-WorkstationRecordPath -Target $Target -ChangeId $ChangeId

    $record = [ordered]@{
        schema_version            = "1"
        generated_at              = Get-Rfc3339Timestamp
        run_id                    = $script:RunId
        change_id                 = $ChangeId
        command                   = Get-PublicCommandText
        target                    = $Target
        result                    = [string]$ApplyResult.result
        exit_code                 = $ExitCode
        reboot_required           = [bool]$ApplyResult.reboot_required
        ready_for_next_step       = if ($ApplyResult.PSObject.Properties["ready_for_next_step"]) { [bool]$ApplyResult.ready_for_next_step } else { $true }
        block_next_step_until_reboot = if ($ApplyResult.PSObject.Properties["block_next_step_until_reboot"]) { [bool]$ApplyResult.block_next_step_until_reboot } else { $false }
        profile_path              = $ProfilePath
        profile_sha256            = $profileHash
        repository_commit         = $gitContext.commit
        repository_branch         = $gitContext.branch
        warnings                  = @($ApplyResult.warnings)
        failed_items              = @($ApplyResult.failed_items)
        optional_failed_items     = if ($ApplyResult.PSObject.Properties["optional_failed_items"]) { @($ApplyResult.optional_failed_items) } else { @() }
    }

    if ($ApplyResult.PSObject.Properties["details"]) {
        $record.details = $ApplyResult.details
    }

    foreach ($propertyName in @("child_exit_code", "failure_stage", "error_id", "message", "next_action")) {
        if ($ApplyResult.PSObject.Properties[$propertyName]) {
            $record[$propertyName] = $ApplyResult.$propertyName
        }
    }

    Write-BoringAdminJsonAtomically -Path $recordPath -InputObject $record -Depth 12
    return $recordPath
}

function Require-PublicApplyConfirmation {
    param(
        [Parameter(Mandatory)]
        [psobject] $Spec
    )

    Write-Warn ("Public apply confirmation required for target '{0}'." -f $Spec.target)
    Write-Warn "Review the plan output before continuing."
    $confirmation = Read-Host "Type YES to continue from the public boundary"
    if ($confirmation -ne "YES") {
        Exit-BoringAdminFailure `
            -Message "Apply aborted at the public boundary." `
            -ErrorId "apply.confirmation_declined" `
            -ExitCode $script:PublicExitCodes.Input `
            -ChangeId $script:CliOptions.ChangeId
    }
}

function Show-UnsupportedSecurityApply {
    Exit-BoringAdminFailure `
        -Message "No write-capable security apply flow is implemented in v002." `
        -ErrorId "apply.security.unsupported" `
        -ExitCode $script:PublicExitCodes.Unsupported `
        -ChangeId $script:CliOptions.ChangeId
}

function Invoke-PublicCheck {
    param(
        [string] $Target = "all"
    )

    $resolvedProfile = Resolve-ProfileForReadOnlyUse

    switch ($Target) {
        "all" {
            if ($script:CliOptions.Json) {
                $export = Get-CheckExportObject
                Get-StructuredSuccessRecord `
                    -Command "check" `
                    -Target "all" `
                    -ExitCode $script:PublicExitCodes.Success `
                    -Message "Read-only check completed." `
                    -Data @{
                        result = $export
                    } |
                    ConvertTo-Json -Depth 10
                return
            }

            if ($script:CliOptions.Save) {
                Save-CheckTextSnapshot
                exit $script:PublicExitCodes.Success
            }

            if ($script:CliOptions.Summary) {
                $export = Get-CheckExportObject
                Write-MakeHeader "Check Summary"
                Write-MakeInfo ("Generated at: {0}" -f $export.generatedAt)
                Write-MakeInfo ("Computer name: {0}" -f $export.computerName)
                Write-Host ""

                foreach ($result in $export.results) {
                    $warningCount = @($result.data.warnings).Count
                    if ($warningCount -gt 0) {
                        Write-MakeWarn ("{0}: {1} warning(s)" -f $result.scope, $warningCount)
                    }
                    else {
                        Write-MakeInfo ("{0}: no warnings" -f $result.scope)
                    }
                }

                exit $script:PublicExitCodes.Success
            }

            $verifyScripts = @(
                "scripts/verify/security/29-security-visibility.verify.ps1",
                "scripts/verify/software/39-software-inventory.verify.ps1",
                "scripts/verify/identity/46-identity-local-visibility.verify.ps1",
                "scripts/verify/host/55-host-identity-visibility.verify.ps1",
                "scripts/verify/system/90-system-state.verify.ps1",
                "scripts/verify/recovery/60-recovery-visibility.verify.ps1"
            )

            foreach ($relativePath in $verifyScripts) {
                if (-not $script:CliOptions.Quiet) {
                    Write-Host ""
                    Write-Host ("[CHECK] {0}" -f $relativePath) -ForegroundColor DarkGray
                }

                $childExitCode = Invoke-RepoScriptProcess -RelativePath $relativePath -ProfilePath $resolvedProfile
                if ($childExitCode -ne 0) {
                    exit $script:PublicExitCodes.CheckFailed
                }
            }

            exit $script:PublicExitCodes.Success
        }
        "env" {
            if ($script:CliOptions.Json) {
                $makeCommand = Get-Command make -ErrorAction SilentlyContinue
                Get-StructuredSuccessRecord `
                    -Command "check" `
                    -Target "env" `
                    -ExitCode $script:PublicExitCodes.Success `
                    -Message "Environment check completed." `
                    -Data @{
                        powershell_version = [string]$PSVersionTable.PSVersion
                        make_available     = [bool]$makeCommand
                        make_path          = if ($makeCommand) { $makeCommand.Source } else { $null }
                    } |
                    ConvertTo-Json -Depth 6
                return
            }

            Invoke-CheckEnv
            exit $script:PublicExitCodes.Success
        }
        "config" {
            try {
                $config = Import-BoringAdminConfig -ProfilePath $script:CliOptions.Profile
            }
            catch {
                Exit-BoringAdminFailure `
                    -Message $_.Exception.Message `
                    -ErrorId "config.invalid_profile" `
                    -ExitCode $script:PublicExitCodes.Config
            }

            if ($script:CliOptions.Json) {
                Get-StructuredSuccessRecord `
                    -Command "check" `
                    -Target "config" `
                    -ExitCode $script:PublicExitCodes.Success `
                    -Message "Configuration is valid." `
                    -Data @{
                        profile_path = $config.resolvedProfilePath
                        profile_type = $config.profileType
                        profile_name = $config.profileName
                    } |
                    ConvertTo-Json -Depth 6
                return
            }

            Write-MakeInfo ("Configuration profile is valid: {0}" -f $config.resolvedProfilePath)
            Write-MakeInfo ("Profile type: {0}" -f $config.profileType)
            exit $script:PublicExitCodes.Success
        }
        default {
            $verifyMap = @{
                "security" = "scripts/verify/security/29-security-visibility.verify.ps1"
                "software" = "scripts/verify/software/39-software-inventory.verify.ps1"
                "identity" = "scripts/verify/identity/46-identity-local-visibility.verify.ps1"
                "host"     = "scripts/verify/host/55-host-identity-visibility.verify.ps1"
                "system"   = "scripts/verify/system/90-system-state.verify.ps1"
                "recovery" = "scripts/verify/recovery/60-recovery-visibility.verify.ps1"
            }

            if (-not $verifyMap.ContainsKey($Target)) {
                Exit-BoringAdminFailure `
                    -Message "Unknown check target: $Target" `
                    -ErrorId "check.unknown_target" `
                    -ExitCode $script:PublicExitCodes.Input
            }

            if ($script:CliOptions.Json) {
                $capture = Invoke-RepoScriptProcessCapture `
                    -RelativePath $verifyMap[$Target] `
                    -ArgumentList @("-OutputFormat", "Json") `
                    -ProfilePath $resolvedProfile

                if ($capture.ExitCode -ne 0) {
                    Exit-BoringAdminFailure `
                        -Message "Check failed for target '$Target'." `
                        -ErrorId "check.target_failed" `
                        -ExitCode $script:PublicExitCodes.CheckFailed
                }

                try {
                    $parsed = $capture.Output | ConvertFrom-Json -ErrorAction Stop
                }
                catch {
                    Exit-BoringAdminFailure `
                        -Message "Unable to parse JSON output for target '$Target'." `
                        -ErrorId "check.invalid_json" `
                        -ExitCode $script:PublicExitCodes.Runtime
                }

                Get-StructuredSuccessRecord `
                    -Command "check" `
                    -Target $Target `
                    -ExitCode $script:PublicExitCodes.Success `
                    -Message "Read-only check completed." `
                    -Data @{
                        result = $parsed
                    } |
                    ConvertTo-Json -Depth 10
                return
            }

            $childExitCode = Invoke-RepoScriptProcess -RelativePath $verifyMap[$Target] -ProfilePath $resolvedProfile
            if ($childExitCode -ne 0) {
                exit $script:PublicExitCodes.CheckFailed
            }

            exit $script:PublicExitCodes.Success
        }
    }
}

function Invoke-PublicPlan {
    param(
        [string] $Target
    )

    if (-not $Target) {
        Exit-BoringAdminFailure `
            -Message "plan requires an explicit target." `
            -ErrorId "plan.target_required" `
            -ExitCode $script:PublicExitCodes.Input
    }

    $spec = Get-PlanSpec -Target $Target
    if (-not $spec) {
        Exit-BoringAdminFailure `
            -Message "Unknown plan target: $Target" `
            -ErrorId "plan.unknown_target" `
            -ExitCode $script:PublicExitCodes.Input
    }

    $resolvedProfile = $null
    $config = $null
    if ($spec.requires_profile) {
        try {
            $config = Import-BoringAdminConfig -ProfilePath $script:CliOptions.Profile
            $resolvedProfile = $config.resolvedProfilePath
            Assert-BoringAdminWritableProfile -Config $config -Operation ("plan {0}" -f $Target)
        }
        catch {
            Exit-BoringAdminFailure `
                -Message $_.Exception.Message `
                -ErrorId "config.invalid_profile" `
                -ExitCode $script:PublicExitCodes.Config
        }
    }

    $planOutcome = Get-PublicPlanOutcome -Spec $spec -Config $config

    if ($script:CliOptions.Json) {
        Get-StructuredSuccessRecord `
            -Command "plan" `
            -Target $Target `
            -ExitCode $planOutcome.ExitCode `
            -Message $planOutcome.Message `
            -Severity $planOutcome.Severity `
            -Data @{
                architecture_surface = $BoringAdminSurfaceVersion
                classification       = $spec.classification
                requires_profile     = $spec.requires_profile
                requires_admin       = $spec.requires_admin
                requires_confirm     = $spec.requires_confirm
                resolved_profile     = $resolvedProfile
                legacy_surface       = $spec.legacy_surface
                script_path          = $spec.script_path
                dry_run_equivalent   = if ($spec.write_capable) { ("apply {0} --dry-run" -f $Target) } else { $null }
                summary              = $spec.summary
                plan_kind            = $planOutcome.PlanKind
                change_count         = $planOutcome.ChangeCount
                changes              = @($planOutcome.Changes)
                warnings             = @($planOutcome.Warnings)
                blocking_conditions  = @($planOutcome.BlockingConditions)
                state_determination  = $planOutcome.StateDetermination
            } |
            ConvertTo-Json -Depth 8
        exit $planOutcome.ExitCode
    }

    Write-MakeHeader ("Plan :: {0}" -f $Target)
    Write-MakeInfo ("run_id: {0}" -f $script:RunId)
    Write-MakeInfo ("classification: {0}" -f $spec.classification)
    Write-MakeInfo ("legacy surface: {0}" -f $spec.legacy_surface)
    Write-MakeInfo ("script path: {0}" -f $spec.script_path)
    if ($resolvedProfile) {
        Write-MakeInfo ("profile: {0}" -f $resolvedProfile)
    }
    Write-MakeInfo $spec.summary
    Write-MakeInfo ("plan_kind: {0}" -f $planOutcome.PlanKind)
    Write-MakeInfo ("state_determination: {0}" -f $planOutcome.StateDetermination)
    Write-MakeInfo ("change_count: {0}" -f $planOutcome.ChangeCount)
    Write-Host ""
    Write-BoringAdminHost "This plan is read-only."

    foreach ($warning in @($planOutcome.Warnings)) {
        Write-MakeWarn $warning
    }

    foreach ($blockingCondition in @($planOutcome.BlockingConditions)) {
        Write-MakeWarn ("blocking_condition: {0}" -f $blockingCondition)
    }

    if ($planOutcome.ChangeCount -gt 0) {
        Write-Host ""
        Write-BoringAdminHost "Planned changes:"
        foreach ($change in @($planOutcome.Changes)) {
            Write-BoringAdminHost ("  - {0} [{1}] current={2}; desired={3}" -f $change.id, $change.action, $change.current, $change.desired)
        }
    }

    if ($planOutcome.PlanKind -eq "capability-preview") {
        Write-Host ""
        Write-BoringAdminHost "This target currently exposes capability preview only."
    }
    else {
        Write-Host ""
        if ($spec.write_capable) {
            Write-BoringAdminHost "Use '.\boring-admin.ps1 apply $Target --change-id <id>$(if ($spec.requires_profile) { ' --profile <path>' })' to execute the change."
        }
        else {
            Write-BoringAdminHost "No write-capable apply path is available for this target in v002."
            Write-BoringAdminHost "Use '.\boring-admin.ps1 check security' for the supported read-only path."
        }
    }

    exit $planOutcome.ExitCode
}

function Invoke-PublicApply {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [string] $Target,
        [switch] $FromLegacyOverlay
    )

    if (-not $Target) {
        Exit-BoringAdminFailure `
            -Message "apply requires an explicit target." `
            -ErrorId "apply.target_required" `
            -ExitCode $script:PublicExitCodes.Input
    }

    if ($script:CliOptions.Json) {
        Exit-BoringAdminFailure `
            -Message "Interactive apply does not currently support --json. Use plan --json or check --json for machine output." `
            -ErrorId "apply.json_unsupported" `
            -ExitCode $script:PublicExitCodes.Unsupported `
            -ChangeId $script:CliOptions.ChangeId
    }

    if ($script:CliOptions.DryRun) {
        Invoke-PublicPlan -Target $Target
        return
    }

    $script:CurrentTarget = $Target
    $spec = Get-PlanSpec -Target $Target
    if (-not $spec) {
        Exit-BoringAdminFailure `
            -Message "Unknown apply target: $Target" `
            -ErrorId "apply.unknown_target" `
            -ExitCode $script:PublicExitCodes.Input `
            -ChangeId $script:CliOptions.ChangeId
    }

    if (-not $spec.write_capable) {
        Show-UnsupportedSecurityApply
        return
    }

    if (-not $script:CliOptions.ChangeId) {
        Exit-BoringAdminFailure `
            -Message "apply requires --change-id for the public write-capable surface." `
            -ErrorId "apply.change_id_required" `
            -ExitCode $script:PublicExitCodes.Input
    }

    if ($spec.requires_admin -and -not (Test-IsAdministrator)) {
        Exit-BoringAdminFailure `
            -Message "apply requires an elevated administrator shell." `
            -ErrorId "apply.administrator_required" `
            -ExitCode $script:PublicExitCodes.Permission `
            -ChangeId $script:CliOptions.ChangeId
    }

    $resolvedProfile = Resolve-ProfileForWriteUse -Target $Target
    $safeChangeId = Convert-ToSafeFileComponent -Value $script:CliOptions.ChangeId
    $script:ApplyAuditLogPath = Join-Path (Get-ApplyAuditDirectory) ("apply-{0}-{1}.jsonl" -f $script:RunId, $safeChangeId)
    $applyResultPath = Get-ApplyResultPath

    Write-MakeHeader ("Apply :: {0}" -f $Target)
    Write-MakeInfo ("run_id: {0}" -f $script:RunId)
    Write-MakeInfo ("change_id: {0}" -f $script:CliOptions.ChangeId)
    if ($resolvedProfile) {
        Write-MakeInfo ("profile: {0}" -f $resolvedProfile)
    }
    Write-MakeInfo ("audit_log: {0}" -f $script:ApplyAuditLogPath)
    if ($FromLegacyOverlay) {
        Write-LegacyAliasNotice -LegacyCommand "overlay" -PublicCommand ("apply {0}" -f $Target)
    }

    $precheck = Get-PublicApplyPrecheck -Spec $spec
    if (-not $precheck.Allowed) {
        Write-ApplyAuditEvent -Severity "warn" -Message "Apply blocked before execution." -Data $precheck.AuditData
        Exit-BoringAdminFailure `
            -Message $precheck.Message `
            -ErrorId $precheck.ErrorId `
            -ExitCode $precheck.ExitCode `
            -ChangeId $script:CliOptions.ChangeId `
            -NextAction $precheck.NextAction
    }

    if ($spec.requires_boundary_confirm) {
        Require-PublicApplyConfirmation -Spec $spec
    }

    if (-not (Test-BoringAdminShouldProcess -Target $Target -Action "Apply planned changes" -InvocationCmdlet $PSCmdlet)) {
        Write-ApplyAuditEvent -Severity "warn" -Message "Apply skipped by ShouldProcess." -Data @{ reason = "WhatIf or confirmation declined" }
        exit $script:PublicExitCodes.Success
    }

    Write-ApplyAuditEvent -Severity "info" -Message "Apply started." -Data @{
        target         = $Target
        classification = $spec.classification
        script_path    = $spec.script_path
        profile_path   = $resolvedProfile
    }

    $childExitCode = Invoke-RepoScriptProcess `
        -RelativePath $spec.script_path `
        -ProfilePath $resolvedProfile `
        -AdditionalEnvironment @{
            BORING_ADMIN_APPLY_RESULT_PATH = $applyResultPath
            BORING_ADMIN_PUBLIC_APPLY_TARGET = $Target
        }

    try {
        $completion = Complete-BoringAdminPublicApply `
            -Target $Target `
            -ProfilePath $resolvedProfile `
            -ChangeId $script:CliOptions.ChangeId `
            -ChildExitCode $childExitCode `
            -ApplyResultPath $applyResultPath `
            -AuditPath $script:ApplyAuditLogPath `
            -RunId $script:RunId
    }
    catch {
        Exit-BoringAdminFailure `
            -Message "Apply failed and the workstation record could not be written." `
            -ErrorId "apply.record_write_failed" `
            -ExitCode $script:PublicExitCodes.Runtime `
            -ChangeId $script:CliOptions.ChangeId
    }

    $applyResult = $completion.ApplyResult
    $publicExitCode = [int]$completion.PublicExitCode
    $recordPath = $completion.WorkstationPath

    Write-MakeInfo ("workstation_record: {0}" -f $recordPath)
    if (@($applyResult.warnings).Count -gt 0) {
        Write-MakeWarn ("warnings: {0}" -f (@($applyResult.warnings).Count))
    }
    if ($applyResult.PSObject.Properties["next_action"] -and $applyResult.next_action) {
        Write-MakeInfo ("next_action: {0}" -f $applyResult.next_action)
    }
    if ($applyResult.PSObject.Properties["block_next_step_until_reboot"] -and [bool]$applyResult.block_next_step_until_reboot) {
        Write-MakeWarn "Next step is blocked until reboot."
    }

    if ([string]$applyResult.result -eq "failed") {
        Write-MakeFail "Apply failed."
    }
    elseif ($publicExitCode -eq $script:PublicExitCodes.Partial) {
        Write-MakeWarn "Apply completed with partial or manual-verification-required result."
    }
    else {
        Write-MakeInfo "Apply completed."
    }

    exit $publicExitCode
}

function Parse-CliArguments {
    param(
        [string[]] $Tokens
    )

    $Tokens = @($Tokens)

    $options = [ordered]@{
        Json      = $false
        Quiet     = $false
        Verbose   = $false
        DryRun    = $false
        Help      = $false
        Version   = $false
        Summary   = $false
        Save      = $false
        Profile   = $null
        ChangeId  = $null
    }

    $positionals = [System.Collections.Generic.List[string]]::new()

    for ($index = 0; $index -lt $Tokens.Count; $index++) {
        $token = $Tokens[$index]

        if ($token -eq "--help") {
            $options.Help = $true
            continue
        }

        if ($token -eq "--version") {
            $options.Version = $true
            continue
        }

        if ($token -eq "--json") {
            $options.Json = $true
            continue
        }

        if ($token -eq "--quiet") {
            $options.Quiet = $true
            continue
        }

        if ($token -eq "--verbose") {
            $options.Verbose = $true
            continue
        }

        if ($token -eq "--dry-run") {
            $options.DryRun = $true
            continue
        }

        if ($token -eq "--summary") {
            $options.Summary = $true
            continue
        }

        if ($token -eq "--save") {
            $options.Save = $true
            continue
        }

        if ($token -eq "--profile") {
            if (($index + 1) -ge $Tokens.Count) {
                throw [System.ArgumentException]::new("--profile requires a value.")
            }

            $index++
            $options.Profile = $Tokens[$index]
            continue
        }

        if ($token -eq "--change-id") {
            if (($index + 1) -ge $Tokens.Count) {
                throw [System.ArgumentException]::new("--change-id requires a value.")
            }

            $index++
            $options.ChangeId = $Tokens[$index]
            continue
        }

        if ($token.StartsWith("--")) {
            throw [System.ArgumentException]::new("Unknown option: $token")
        }

        $positionals.Add($token) | Out-Null
    }

    return [pscustomobject]@{
        Command     = if ($positionals.Count -ge 1) { $positionals[0] } else { $null }
        Target      = if ($positionals.Count -ge 2) { $positionals[1] } else { $null }
        Extra       = if ($positionals.Count -gt 2) { @($positionals | Select-Object -Skip 2) } else { @() }
        Options     = [pscustomobject]$options
    }
}

if ($MyInvocation.InvocationName -eq '.') {
    return
}

try {
    $request = Parse-CliArguments -Tokens $CliArgs
    $script:CliOptions = $request.Options

    if (@($request.Extra).Count -gt 0) {
        Exit-BoringAdminFailure `
            -Message ("Unexpected extra arguments: {0}" -f ($request.Extra -join ", ")) `
            -ErrorId "top_level.too_many_arguments" `
            -ExitCode $script:PublicExitCodes.Input `
            -Scope "cli-input-error"
    }

    if ($script:CliOptions.Version -and -not $request.Command) {
        Show-Version
        exit $script:PublicExitCodes.Success
    }

    if ($script:CliOptions.Help -and -not $request.Command) {
        Show-PublicHelp
        exit $script:PublicExitCodes.Success
    }

    $command = if ($request.Command) { $request.Command } else { "help" }
    $target = $request.Target

    switch ($command) {
        "help" {
            Show-PublicHelp
            exit $script:PublicExitCodes.Success
        }
        "version" {
            Show-Version
            exit $script:PublicExitCodes.Success
        }
        "check" {
            Invoke-PublicCheck -Target $(if ($target) { $target } else { "all" })
            return
        }
        "plan" {
            Invoke-PublicPlan -Target $target
            return
        }
        "apply" {
            Invoke-PublicApply -Target $target
            return
        }
        "audit" {
            if ($target -eq "export") {
                $script:CliOptions.Json = $true
            }

            Write-LegacyAliasNotice -LegacyCommand "audit" -PublicCommand "check"

            switch ($target) {
                $null { Invoke-PublicCheck -Target "all"; return }
                "all" { Invoke-PublicCheck -Target "all"; return }
                "export" { Invoke-PublicCheck -Target "all"; return }
                "summary" { $script:CliOptions.Summary = $true; Invoke-PublicCheck -Target "all"; return }
                "save" { $script:CliOptions.Save = $true; Invoke-PublicCheck -Target "all"; return }
                "recovery" { Invoke-PublicCheck -Target "recovery"; return }
                "help" { Show-PublicHelp; exit $script:PublicExitCodes.Success }
                default { Invoke-PublicCheck -Target $target; return }
            }
        }
        "verify" {
            Write-LegacyAliasNotice -LegacyCommand "verify" -PublicCommand "check"
            Invoke-PublicCheck -Target $(if ($target) { $target } else { "all" })
            return
        }
        "overlay" {
            if (-not $target) {
                Exit-BoringAdminFailure `
                    -Message "overlay requires a target. Use apply software or apply ux." `
                    -ErrorId "overlay.target_required" `
                    -ExitCode $script:PublicExitCodes.Input
            }

            Invoke-PublicApply -Target $target -FromLegacyOverlay
            return
        }
        "review" {
            Write-LegacyAliasNotice -LegacyCommand "review" -PublicCommand "plan"

            $legacyReviewMap = @{
                "security" = "scripts/apply/security/21-security-baseline.manual.ps1"
                "identity" = "scripts/apply/identity/40-identity-local-orchestrator.manual.ps1"
                "host"     = "scripts/apply/host/50-host-identity-orchestrator.manual.ps1"
            }

            if (-not $target) {
                Show-PublicHelp
                exit $script:PublicExitCodes.Success
            }

            if (-not $legacyReviewMap.ContainsKey($target)) {
                Exit-BoringAdminFailure `
                    -Message "Unknown legacy review target: $target" `
                    -ErrorId "review.unknown_target" `
                    -ExitCode $script:PublicExitCodes.Input
            }

            $childExitCode = Invoke-RepoScriptProcess -RelativePath $legacyReviewMap[$target] -ProfilePath (Resolve-ProfileForReadOnlyUse)
            if ($childExitCode -ne 0) {
                exit $script:PublicExitCodes.Runtime
            }

            exit $script:PublicExitCodes.Success
        }
        "info" {
            Show-LegacyInfo
            exit $script:PublicExitCodes.Success
        }
        "setup" {
            Show-LegacySetup
            exit $script:PublicExitCodes.Success
        }
        "check-env" {
            Write-LegacyAliasNotice -LegacyCommand "check-env" -PublicCommand "check env"
            Invoke-PublicCheck -Target "env"
            return
        }
        "operational" {
            Write-LegacyAliasNotice -LegacyCommand "operational" -PublicCommand "help"
            Show-PublicHelp
            exit $script:PublicExitCodes.Success
        }
        default {
            Exit-BoringAdminFailure `
                -Message "Unknown command: $command" `
                -ErrorId "top_level.unknown_command" `
                -ExitCode $script:PublicExitCodes.Input `
                -Scope "cli-input-error"
        }
    }
}
catch [System.ArgumentException] {
    Exit-BoringAdminFailure `
        -Message $_.Exception.Message `
        -ErrorId "cli.invalid_argument" `
        -ExitCode $script:PublicExitCodes.Input `
        -Scope "cli-input-error"
}
catch {
    Exit-BoringAdminFailure `
        -Message $_.Exception.Message `
        -ErrorId "runtime.unhandled_exception" `
        -ExitCode $script:PublicExitCodes.Runtime `
        -Scope "runtime-error" `
        -ChangeId $script:CliOptions.ChangeId
}
