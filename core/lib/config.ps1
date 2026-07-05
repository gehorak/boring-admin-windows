Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$script:BoringAdminRepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$script:BoringAdminProfileSchemaVersion = "2"
$script:BoringAdminProfileTypes = @("sample", "example", "local")
$script:BoringAdminPackageClasses = @("baseline", "ux", "network", "remoteAccess", "adminSpecial")
$script:BoringAdminPackageManagers = @("choco", "winget")
$script:BoringAdminReservedLocalAccountNames = @("Administrator", "Guest", "DefaultAccount", "WDAGUtilityAccount")

function Get-BoringAdminRepositoryRoot {
    return $script:BoringAdminRepositoryRoot
}

function Get-BoringAdminDefaultLocalProfilePath {
    return Join-Path (Get-BoringAdminRepositoryRoot) "config\profiles\individual.local.json"
}

function Get-BoringAdminPublicSampleProfilePath {
    return Join-Path (Get-BoringAdminRepositoryRoot) "config\profiles\individual.example.json"
}

function Resolve-BoringAdminCandidatePath {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path (Get-BoringAdminRepositoryRoot) $Path))
}

function Resolve-BoringAdminProfilePath {
    [CmdletBinding()]
    param(
        [string] $ProfilePath
    )

    if ($ProfilePath) {
        $resolved = Resolve-BoringAdminCandidatePath -Path $ProfilePath
        if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
            throw [System.InvalidOperationException]::new("Profile not found: $resolved")
        }

        return $resolved
    }

    if ($env:BORING_ADMIN_PROFILE) {
        $resolved = Resolve-BoringAdminCandidatePath -Path $env:BORING_ADMIN_PROFILE
        if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
            throw [System.InvalidOperationException]::new("BORING_ADMIN_PROFILE points to a missing profile: $resolved")
        }

        return $resolved
    }

    $localProfile = Get-BoringAdminDefaultLocalProfilePath
    if (Test-Path -LiteralPath $localProfile -PathType Leaf) {
        return $localProfile
    }

    $sampleProfile = Get-BoringAdminPublicSampleProfilePath
    if (Test-Path -LiteralPath $sampleProfile -PathType Leaf) {
        return $sampleProfile
    }

    throw [System.InvalidOperationException]::new(
        "No configuration profile found. Create config/profiles/individual.local.json from config/profiles/individual.example.json or set BORING_ADMIN_PROFILE."
    )
}

function Get-BoringAdminConfigValue {
    param(
        [Parameter(Mandatory)]
        [psobject] $Config,

        [Parameter(Mandatory)]
        [string] $Path
    )

    $current = $Config

    foreach ($segment in ($Path -split '\.')) {
        if ($null -eq $current) {
            return $null
        }

        $property = $current.PSObject.Properties[$segment]
        if (-not $property) {
            return $null
        }

        $current = $property.Value
    }

    return $current
}

function Test-BoringAdminConfigPathExists {
    param(
        [Parameter(Mandatory)]
        [psobject] $Config,

        [Parameter(Mandatory)]
        [string] $Path
    )

    $current = $Config
    $segments = $Path -split '\.'

    for ($index = 0; $index -lt $segments.Count; $index++) {
        if ($null -eq $current) {
            return $false
        }

        $property = $current.PSObject.Properties[$segments[$index]]
        if (-not $property) {
            return $false
        }

        if ($index -eq ($segments.Count - 1)) {
            return $true
        }

        $current = $property.Value
    }

    return $false
}

function Assert-BoringAdminRequiredString {
    param(
        [Parameter(Mandatory)]
        [psobject] $Config,

        [Parameter(Mandatory)]
        [string] $Path
    )

    $value = Get-BoringAdminConfigValue -Config $Config -Path $Path
    if ([string]::IsNullOrWhiteSpace([string]$value)) {
        throw [System.InvalidOperationException]::new("Profile validation failed. Missing or empty string: $Path")
    }
}

