Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# ============================================================================
# common.ps1
#
# PURPOSE
# -------
# Shared helper layer for boring-admin-windows scripts.
#
# This file is the single runtime helper source for:
# - execution assertions
# - console output vocabulary
# - warning and exit handling
# - selected registry/profile helpers
# - guarded system queries
#
# DESIGN RULES
# ------------
# - helper functions only
# - no auto-execution on import
# - safe for dot-sourcing
# - explicit calls only
# ============================================================================


# ============================================================================
# 1. EXECUTION ASSERTIONS
# ============================================================================

function Assert-Administrator {
    <#
    .SYNOPSIS
        Ensures the current session is elevated.
    #>

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Exit-Fatal "This script must be run as Administrator."
    }
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-PowerShellVersion {
    <#
    .SYNOPSIS
        Returns $true when running on PowerShell 7+.
    #>

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Warn "Running under Windows PowerShell 5.1. Some behavior may be limited."
        return $false
    }

    return $true
}

function Test-BoringAdminNoColorRequested {
    return -not [string]::IsNullOrWhiteSpace([string]$env:NO_COLOR)
}

function Test-BoringAdminOutputRedirected {
    try {
        return [Console]::IsOutputRedirected
    }
    catch {
        return $false
    }
}

function Test-BoringAdminColorEnabled {
    if (Test-BoringAdminNoColorRequested) {
        return $false
    }

    if (Test-BoringAdminOutputRedirected) {
        return $false
    }

    return $true
}

function Write-BoringAdminHost {
    param(
        [AllowEmptyString()]
        [string] $Message = "",

        [ConsoleColor] $ForegroundColor
    )

    if ($PSBoundParameters.ContainsKey("ForegroundColor") -and (Test-BoringAdminColorEnabled)) {
        Write-Host $Message -ForegroundColor $ForegroundColor
        return
    }

    Write-Host $Message
}

function ConvertTo-BoringAdminOutputPreview {
    param(
        [AllowNull()]
        [object] $Output,

        [int] $MaxLength = 800
    )

    $text = if ($null -eq $Output) {
        ""
    }
    elseif ($Output -is [string]) {
        [string]$Output
    }
    else {
        ($Output | Out-String)
    }

    $trimmed = $text.Trim()
    if ($trimmed.Length -le $MaxLength) {
        return $trimmed
    }

    return "{0}...[truncated]" -f $trimmed.Substring(0, $MaxLength)
}

function Get-BoringAdminCommandResult {
    param(
        [Parameter(Mandatory)]
        [int] $ExitCode,

        [AllowNull()]
        [object] $Output,

        [int] $MaxOutputLength = 800
    )

    return [pscustomobject]@{
        ExitCode = [int]$ExitCode
        Output   = [string](ConvertTo-BoringAdminOutputPreview -Output $Output -MaxLength $MaxOutputLength)
    }
}


# ============================================================================
# 2. OUTPUT HELPERS
# ============================================================================

function Write-Section {
    param(
        [Parameter(Mandatory)]
        [string] $Title
    )

    Write-Host ""
    Write-BoringAdminHost "=== $Title ===" -ForegroundColor Cyan
}

function Write-SubSection {
    param(
        [Parameter(Mandatory)]
        [string] $Title
    )

    Write-Host ""
    Write-BoringAdminHost "-- $Title --" -ForegroundColor DarkCyan
}

function Write-Info {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-BoringAdminHost "[INFO] $Message" -ForegroundColor White
}

function Write-Warn {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-BoringAdminHost "[WARN] $Message" -ForegroundColor Yellow
}

function Write-WarnFlagged {
    param(
        [Parameter(Mandatory)]
        [string] $Message,

        [Parameter(Position = 1)]
        [object] $Flag
    )

    $script:HadWarnings = $true

    if ($null -ne $Flag -and $Flag -is [ref]) {
        $Flag.Value = $true
    }

    Write-Warn $Message
}

