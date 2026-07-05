# ============================================================================
# 51-host-identity-core.manual.ps1
#
# PURPOSE
# -------
# Enforce the core host identity state of the system:
# - computer name
# - system time zone
# - system locale (non-Unicode)
#
# This script is used by boring-admin.ps1 apply host.
#
# CONTRACT
# --------
# Follows docs/ARCHITECTURE.md and docs/ARCHITECTURE.md
# ============================================================================

[CmdletBinding()]
param()

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
$config = Import-BoringAdminConfigOrFail
$null = Initialize-BoringAdminApplyResult -Target "host"

try {
    Assert-BoringAdminWritableProfile -Config $config -Operation "Host identity apply"
}
catch {
    Exit-Fatal $_.Exception.Message
}

$hostIdentity = Get-BoringAdminHostIdentitySettings -Config $config

Assert-Administrator
Test-PowerShellVersion | Out-Null

Write-Section "51-host-identity - Core Host Identity"
Write-Info "Public confirmation is handled before this script executes."

$desiredComputerName = $hostIdentity.computerName
$desiredTimeZone = $hostIdentity.timeZone
$desiredSystemLocale = $hostIdentity.systemLocale

$currentComputerName = $env:COMPUTERNAME
$currentTimeZone = (Get-TimeZone).Id
$currentSystemLocale = (Get-WinSystemLocale).Name
$pendingRebootBefore = @(Get-BoringAdminPendingRebootSignals)
$renameScheduled = $false
$systemLocaleChanged = $false
$timeZoneChanged = $false

if ($pendingRebootBefore.Count -gt 0) {
    $warningMessage = "A pending reboot already exists before host identity changes."
    Write-WarnFlagged $warningMessage
    Add-BoringAdminApplyWarning $warningMessage
    Register-BoringAdminApplyResultState -Result "manual-verification-required"
    Register-BoringAdminRebootCheckpoint -RebootRequired $true -ReadyForNextStep $false -BlockNextStepUntilReboot $true
}

Write-Section "Computer Name"
Write-Info "Current computer name : $currentComputerName"
Write-Info "Desired computer name : $desiredComputerName"

if ($currentComputerName -ieq $desiredComputerName) {
    Write-OK "Computer name already matches desired state."
}
else {
    try {
        Rename-Computer -NewName $desiredComputerName -Force
        $renameScheduled = $true
        $warningMessage = "Computer rename scheduled. Reboot is required before the next baseline step."
        Write-WarnFlagged $warningMessage
        Add-BoringAdminApplyWarning $warningMessage
        Register-BoringAdminApplyResultState -Result "manual-verification-required"
        Register-BoringAdminRebootCheckpoint -RebootRequired $true -ReadyForNextStep $false -BlockNextStepUntilReboot $true
    }
    catch {
        Exit-Fatal "Failed to schedule computer rename."
    }
}

Write-Section "System Time Zone"
Write-Info "Current time zone : $currentTimeZone"
Write-Info "Desired time zone : $desiredTimeZone"

if ($currentTimeZone -eq $desiredTimeZone) {
    Write-OK "System time zone already matches desired state."
}
else {
    try {
        Set-TimeZone -Id $desiredTimeZone
        $timeZoneChanged = $true
        Write-Info "System time zone updated."
    }
    catch {
        Exit-Fatal "Failed to set system time zone."
    }
}

Write-Section "System Locale (Non-Unicode)"
Write-Info "Current system locale : $currentSystemLocale"
Write-Info "Desired system locale : $desiredSystemLocale"

if ($currentSystemLocale -eq $desiredSystemLocale) {
    Write-OK "System locale already matches desired state."
}
else {
    try {
        Set-WinSystemLocale -SystemLocale $desiredSystemLocale
        $systemLocaleChanged = $true
        $warningMessage = "System locale updated. Reboot is required before the next baseline step."
        Write-WarnFlagged $warningMessage
        Add-BoringAdminApplyWarning $warningMessage
        Register-BoringAdminApplyResultState -Result "manual-verification-required"
        Register-BoringAdminRebootCheckpoint -RebootRequired $true -ReadyForNextStep $false -BlockNextStepUntilReboot $true
    }
    catch {
        Exit-Fatal "Failed to set system locale."
    }
}

$pendingRebootAfter = @(Get-BoringAdminPendingRebootSignals)
if ($pendingRebootAfter.Count -gt 0) {
    Register-BoringAdminRebootCheckpoint -RebootRequired $true -ReadyForNextStep $false -BlockNextStepUntilReboot $true
}

Add-BoringAdminApplyDetail -Name "host_identity" -Value ([pscustomobject]@{
    current = [pscustomobject]@{
        computerName = $currentComputerName
        timeZone     = $currentTimeZone
        systemLocale = $currentSystemLocale
    }
    desired = [pscustomobject]@{
        computerName = $desiredComputerName
        timeZone     = $desiredTimeZone
        systemLocale = $desiredSystemLocale
    }
    changes = [pscustomobject]@{
        renameScheduled   = $renameScheduled
        timeZoneChanged   = $timeZoneChanged
        systemLocaleChanged = $systemLocaleChanged
    }
    pendingRebootBefore = @($pendingRebootBefore)
    pendingRebootAfter  = @($pendingRebootAfter)
})

Write-Section "Intentional non-actions"
Write-Info "No reboot was performed"
Write-Info "No services were restarted"
Write-Info "No user or group identities were modified"
Write-Info "No network configuration was changed"
Write-Info "No security baselines were altered"

Write-Section "Summary"
Write-Info "Host identity core configuration completed."
Write-BoringAdminApplyResult
Exit-Warn