function Assert-BoringAdminStringArray {
    param(
        [Parameter(Mandatory)]
        [psobject] $Config,

        [Parameter(Mandatory)]
        [string] $Path
    )

    $value = Get-BoringAdminConfigValue -Config $Config -Path $Path
    if (-not (Test-BoringAdminConfigPathExists -Config $Config -Path $Path)) {
        throw [System.InvalidOperationException]::new("Profile validation failed. Missing array: $Path")
    }

    $items = if ($null -eq $value) { @() } else { @($value) }
    foreach ($item in $items) {
        if ([string]::IsNullOrWhiteSpace([string]$item)) {
            throw [System.InvalidOperationException]::new("Profile validation failed. Array '$Path' contains an empty value.")
        }
    }
}

function Test-BoringAdminPackageSourceValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("choco", "winget")]
        [string] $PackageManager,

        [Parameter(Mandatory)]
        [string] $Source
    )

    $trimmedSource = [string]$Source
    if ([string]::IsNullOrWhiteSpace($trimmedSource)) {
        return $false
    }

    switch ($PackageManager) {
        "choco" {
            if ($trimmedSource -match '^https://\S+$') {
                return $true
            }

            if ($trimmedSource -match '^[A-Za-z]:[\\/]') {
                return $true
            }

            if ($trimmedSource -match '^\\\\[^\\\/]+\\[^\\\/]+(?:[\\\/].*)?$') {
                return $true
            }

            if ($trimmedSource -match '^[A-Za-z0-9._-]+$') {
                return $true
            }

            return $false
        }
        "winget" {
            return $trimmedSource -match '^[A-Za-z0-9._-]+$'
        }
    }
}

function Get-BoringAdminPackageSourcePolicyDescription {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("choco", "winget")]
        [string] $PackageManager
    )

    switch ($PackageManager) {
        "choco" {
            return "Chocolatey package sources must be one explicit HTTPS repository URL, absolute local path, UNC path, or configured source alias."
        }
        "winget" {
            return "WinGet package sources must be one explicit source identifier such as 'winget' or 'msstore'."
        }
    }
}

function Assert-BoringAdminPackageSourceValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("choco", "winget")]
        [string] $PackageManager,

        [Parameter(Mandatory)]
        [string] $Source,

        [Parameter(Mandatory)]
        [string] $Path
    )

    if (Test-BoringAdminPackageSourceValue -PackageManager $PackageManager -Source $Source) {
        return
    }

    $policyDescription = Get-BoringAdminPackageSourcePolicyDescription -PackageManager $PackageManager
    throw [System.InvalidOperationException]::new(
        "Profile validation failed. Package '$Path' has unsupported source '$Source' for package manager '$PackageManager'. $policyDescription"
    )
}

function Assert-BoringAdminPackageEntryArray {
    param(
        [Parameter(Mandatory)]
        [psobject] $Config,

        [Parameter(Mandatory)]
        [ValidateSet("choco", "winget")]
        [string] $PackageManager,

        [Parameter(Mandatory)]
        [string] $Path
    )

    $value = Get-BoringAdminConfigValue -Config $Config -Path $Path
    if (-not (Test-BoringAdminConfigPathExists -Config $Config -Path $Path)) {
        throw [System.InvalidOperationException]::new("Profile validation failed. Missing package array: $Path")
    }

    $packages = if ($null -eq $value) { @() } else { @($value) }
    foreach ($package in $packages) {
        if ($null -eq $package) {
            throw [System.InvalidOperationException]::new("Profile validation failed. Package array '$Path' contains a null entry.")
        }

        foreach ($fieldName in @("id", "version", "source", "reviewedPublisher")) {
            $fieldValue = $package.PSObject.Properties[$fieldName]
            if (-not $fieldValue -or [string]::IsNullOrWhiteSpace([string]$fieldValue.Value)) {
                throw [System.InvalidOperationException]::new("Profile validation failed. Package '$Path' is missing required string field '$fieldName'.")
            }
        }

        Assert-BoringAdminPackageSourceValue -PackageManager $PackageManager -Source ([string]$package.source) -Path $Path

        $requiredProperty = $package.PSObject.Properties["required"]
        if (-not $requiredProperty) {
            throw [System.InvalidOperationException]::new("Profile validation failed. Package '$Path' is missing required boolean field 'required'.")
        }

        if ($requiredProperty.Value -isnot [bool]) {
            throw [System.InvalidOperationException]::new("Profile validation failed. Package '$Path' field 'required' must be a boolean.")
        }
    }
}

function Test-BoringAdminLocalAccountNameValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Name
    )

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return $false
    }

    $trimmedName = [string]$Name
    if ($trimmedName -ne $trimmedName.Trim()) {
        return $false
    }

    if ($trimmedName.Length -gt 20) {
        return $false
    }

    if ($trimmedName.EndsWith(".") -or $trimmedName.EndsWith(" ")) {
        return $false
    }

    if ($trimmedName -match '[\"\/\\\[\]:;|=,\+\*\?<>\x00-\x1F]') {
        return $false
    }

    return $true
}

function Test-BoringAdminReservedLocalAccountName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Name
    )

    return @($script:BoringAdminReservedLocalAccountNames | Where-Object { $_ -ieq $Name }).Count -gt 0
}

function Assert-BoringAdminManagedAccountNames {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject] $Config
    )

    $accounts = [ordered]@{
        "accounts.primaryAdminName"        = [string]$Config.accounts.primaryAdminName
        "accounts.recoveryAdminName"       = [string]$Config.accounts.recoveryAdminName
        "accounts.temporaryAccessUserName" = [string]$Config.accounts.temporaryAccessUserName
    }

    $seenNames = @{}
    foreach ($accountEntry in $accounts.GetEnumerator()) {
        $accountName = $accountEntry.Value
        if (-not (Test-BoringAdminLocalAccountNameValue -Name $accountName)) {
            throw [System.InvalidOperationException]::new(
                "Profile validation failed. $($accountEntry.Key) has invalid local account name '$accountName'. Managed local account names must be trimmed, at most 20 characters, must not end with '.' or space, and must not contain Windows-reserved punctuation."
            )
        }

        if (Test-BoringAdminReservedLocalAccountName -Name $accountName) {
            throw [System.InvalidOperationException]::new(
                "Profile validation failed. $($accountEntry.Key) uses reserved built-in Windows account name '$accountName'. Choose a managed account name that does not collide with built-in local accounts."
            )
        }

        $normalizedName = $accountName.ToUpperInvariant()
        if ($seenNames.ContainsKey($normalizedName)) {
            throw [System.InvalidOperationException]::new(
                "Profile validation failed. Managed account names must be unique. $($accountEntry.Key) duplicates $($seenNames[$normalizedName]) with value '$accountName'."
            )
        }

        $seenNames[$normalizedName] = $accountEntry.Key
    }
}

function Test-BoringAdminComputerNameValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ComputerName
    )

    if ([string]::IsNullOrWhiteSpace($ComputerName)) {
        return $false
    }

    $trimmedName = [string]$ComputerName
    if ($trimmedName -ne $trimmedName.Trim()) {
        return $false
    }

    if ($trimmedName.Length -gt 15) {
        return $false
    }

    if ($trimmedName.StartsWith("-") -or $trimmedName.EndsWith("-")) {
        return $false
    }

    return $trimmedName -match '^[A-Za-z0-9-]+$'
}

function Assert-BoringAdminComputerNameValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ComputerName
    )

    if (Test-BoringAdminComputerNameValue -ComputerName $ComputerName) {
        return
    }

    throw [System.InvalidOperationException]::new(
        "Profile validation failed. hostIdentity.computerName '$ComputerName' must be a trimmed Windows workstation name up to 15 characters using only letters, digits, and hyphen."
    )
}

function Test-BoringAdminTimeZoneValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $TimeZone
    )

    try {
        return @(Get-TimeZone -ListAvailable | Where-Object { $_.Id -eq $TimeZone }).Count -gt 0
    }
    catch {
        return $false
    }
}

function Assert-BoringAdminTimeZoneValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $TimeZone
    )

    if (Test-BoringAdminTimeZoneValue -TimeZone $TimeZone) {
        return
    }

    throw [System.InvalidOperationException]::new(
        "Profile validation failed. hostIdentity.timeZone '$TimeZone' is not a valid local Windows time zone identifier."
    )
}

function Test-BoringAdminSystemLocaleValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $SystemLocale
    )

    try {
        $matchingCultures = @(
            [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures) |
                Where-Object { $_.Name -ceq $SystemLocale }
        )
        if ($matchingCultures.Count -eq 0) {
            return $false
        }

        $languageList = @(New-WinUserLanguageList -Language $SystemLocale)
        return $languageList.Count -gt 0
    }
    catch {
        return $false
    }
}

function Assert-BoringAdminSystemLocaleValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $SystemLocale
    )

    if (Test-BoringAdminSystemLocaleValue -SystemLocale $SystemLocale) {
        return
    }

    throw [System.InvalidOperationException]::new(
        "Profile validation failed. hostIdentity.systemLocale '$SystemLocale' is not a valid local Windows language tag."
    )
}

function Assert-BoringAdminConfigShape {
    param(
        [Parameter(Mandatory)]
        [psobject] $Config
    )

    $schemaVersion = [string](Get-BoringAdminConfigValue -Config $Config -Path "schemaVersion")
    if ($schemaVersion -ne $script:BoringAdminProfileSchemaVersion) {
        if ($schemaVersion -eq "1") {
            throw [System.InvalidOperationException]::new(
                "Profile schemaVersion '1' is no longer supported. Migrate to schemaVersion '2' by setting software.packageManager and replacing per-manager package string arrays with package objects that include id, version, source, reviewedPublisher, and required."
            )
        }

        throw [System.InvalidOperationException]::new(
            "Unsupported profile schemaVersion '$schemaVersion'. Supported value: $($script:BoringAdminProfileSchemaVersion)."
        )
    }

    foreach ($path in @(
        "schemaVersion",
        "profileName",
        "profileType",
        "hostIdentity.computerName",
        "hostIdentity.timeZone",
        "hostIdentity.systemLocale",
        "accounts.primaryAdminName",
        "accounts.recoveryAdminName",
        "accounts.temporaryAccessUserName",
        "accounts.temporaryAccessDescription"
    )) {
        Assert-BoringAdminRequiredString -Config $Config -Path $path
    }

    if ($Config.profileType -notin $script:BoringAdminProfileTypes) {
        throw [System.InvalidOperationException]::new(
            "Profile validation failed. profileType must be one of: $($script:BoringAdminProfileTypes -join ', ')"
        )
    }

    Assert-BoringAdminRequiredString -Config $Config -Path "software.packageManager"

    if ($Config.software.packageManager -notin $script:BoringAdminPackageManagers) {
        throw [System.InvalidOperationException]::new(
            "Profile validation failed. software.packageManager must be one of: $($script:BoringAdminPackageManagers -join ', ')"
        )
    }

    Assert-BoringAdminManagedAccountNames -Config $Config
    Assert-BoringAdminComputerNameValue -ComputerName ([string]$Config.hostIdentity.computerName)
    Assert-BoringAdminTimeZoneValue -TimeZone ([string]$Config.hostIdentity.timeZone)
    Assert-BoringAdminSystemLocaleValue -SystemLocale ([string]$Config.hostIdentity.systemLocale)

    foreach ($packageClass in $script:BoringAdminPackageClasses) {
        Assert-BoringAdminPackageEntryArray -Config $Config -PackageManager $Config.software.packageManager -Path ("software.{0}" -f $packageClass)
    }
}