function Write-OK {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-BoringAdminHost "[OK]   $Message" -ForegroundColor Green
}

function Write-Fail {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-BoringAdminHost "[FAIL] $Message" -ForegroundColor Red
}


# ============================================================================
# 3. TIME AND ERROR HELPERS
# ============================================================================

function Get-Rfc3339Timestamp {
    return [DateTimeOffset]::Now.ToString(
        "yyyy-MM-ddTHH:mm:sszzz",
        [System.Globalization.CultureInfo]::InvariantCulture
    )
}

function Get-BoringAdminRecordRoot {
    $programData = if ($env:ProgramData) {
        $env:ProgramData
    }
    else {
        Join-Path $env:SystemDrive "ProgramData"
    }

    return Join-Path $programData "BoringAdmin\records"
}

function Get-BoringAdminApplyAuditDirectory {
    $directory = Join-Path (Get-BoringAdminRecordRoot) "apply-audit"
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    return $directory
}

function Get-BoringAdminCheckRecordDirectory {
    $directory = Join-Path (Get-BoringAdminRecordRoot) "checks"
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    return $directory
}

function Write-BoringAdminJsonAtomically {
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [object] $InputObject,

        [int] $Depth = 10
    )

    $directory = Split-Path -Parent $Path
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $temporaryPath = "{0}.{1}.tmp" -f $Path, ([guid]::NewGuid().ToString("N"))
    $json = $InputObject | ConvertTo-Json -Depth $Depth
    [System.IO.File]::WriteAllText($temporaryPath, $json, [System.Text.Encoding]::UTF8)
    Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
}

function Get-FileSha256Hex {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Get-BoringAdminLocalGroupNameBySid {
    param(
        [Parameter(Mandatory)]
        [string] $Sid
    )

    try {
        $sidObject = [System.Security.Principal.SecurityIdentifier]::new($Sid)
        $translated = $sidObject.Translate([System.Security.Principal.NTAccount]).Value
        return ($translated -split "\\", 2)[-1]
    }
    catch {
        Exit-Fatal "Unable to resolve built-in local group SID '$Sid'."
    }
}

function Get-BoringAdminAdministratorsGroupName {
    return Get-BoringAdminLocalGroupNameBySid -Sid "S-1-5-32-544"
}

function Get-BoringAdminPendingRebootSignals {
    $signals = [System.Collections.Generic.List[string]]::new()

    $keyChecks = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    )

    foreach ($path in $keyChecks) {
        if (Test-Path -LiteralPath $path -PathType Container) {
            $signals.Add($path) | Out-Null
        }
    }

    $sessionManagerPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
    try {
        $sessionManager = Get-ItemProperty -LiteralPath $sessionManagerPath -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue
        if ($sessionManager -and $sessionManager.PendingFileRenameOperations) {
            $signals.Add("${sessionManagerPath}::PendingFileRenameOperations") | Out-Null
        }
    }
    catch {
        Write-Warn "Unable to read pending reboot markers from Session Manager."
    }

    return @($signals)
}

function Get-BoringAdminRunId {
    return [guid]::NewGuid().ToString()
}

function Get-BoringAdminEventId {
    return [guid]::NewGuid().ToString()
}

function Get-StructuredEventRecord {
    param(
        [Parameter(Mandatory)]
        [string] $RunId,

        [Parameter(Mandatory)]
        [string] $Severity,

        [Parameter(Mandatory)]
        [string] $Message,

        [string] $Scope = "runtime-event",

        [string] $Command,

        [string] $Target,

        [string] $ChangeId,

        [hashtable] $Data
    )

    $record = [ordered]@{
        scope       = $Scope
        generatedAt = Get-Rfc3339Timestamp
        run_id      = $RunId
        event_id    = Get-BoringAdminEventId
        severity    = $Severity
        message     = $Message
    }

    if ($Command) {
        $record.command = $Command
    }

    if ($Target) {
        $record.target = $Target
    }

    if ($ChangeId) {
        $record.change_id = $ChangeId
    }

    if ($Data) {
        $record.data = [pscustomobject]$Data
    }

    return [pscustomobject]$record
}

