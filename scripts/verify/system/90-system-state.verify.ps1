# ============================================================================
# 90-system-state.verify.ps1
#
# PURPOSE
# -------
# Provide a fast, read-only audit of the current system state
# to verify whether the intended Windows 11 (SMB / non-domain)
# design and lifecycle assumptions are still intact.
#
# This script reports observable facts and highlights
# deviations from the declared architecture.
#
# LIFECYCLE
# ---------
# Stage: 90–99 — Audit & Reporting
#
# AUDIT SCOPE
# -----------
# - OS version and domain join state
# - local administrator exposure
# - security baseline indicators (Defender, Firewall, BitLocker)
# - bootstrap / debloat policy markers
# - software delivery indicators (Chocolatey presence)
# - temporary access account presence
#
# OUTPUT GOAL
# -----------
# - one-screen, human-readable output
# - actionable WARN signals
# - no hidden interpretation or remediation
#
# SAFETY
# ------
# - Read-only execution
# - Makes NO changes to system state
# - No remediation or enforcement
# - No reboot
#
# MODE
# ----
# VERIFY
# - Safe to run repeatedly
# - Safe to run during incidents
# - Safe to run on unknown systems
#
# NON-GOALS
# ---------
# - system configuration or remediation
# - automatic fixing of detected issues
# - policy enforcement or hardening
#
# CONTRACT
# --------
# This script follows docs/ARCHITECTURE.md
# and the lifecycle model defined in docs/ARCHITECTURE.md
# ============================================================================

[CmdletBinding()]
param(
    [ValidateSet("Text", "Json")]
    [string] $OutputFormat = "Text"
)


# -----------------------------------------------------------------------------
# Bootstrap
# -----------------------------------------------------------------------------

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
$identitySettings = Get-BoringAdminIdentitySettings -Config $config
$administratorsGroupName = Get-BoringAdminAdministratorsGroupName

function Add-SystemWarning {
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

$osInfo = $null
$computerSystem = $null
$adminMembers = @()
$defender = [pscustomobject]@{
    serviceRunning      = $null
    antivirusEnabled    = $null
    realTimeProtection  = $null
}
$firewallProfiles = @()
$bitLockerVolumes = @()
$policyMarkers = @()
$chocolateyPresent = $false
$temporaryGuestPresent = $false

# ---------------------------------------------------------------------------
# 1) OS & domain state
# ---------------------------------------------------------------------------

try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop

    $osInfo = [pscustomobject]@{
        caption = $os.Caption
        version = $os.Version
    }

    $computerSystem = [pscustomobject]@{
        computerName = $cs.Name
        partOfDomain = [bool]$cs.PartOfDomain
    }

    if ($cs.PartOfDomain) {
        Add-SystemWarning "System is domain-joined. This deviates from the design."
    }
}
catch {
    Add-SystemWarning "Unable to query OS or domain join state."
}

# ---------------------------------------------------------------------------
# 2) Local administrators exposure
# ---------------------------------------------------------------------------

try {
    $admins = @(Get-LocalGroupMember -Group $administratorsGroupName -ErrorAction Stop)
    $adminMembers = @(
        $admins | ForEach-Object {
            [pscustomobject]@{
                name = $_.Name
            }
        }
    )

    $expectedAdminPatterns = @(
        "(^|\\){0}$" -f [regex]::Escape($identitySettings.primaryAdminName),
        "(^|\\){0}$" -f [regex]::Escape($identitySettings.recoveryAdminName)
    )

    $unexpectedAdmins = @(
        $admins | Where-Object {
            $memberName = $_.Name
            -not ($expectedAdminPatterns | Where-Object { $memberName -imatch $_ })
        }
    )

    if ($unexpectedAdmins.Count -gt 0) {
        Add-SystemWarning "Unexpected admin accounts detected. Review required."
    }
}
catch {
    Add-SystemWarning "Unable to enumerate local Administrators group membership."
}

# ---------------------------------------------------------------------------
# 3) Windows Defender status
# ---------------------------------------------------------------------------

try {
    $svc = Get-Service -Name WinDefend -ErrorAction SilentlyContinue
    $defender.serviceRunning = [bool]($svc -and $svc.Status -eq "Running")

    if (-not $defender.serviceRunning) {
        Add-SystemWarning "Windows Defender service is not running."
    }
    else {
        $mp = Try-GetMpComputerStatus -TimeoutSec 5

        if (-not $mp) {
            Add-SystemWarning "Defender status unavailable (timeout)."
        }
        else {
            $defender.antivirusEnabled = [bool]$mp.AntivirusEnabled
            $defender.realTimeProtection = [bool]$mp.RealTimeProtectionEnabled

            if (-not $mp.AntivirusEnabled -or -not $mp.RealTimeProtectionEnabled) {
                Add-SystemWarning "Defender is not fully enabled. Manual investigation required."
            }
        }
    }
}
catch {
    Add-SystemWarning "Unable to query Defender status."
}

# ---------------------------------------------------------------------------
# 4) Firewall status
# ---------------------------------------------------------------------------

