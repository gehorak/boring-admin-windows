# ============================================================================
# 55-host-identity-visibility.verify.ps1
#
# PURPOSE
# -------
# Provide read-only visibility into current host identity, desired host
# identity from the active profile, and pending reboot markers that can block
# the next baseline step.
#
# CONTRACT
# --------
# Follows docs/ARCHITECTURE.md and docs/ARCHITECTURE.md
# ============================================================================

[CmdletBinding()]
param(
    [ValidateSet("Text", "Json")]
    [string] $OutputFormat = "Text"
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptRoot "..\..")
if (-not (Test-Path (Join-Path $ProjectRoot "core\lib\common.ps1"))) {
    $ProjectRoot = Resolve-Path (Join-Path $ScriptRoot "..\..\..")
}

. (Join-Path $ProjectRoot "core\lib\common.ps1")
. (Join-Path $ProjectRoot "core\lib\config.ps1")

$script:HadWarnings = $false
$warnings = [System.Collections.Generic.List[string]]::new()
$config = Import-BoringAdminConfigOrFail
$hostIdentity = Get-BoringAdminHostIdentitySettings -Config $config

function Add-HostVisibilityWarning {
    param(
        [Parameter(Mandatory)]
        [string] $Message
    )

    $script:HadWarnings = $true
    $warnings.Add($Message) | Out-Null

    if ($OutputFormat -eq "Text") {
        Write-Warn $Message
    }
}

Assert-Administrator
Test-PowerShellVersion | Out-Null

$currentComputerName = $null
$currentTimeZone = $null
$currentSystemLocale = $null

try {
    $currentComputerName = $env:COMPUTERNAME
}
catch {
    Add-HostVisibilityWarning "Unable to read computer name."
}

try {
    $currentTimeZone = (Get-TimeZone).Id
}
catch {
    Add-HostVisibilityWarning "Unable to read system time zone."
}

try {
    $currentSystemLocale = (Get-WinSystemLocale).Name
}
catch {
    Add-HostVisibilityWarning "Unable to read system locale."
}

$pendingRebootSignals = @(Get-BoringAdminPendingRebootSignals)
if ($pendingRebootSignals.Count -gt 0) {
    Add-HostVisibilityWarning "Pending reboot markers are present."
}

$drift = [pscustomobject]@{
    computerName = [bool]($currentComputerName -and $currentComputerName -ine $hostIdentity.computerName)
    timeZone     = [bool]($currentTimeZone -and $currentTimeZone -ne $hostIdentity.timeZone)
    systemLocale = [bool]($currentSystemLocale -and $currentSystemLocale -ne $hostIdentity.systemLocale)
}

if ($drift.computerName) {
    Add-HostVisibilityWarning "Computer name does not match the active profile."
}

if ($drift.timeZone) {
    Add-HostVisibilityWarning "System time zone does not match the active profile."
}

if ($drift.systemLocale) {
    Add-HostVisibilityWarning "System locale does not match the active profile."
}

$result = [pscustomobject]@{
    scope       = "host-identity-visibility"
    generatedAt = Get-Rfc3339Timestamp
    host        = [pscustomobject]@{
        current = [pscustomobject]@{
            computerName = $currentComputerName
            timeZone     = $currentTimeZone
            systemLocale = $currentSystemLocale
        }
        desired = [pscustomobject]@{
            computerName = $hostIdentity.computerName
            timeZone     = $hostIdentity.timeZone
            systemLocale = $hostIdentity.systemLocale
        }
        drift               = $drift
        pendingRebootSignals = @($pendingRebootSignals)
        nextStepReady       = ($pendingRebootSignals.Count -eq 0)
    }
    warnings    = @($warnings)
}

if ($OutputFormat -eq "Json") {
    $result | ConvertTo-Json -Depth 7
    Exit-Warn
}

Write-Section "55-host-identity - Visibility (VERIFY)"
Write-Section "Current host identity"
Write-Info "Computer name : $currentComputerName"
Write-Info "Time zone     : $currentTimeZone"
Write-Info "System locale : $currentSystemLocale"

Write-Section "Desired host identity"
Write-Info "Computer name : $($hostIdentity.computerName)"
Write-Info "Time zone     : $($hostIdentity.timeZone)"
Write-Info "System locale : $($hostIdentity.systemLocale)"

Write-Section "Drift and reboot checkpoint"
Write-Info "Computer name drift : $($drift.computerName)"
Write-Info "Time zone drift     : $($drift.timeZone)"
Write-Info "System locale drift : $($drift.systemLocale)"
Write-Info "Next step ready     : $($pendingRebootSignals.Count -eq 0)"

foreach ($signal in $pendingRebootSignals) {
    Write-Info "Pending reboot signal: $signal"
}

Write-Section "Intentional non-actions"
Write-Info "No configuration was modified"
Write-Info "No reboot was scheduled or performed"
Write-Info "No enforcement or remediation occurred"
Write-Info "No network or security settings were accessed"

Write-Section "Summary"
Write-Info "Host identity visibility check completed."
Exit-Warn