function Get-StructuredErrorRecord {
    param(
        [Parameter(Mandatory)]
        [string] $ErrorId,

        [Parameter(Mandatory)]
        [string] $Message,

        [int] $ExitCode = 1,

        [string] $Scope = "runtime-error",

        [string] $RunId,

        [string] $EventId,

        [string] $ChangeId,

        [string] $NextAction
    )

    if (-not $RunId) {
        $RunId = Get-BoringAdminRunId
    }

    if (-not $EventId) {
        $EventId = Get-BoringAdminEventId
    }

    $record = [ordered]@{
        scope       = $Scope
        generatedAt = Get-Rfc3339Timestamp
        run_id      = $RunId
        event_id    = $EventId
        severity    = "error"
        error_id    = $ErrorId
        exit_code   = $ExitCode
        message     = $Message
    }

    if ($ChangeId) {
        $record.change_id = $ChangeId
    }

    if ($NextAction) {
        $record.next_action = $NextAction
    }

    return [pscustomobject]$record
}


# ============================================================================
# 4. EXIT HELPERS
# ============================================================================

function Exit-Warn {
    <#
    .SYNOPSIS
        Emits a warning summary when warnings were recorded and exits 0.
    #>

    if ($script:HadWarnings) {
        Write-Warn "Completed with warnings."
    }

    exit 0
}

function Exit-Fatal {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-Fail $Message
    exit 1
}

function Require-ManualConfirmation {
    <#
    .SYNOPSIS
        Requires explicit YES confirmation for state-changing MANUAL scripts.
    #>

    param(
        [string] $Prompt = "Type YES to continue",
        [string] $AbortMessage = "Operation aborted by operator."
    )

    $confirm = Read-Host $Prompt
    if ($confirm -ne "YES") {
        Write-WarnFlagged $AbortMessage
        Exit-Warn
    }
}

function Initialize-BoringAdminApplyResult {
    param(
        [Parameter(Mandatory)]
        [string] $Target
    )

    $script:BoringAdminApplyResult = [ordered]@{
        target                        = $Target
        result                        = "completed"
        reboot_required               = $false
        block_next_step_until_reboot = $false
        ready_for_next_step           = $true
        warnings                      = [System.Collections.Generic.List[string]]::new()
        failed_items                  = [System.Collections.Generic.List[object]]::new()
        optional_failed_items         = [System.Collections.Generic.List[object]]::new()
        details                       = [ordered]@{}
    }

    return [pscustomobject]$script:BoringAdminApplyResult
}

function Add-BoringAdminApplyWarning {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    if (-not $script:BoringAdminApplyResult) {
        return
    }

    $script:BoringAdminApplyResult.warnings.Add($Message) | Out-Null
}

function Add-BoringAdminApplyFailedItem {
    param(
        [Parameter(Mandatory)]
        [string] $Id,

        [Parameter(Mandatory)]
        [string] $Reason,

        [string] $Classification = "unknown",

        [string] $ExpectedVersion,

        [string] $ObservedVersion
    )

    if (-not $script:BoringAdminApplyResult) {
        return
    }

    $record = [ordered]@{
        id             = $Id
        reason         = $Reason
        classification = $Classification
    }

    if ($ExpectedVersion) {
        $record.expected_version = $ExpectedVersion
    }

    if ($ObservedVersion) {
        $record.observed_version = $ObservedVersion
    }

    $script:BoringAdminApplyResult.failed_items.Add([pscustomobject]$record) | Out-Null
}