try {
    $firewallProfiles = @(
        Get-NetFirewallProfile -ErrorAction Stop | ForEach-Object {
            if (-not $_.Enabled) {
                Add-SystemWarning "Firewall profile '$($_.Name)' is disabled."
            }

            [pscustomobject]@{
                name    = $_.Name
                enabled = [bool]$_.Enabled
            }
        }
    )
}
catch {
    Add-SystemWarning "Unable to query firewall profiles."
}

# ---------------------------------------------------------------------------
# 5) BitLocker status
# ---------------------------------------------------------------------------

try {
    $bitLockerVolumes = @(
        Get-BitLockerVolume -ErrorAction Stop | ForEach-Object {
            if ($_.ProtectionStatus -ne 1) {
                Add-SystemWarning "BitLocker NOT enabled on $($_.MountPoint)"
            }

            [pscustomobject]@{
                mountPoint       = $_.MountPoint
                protectionStatus = $_.ProtectionStatus
            }
        }
    )
}
catch {
    Add-SystemWarning "BitLocker status not available."
}

# ---------------------------------------------------------------------------
# 6) Mini-debloat markers (policy presence)
# ---------------------------------------------------------------------------

$checks = @(
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"; Name = "DisableConsumerFeatures" },
    @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"; Name = "AllowNewsAndInterests" }
)

foreach ($check in $checks) {
    $property = Get-ItemProperty -Path $check.Path -Name $check.Name -ErrorAction SilentlyContinue
    $present = ($null -ne $property)

    if (-not $present) {
        Add-SystemWarning "Missing policy: $($check.Path)\$($check.Name)"
    }

    $policyMarkers += [pscustomobject]@{
        path    = $check.Path
        name    = $check.Name
        present = $present
    }
}

# ---------------------------------------------------------------------------
# 7) Chocolatey presence
# ---------------------------------------------------------------------------

$chocolateyPresent = [bool](Get-Command choco.exe -ErrorAction SilentlyContinue)

# ---------------------------------------------------------------------------
# 8) Temporary guest account presence
# ---------------------------------------------------------------------------

$temporaryGuestPresent = [bool](Get-LocalUser -Name $identitySettings.temporaryAccessUserName -ErrorAction SilentlyContinue)
if ($temporaryGuestPresent) {
    Add-SystemWarning ("Temporary access account '{0}' EXISTS. Remove if no longer needed." -f $identitySettings.temporaryAccessUserName)
}

$result = [pscustomobject]@{
    scope       = "system-state"
    generatedAt = Get-Rfc3339Timestamp
    system      = [pscustomobject]@{
        os              = $osInfo
        computer        = $computerSystem
        administrators  = @($adminMembers)
        defender        = $defender
        firewall        = @($firewallProfiles)
        bitLocker       = @($bitLockerVolumes)
        policyMarkers   = @($policyMarkers)
        chocolatey      = [pscustomobject]@{ present = $chocolateyPresent }
        temporaryAccessAccount = [pscustomobject]@{ present = $temporaryGuestPresent }
    }
    warnings    = @($warnings)
}

if ($OutputFormat -eq "Json") {
    $result | ConvertTo-Json -Depth 7
    Exit-Warn
}

Write-Section "System Audit (Read-Only)"

Write-Section "OS & Join State"
if ($osInfo) {
    Write-Info "OS: $($osInfo.caption) ($($osInfo.version))"
}
if ($computerSystem) {
    Write-Info "Computer name: $($computerSystem.computerName)"
    Write-Info "Domain joined: $($computerSystem.partOfDomain)"
}

Write-Section "Local Administrators"
foreach ($admin in $adminMembers) {
    Write-Info "Admin member: $($admin.name)"
}

Write-Section "Verify: Windows Defender"
if ($null -ne $defender.antivirusEnabled) {
    Write-Info "Antivirus enabled: $($defender.antivirusEnabled)"
}
if ($null -ne $defender.realTimeProtection) {
    Write-Info "Real-time protection: $($defender.realTimeProtection)"
}

Write-Section "Windows Firewall"
foreach ($firewallProfile in $firewallProfiles) {
    Write-Info "Profile [$($firewallProfile.name)] enabled: $($firewallProfile.enabled)"
}

Write-Section "BitLocker"
foreach ($volume in $bitLockerVolumes) {
    Write-Info "Volume $($volume.mountPoint): ProtectionStatus = $($volume.protectionStatus)"
}

Write-Section "Debloat Policy Markers"
foreach ($marker in $policyMarkers) {
    if ($marker.present) {
        Write-Info "Policy OK: $($marker.path)\$($marker.name)"
    }
}

Write-Section "Chocolatey"
if ($chocolateyPresent) {
    Write-Info "Chocolatey installed."
}

Write-Section "Temporary Access Account"
if (-not $temporaryGuestPresent) {
    Write-Info "No temporary guest account present."
}
else {
    Write-Info ("Temporary access account '{0}' is present." -f $identitySettings.temporaryAccessUserName)
}

Write-Section "Audit Summary"
Write-Info "Audit completed."
Write-Info "Review WARNINGS above. No automatic remediation performed."

Exit-Warn
