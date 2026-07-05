# ============================================================================
# 41-identity-local-admin-model.manual.ps1
#
# PURPOSE
# -------
# Establish and maintain the explicit local administrator model for Windows 11
# systems in SMB / non-domain environments.
#
# This script is used by boring-admin.ps1 apply identity.
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
$null = Initialize-BoringAdminApplyResult -Target "identity"

try {
    Assert-BoringAdminWritableProfile -Config $config -Operation "Local administrator model enforcement"
}
catch {
    Exit-Fatal $_.Exception.Message
}

$identitySettings = Get-BoringAdminIdentitySettings -Config $config
$administratorsGroupName = Get-BoringAdminAdministratorsGroupName
$expectedManagedAccounts = @($identitySettings.primaryAdminName, $identitySettings.recoveryAdminName)

function Get-LocalUserSafe {
    param(
        [Parameter(Mandatory)]
        [string] $Name
    )

    try {
        return Get-LocalUser -Name $Name -ErrorAction Stop
    }
    catch {
        return $null
    }
}

function Test-LocalGroupMembership {
    param(
        [Parameter(Mandatory)]
        [string] $Group,

        [Parameter(Mandatory)]
        [string] $Member
    )

    try {
        $groupMembers = @(Get-LocalGroupMember -Group $Group -ErrorAction Stop)
    }
    catch {
        return $false
    }

    foreach ($groupMember in $groupMembers) {
        if ($groupMember.Name -imatch ("(^|\\){0}$" -f [regex]::Escape($Member))) {
            return $true
        }
    }

    return $false
}

function Ensure-AdministratorsMembership {
    param(
        [Parameter(Mandatory)]
        [string] $AccountName
    )

    if (Test-LocalGroupMembership -Group $administratorsGroupName -Member $AccountName) {
        return "present"
    }

    Add-LocalGroupMember -Group $administratorsGroupName -Member $AccountName -ErrorAction Stop
    return "added"
}

Assert-Administrator
Test-PowerShellVersion | Out-Null

Write-Section "41-identity - Local Administrator Model"
Write-Info "Administrators group resolved from SID S-1-5-32-544 as: $administratorsGroupName"
Write-Info "Public confirmation is handled before this script executes."

$primaryAdminName = $identitySettings.primaryAdminName
$recoveryAdminName = $identitySettings.recoveryAdminName
$primaryAdmin = Get-LocalUserSafe -Name $primaryAdminName
$recoveryAdmin = Get-LocalUserSafe -Name $recoveryAdminName

$primaryAction = "unchanged"
$primaryMembership = "unknown"
$recoveryAction = "unchanged"
$recoveryMembership = "unknown"

Write-Section "Apply admin model: Primary administrator"

if (-not $primaryAdmin) {
    Write-Info "Creating primary administrator: $primaryAdminName"
    $password = Read-Host "Enter password for $primaryAdminName" -AsSecureString

    try {
        New-LocalUser -Name $primaryAdminName -Password $password -Description "Primary local administrator" -PasswordNeverExpires:$false -UserMayNotChangePassword:$true -ErrorAction Stop
        $primaryAction = "created"
    }
    catch {
        Exit-Fatal "Failed to create primary administrator '$primaryAdminName'."
    }
}
elseif (-not $primaryAdmin.Enabled) {
    try {
        Enable-LocalUser -Name $primaryAdminName -ErrorAction Stop
        $primaryAction = "enabled"
    }
    catch {
        Exit-Fatal "Failed to enable primary administrator '$primaryAdminName'."
    }
}

try {
    $primaryMembership = Ensure-AdministratorsMembership -AccountName $primaryAdminName
}
catch {
    Exit-Fatal "Failed to ensure Administrators membership for '$primaryAdminName'."
}

Write-Section "Apply admin model: Recovery administrator"

if (-not $recoveryAdmin) {
    Write-Info "Creating recovery administrator: $recoveryAdminName"
    $password = Read-Host "Enter password for $recoveryAdminName" -AsSecureString

    try {
        New-LocalUser -Name $recoveryAdminName -Password $password -Description "Recovery administrator (disabled)" -PasswordNeverExpires:$false -UserMayNotChangePassword:$true -ErrorAction Stop
        $recoveryAction = "created"
    }
    catch {
        Exit-Fatal "Failed to create recovery administrator '$recoveryAdminName'."
    }
}

try {
    $recoveryMembership = Ensure-AdministratorsMembership -AccountName $recoveryAdminName
}
catch {
    Exit-Fatal "Failed to ensure Administrators membership for '$recoveryAdminName'."
}

$recoveryAdmin = Get-LocalUserSafe -Name $recoveryAdminName
if ($recoveryAdmin -and $recoveryAdmin.Enabled) {
    try {
        Disable-LocalUser -Name $recoveryAdminName -ErrorAction Stop
        if ($recoveryAction -eq "unchanged") {
            $recoveryAction = "disabled"
        }
        else {
            $recoveryAction = "$recoveryAction+disabled"
        }
    }
    catch {
        Exit-Fatal "Failed to disable recovery administrator '$recoveryAdminName'."
    }
}

Write-Section "Verify: Administrators group membership"

$administratorsMembers = @()
try {
    $administratorsMembers = @(
        Get-LocalGroupMember -Group $administratorsGroupName -ErrorAction Stop |
            Sort-Object Name |
            ForEach-Object {
                Write-Info "Administrator member: $($_.Name)"
                [string]$_.Name
            }
    )
}
catch {
    $warningMessage = "Unable to enumerate Administrators group membership."
    Write-WarnFlagged $warningMessage
    Add-BoringAdminApplyWarning $warningMessage
    Register-BoringAdminApplyResultState -Result "manual-verification-required"
}

$unexpectedAdminMembers = @(
    $administratorsMembers | Where-Object {
        $memberName = $_
        -not ($expectedManagedAccounts | Where-Object { $memberName -imatch ("(^|\\){0}$" -f [regex]::Escape($_)) })
    }
)

if ($unexpectedAdminMembers.Count -gt 0) {
    $warningMessage = "Unexpected administrator membership remains. Review before treating the identity baseline as complete."
    Write-WarnFlagged $warningMessage
    Add-BoringAdminApplyWarning $warningMessage
    Register-BoringAdminApplyResultState -Result "manual-verification-required"
}

Add-BoringAdminApplyDetail -Name "administrators_group" -Value $administratorsGroupName
Add-BoringAdminApplyDetail -Name "managed_accounts" -Value @(
    [pscustomobject]@{
        name             = $primaryAdminName
        expectedEnabled  = $true
        action           = $primaryAction
        groupMembership  = $primaryMembership
    },
    [pscustomobject]@{
        name             = $recoveryAdminName
        expectedEnabled  = $false
        action           = $recoveryAction
        groupMembership  = $recoveryMembership
    }
)
Add-BoringAdminApplyDetail -Name "unexpected_admin_members" -Value @($unexpectedAdminMembers)

Write-Section "Intentional non-actions"
Write-Info "No Microsoft or cloud identities were modified"
Write-Info "No regular user accounts were altered"
Write-Info "No passwords were rotated automatically"
Write-Info "No account lockout or authentication policies were changed"

Write-Section "Summary"
Write-Info "Local administrator model enforcement completed."
Write-BoringAdminApplyResult
Exit-Warn