function Add-BoringAdminApplyOptionalFailedItem {
    param(
        [Parameter(Mandatory)]
        [string] $Id,

        [Parameter(Mandatory)]
        [string] $Reason,

        [string] $Classification = "unknown",

        [string] $ExpectedVersion,

        [string] $ObservedVersion
    )

    if (-not $script:BoringAdminApplyResult) {
        return
    }

    $record = [ordered]@{
        id             = $Id
        reason         = $Reason
        classification = $Classification
    }

    if ($ExpectedVersion) {
        $record.expected_version = $ExpectedVersion
    }

    if ($ObservedVersion) {
        $record.observed_version = $ObservedVersion
    }

    $script:BoringAdminApplyResult.optional_failed_items.Add([pscustomobject]$record) | Out-Null
}

function Invoke-BoringAdminApplyOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Id,

        [Parameter(Mandatory)]
        [string] $Classification,

        [Parameter(Mandatory)]
        [string] $FailureReason,

        [Parameter(Mandatory)]
        [string] $FailureMessage,

        [ValidateSet("partial", "manual-verification-required", "failed")]
        [string] $FailureResult = "partial",

        [Parameter(Mandatory)]
        [scriptblock] $Operation
    )

    try {
        return [pscustomobject]@{
            Success        = $true
            Value          = (& $Operation)
            Id             = $Id
            Classification = $Classification
            Reason         = $null
            Error          = $null
        }
    }
    catch {
        $errorDetail = $_.Exception.Message
        $message = if ([string]::IsNullOrWhiteSpace($errorDetail)) {
            $FailureMessage
        }
        else {
            "{0} Details: {1}" -f $FailureMessage, $errorDetail
        }

        Write-WarnFlagged -Message $message
        Add-BoringAdminApplyWarning -Message $message
        Add-BoringAdminApplyFailedItem -Id $Id -Reason $FailureReason -Classification $Classification
        Register-BoringAdminApplyResultState -Result $FailureResult

        return [pscustomobject]@{
            Success        = $false
            Value          = $null
            Id             = $Id
            Classification = $Classification
            Reason         = $FailureReason
            Error          = $errorDetail
        }
    }
}

function Register-BoringAdminApplyResultState {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("completed", "partial", "failed", "manual-verification-required")]
        [string] $Result
    )

    if (-not $script:BoringAdminApplyResult) {
        return
    }

    $precedence = @{
        completed                     = 0
        "manual-verification-required" = 1
        partial                       = 2
        failed                        = 3
    }

    $current = [string]$script:BoringAdminApplyResult.result
    if ($precedence[$Result] -gt $precedence[$current]) {
        $script:BoringAdminApplyResult.result = $Result
    }
}

function Register-BoringAdminRebootCheckpoint {
    param(
        [bool] $RebootRequired = $false,
        [bool] $ReadyForNextStep = $true,
        [bool] $BlockNextStepUntilReboot = $false
    )

    if (-not $script:BoringAdminApplyResult) {
        return
    }

    if ($RebootRequired) {
        $script:BoringAdminApplyResult.reboot_required = $true
    }

    if (-not $ReadyForNextStep) {
        $script:BoringAdminApplyResult.ready_for_next_step = $false
    }

    if ($BlockNextStepUntilReboot) {
        $script:BoringAdminApplyResult.block_next_step_until_reboot = $true
    }
}

function Add-BoringAdminApplyDetail {
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [object] $Value
    )

    if (-not $script:BoringAdminApplyResult) {
        return
    }

    $script:BoringAdminApplyResult.details[$Name] = $Value
}