function Import-BoringAdminConfig {
    [CmdletBinding()]
    param(
        [string] $ProfilePath
    )

    $resolvedPath = Resolve-BoringAdminProfilePath -ProfilePath $ProfilePath

    try {
        $config = Get-Content -Raw -LiteralPath $resolvedPath | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw [System.InvalidOperationException]::new("Unable to parse profile JSON: $resolvedPath")
    }

    Assert-BoringAdminConfigShape -Config $config

    $config | Add-Member -NotePropertyName resolvedProfilePath -NotePropertyValue $resolvedPath -Force
    return $config
}

function Import-BoringAdminConfigOrFail {
    [CmdletBinding()]
    param(
        [string] $ProfilePath
    )

    try {
        return Import-BoringAdminConfig -ProfilePath $ProfilePath
    }
    catch {
        if (Get-Command Exit-Fatal -ErrorAction SilentlyContinue) {
            Exit-Fatal $_.Exception.Message
        }

        throw
    }
}

function Assert-BoringAdminWritableProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject] $Config,

        [string] $Operation = "This action"
    )

    if ($Config.profileType -ne "local") {
        throw [System.InvalidOperationException]::new(
            "$Operation requires a local profile. Copy config/profiles/individual.example.json to config/profiles/individual.local.json or set BORING_ADMIN_PROFILE to a local profile."
        )
    }
}

function Get-BoringAdminIdentitySettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject] $Config
    )

    return [pscustomobject]@{
        primaryAdminName         = [string]$Config.accounts.primaryAdminName
        recoveryAdminName        = [string]$Config.accounts.recoveryAdminName
        temporaryAccessUserName  = [string]$Config.accounts.temporaryAccessUserName
        temporaryAccessDescription = [string]$Config.accounts.temporaryAccessDescription
    }
}

function Get-BoringAdminManagedAccountNames {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject] $Config
    )

    $identity = Get-BoringAdminIdentitySettings -Config $Config
    return @(
        $identity.primaryAdminName,
        $identity.recoveryAdminName,
        $identity.temporaryAccessUserName
    )
}

function Get-BoringAdminHostIdentitySettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject] $Config
    )

    return [pscustomobject]@{
        computerName = [string]$Config.hostIdentity.computerName
        timeZone     = [string]$Config.hostIdentity.timeZone
        systemLocale = [string]$Config.hostIdentity.systemLocale
    }
}

function Get-BoringAdminSoftwarePackageList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject] $Config,

        [Parameter(Mandatory)]
        [ValidateSet("baseline", "ux", "network", "remoteAccess", "adminSpecial")]
        [string] $PackageClass,

        [ValidateSet("choco", "winget")]
        [string] $PackageManager
    )

    $activeManager = [string]$Config.software.packageManager
    if ($PackageManager -and $PackageManager -ne $activeManager) {
        throw [System.InvalidOperationException]::new(
            "Profile validation failed. software.packageManager is '$activeManager', so class '$PackageClass' cannot be requested through '$PackageManager'."
        )
    }

    $path = "software.{0}" -f $PackageClass
    $packages = Get-BoringAdminConfigValue -Config $Config -Path $path
    if (-not (Test-BoringAdminConfigPathExists -Config $Config -Path $path)) {
        throw [System.InvalidOperationException]::new(
            "Profile validation failed. Missing software package list for $PackageClass."
        )
    }

    if ($null -eq $packages) {
        return @()
    }

    return @(
        $packages | ForEach-Object {
            [pscustomobject]@{
                id                = [string]$_.id
                version           = [string]$_.version
                source            = [string]$_.source
                reviewedPublisher = [string]$_.reviewedPublisher
                required          = [bool]$_.required
                packageManager    = $activeManager
                packageClass      = $PackageClass
            }
        }
    )
}

function Get-BoringAdminSoftwarePackageManager {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject] $Config
    )

    return [string]$Config.software.packageManager
}