function Write-BoringAdminApplyResult {
    if (-not $script:BoringAdminApplyResult) {
        return
    }

    $resultPath = [System.Environment]::GetEnvironmentVariable("BORING_ADMIN_APPLY_RESULT_PATH", "Process")
    if ([string]::IsNullOrWhiteSpace($resultPath)) {
        return
    }

    $record = [ordered]@{
        generated_at                  = Get-Rfc3339Timestamp
        target                        = $script:BoringAdminApplyResult.target
        result                        = $script:BoringAdminApplyResult.result
        reboot_required               = [bool]$script:BoringAdminApplyResult.reboot_required
        ready_for_next_step           = [bool]$script:BoringAdminApplyResult.ready_for_next_step
        block_next_step_until_reboot = [bool]$script:BoringAdminApplyResult.block_next_step_until_reboot
        warnings                      = @($script:BoringAdminApplyResult.warnings)
        failed_items                  = @($script:BoringAdminApplyResult.failed_items)
        optional_failed_items         = @($script:BoringAdminApplyResult.optional_failed_items)
        details                       = [pscustomobject]$script:BoringAdminApplyResult.details
    }

    Write-BoringAdminJsonAtomically -Path $resultPath -InputObject $record -Depth 10
}


# ============================================================================
# 5. REGISTRY AND PROFILE HELPERS
# ============================================================================

function Mount-DefaultUserProfile {
    <#
    .SYNOPSIS
        Mounts the Default User hive to HKLM:\DefUser.
    #>

    $defaultHivePath = "C:\Users\Default\NTUSER.DAT"
    Write-Info "Mounting Default User profile hive."

    if (Test-Path "HKLM:\DefUser") {
        Write-Warn "Default User hive is already mounted or path is occupied."
        return
    }

    & reg.exe load "HKLM\DefUser" $defaultHivePath | Out-Null

    if ($LASTEXITCODE -ne 0) {
        Exit-Fatal "Failed to mount Default User profile hive."
    }
}

function Dismount-DefaultUserProfile {
    <#
    .SYNOPSIS
        Unmounts the Default User hive from HKLM:\DefUser.
    #>

    if (-not (Test-Path "HKLM:\DefUser")) {
        return
    }

    Write-Info "Dismounting Default User profile hive."

    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()

    & reg.exe unload "HKLM\DefUser" | Out-Null

    if ($LASTEXITCODE -ne 0) {
        Write-Warn "Failed to dismount Default User hive. It may still be locked."
    }
}

function Set-RegistryPreference {
    <#
    .SYNOPSIS
        Writes a registry value to HKCU and to HKLM:\DefUser when mounted.
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)]
        [string] $KeyPath,

        [Parameter(Mandatory)]
        [string] $ValueName,

        [Parameter(Mandatory)]
        $Value,

        [ValidateSet("DWord", "String", "ExpandString", "QWord")]
        [string] $ValueType = "DWord"
    )

    $targets = @("HKCU:\$KeyPath")

    if (Test-Path "HKLM:\DefUser") {
        $targets += "HKLM:\DefUser\$KeyPath"
    }

    foreach ($path in $targets) {
        if ($PSCmdlet.ShouldProcess("$path\$ValueName", "Set registry preference")) {
            if (-not (Test-Path $path)) {
                New-Item -Path $path -Force | Out-Null
            }

            New-ItemProperty `
                -Path $path `
                -Name $ValueName `
                -Value $Value `
                -PropertyType $ValueType `
                -Force | Out-Null

            Write-Info "Registry set: $path\$ValueName = $Value"
        }
    }
}


# ============================================================================
# 6. GUARDED SYSTEM QUERIES
# ============================================================================

function Try-GetMpComputerStatus {
    <#
    .SYNOPSIS
        Queries Defender status without blocking the caller indefinitely.
    #>

    param(
        [int] $TimeoutSec = 5
    )

    $job = Start-Job -ScriptBlock {
        Get-MpComputerStatus
    }

    try {
        if (Wait-Job -Job $job -Timeout $TimeoutSec) {
            return Receive-Job -Job $job
        }

        Write-Warn "Get-MpComputerStatus timed out after $TimeoutSec seconds."
        return $null
    }
    catch {
        Write-Warn "Get-MpComputerStatus failed."
        return $null
    }
    finally {
        if ($job) {
            Stop-Job -Job $job -ErrorAction SilentlyContinue | Out-Null
            Remove-Job -Job $job -Force -ErrorAction SilentlyContinue | Out-Null
        }
    }
}
