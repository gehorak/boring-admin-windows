# ============================================================================
# core/lib/software-inventory.ps1
#
# PURPOSE
# -------
# Provide bounded, locale-safe package inventory helpers for the public
# plan/check paths and the write-capable software overlay.
#
# This helper intentionally prefers "unknown" over a locale-dependent
# false "missing" result when package-manager output cannot be trusted.
# ============================================================================

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

function ConvertTo-BoringAdminChocolateyPackageState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $PackageId,

        [string] $ExpectedVersion,

        [AllowNull()]
        [string] $Output,

        [Parameter(Mandatory)]
        [int] $ExitCode
    )

    $normalizedOutput = if ($null -eq $Output) { "" } else { ($Output -replace "`r", "").Trim() }

    if ($ExitCode -ne 0) {
        return [pscustomobject]@{
            Success = $false
            State   = "unknown"
            Version = $null
            Error   = "Chocolatey inventory query failed with exit code $ExitCode."
            Source  = "choco"
        }
    }

    foreach ($line in ($normalizedOutput -split "`n")) {
        $trimmedLine = $line.Trim()
        if ($trimmedLine -match ('^{0}\|(?<version>.+)$' -f [regex]::Escape($PackageId))) {
            $version = $Matches["version"].Trim()
            $state = if ($ExpectedVersion -and $version -ne $ExpectedVersion) { "version-drift" } else { "present" }
            return [pscustomobject]@{
                Success = $true
                State   = $state
                Version = $version
                Error   = $null
                Source  = "choco"
            }
        }
    }

    return [pscustomobject]@{
        Success = $true
        State   = "missing"
        Version = $null
        Error   = $null
        Source  = "choco"
    }
}

function ConvertTo-BoringAdminWinGetPackageState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $PackageId,

        [string] $ExpectedVersion,

        [AllowNull()]
        [string] $Output,

        [Parameter(Mandatory)]
        [int] $ExitCode
    )

    $normalizedOutput = if ($null -eq $Output) { "" } else { ($Output -replace "`r", "").Trim() }
    $lines = @($normalizedOutput -split "`n" | ForEach-Object { $_.TrimEnd() })
    $nonEmptyLines = @($lines | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

    if ($ExitCode -ne 0) {
        return [pscustomobject]@{
            Success = $false
            State   = "unknown"
            Version = $null
            Error   = "WinGet inventory query failed with exit code $ExitCode."
            Source  = "winget"
        }
    }

    $parsedRows = [System.Collections.Generic.List[object]]::new()
    foreach ($line in $nonEmptyLines) {
        if ($line -match '^(?<name>.+?)\s{2,}(?<id>\S+)\s{2,}(?<version>\S+)(?:\s{2,}.+)?$') {
            $parsedRows.Add([pscustomobject]@{
                Name    = $Matches["name"].Trim()
                Id      = $Matches["id"].Trim()
                Version = $Matches["version"].Trim()
            }) | Out-Null
        }
    }

    $matchingRow = @($parsedRows | Where-Object { $_.Id -eq $PackageId } | Select-Object -First 1)
    if ($matchingRow.Count -eq 1) {
        $version = $matchingRow[0].Version
        $state = if ($ExpectedVersion -and $version -ne $ExpectedVersion) { "version-drift" } else { "present" }
        return [pscustomobject]@{
            Success = $true
            State   = $state
            Version = $version
            Error   = $null
            Source  = "winget"
        }
    }

    $separatorPresent = $false
    for ($index = 0; $index -lt $nonEmptyLines.Count; $index++) {
        if ($nonEmptyLines[$index] -match '^(?:-{3,}|\s*-{3,}(?:\s+-{3,})+\s*)$') {
            $separatorPresent = $true
            $rowsAfterSeparator = @()
            if ($index -lt ($nonEmptyLines.Count - 1)) {
                $rowsAfterSeparator = @($nonEmptyLines[($index + 1)..($nonEmptyLines.Count - 1)] | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
            }

            if ($rowsAfterSeparator.Count -eq 0) {
                return [pscustomobject]@{
                    Success = $true
                    State   = "missing"
                    Version = $null
                    Error   = $null
                    Source  = "winget"
                }
            }

            break
        }
    }

    if ($nonEmptyLines.Count -eq 0) {
        return [pscustomobject]@{
            Success = $true
            State   = "missing"
            Version = $null
            Error   = $null
            Source  = "winget"
        }
    }

    return [pscustomobject]@{
        Success = $false
        State   = "unknown"
        Version = $null
        Error   = if ($separatorPresent) {
            "WinGet inventory output could not be parsed safely."
        }
        else {
            "WinGet inventory output is not trustworthy for locale-safe package absence detection."
        }
        Source  = "winget"
    }
}

function Get-BoringAdminPackagePreflightDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject] $Package,

        [Parameter(Mandatory)]
        [psobject] $ObservedState
    )

    $state = [string]$ObservedState.State
    if (-not [bool]$ObservedState.Success -or $state -eq "unknown") {
        $warningDetail = if ([string]$ObservedState.Error) {
            " Details: $([string]$ObservedState.Error)"
        }
        else {
            ""
        }

        return [pscustomobject]@{
            BlockInstall          = $true
            Status                = "blocked"
            FailureReason         = "precheck-state-unknown"
            FailureClassification = if ([bool]$Package.required) { "required" } else { "optional" }
            WarningMessage        = "Package '$([string]$Package.id)' could not be safely verified before install.$warningDetail"
        }
    }

    return [pscustomobject]@{
        BlockInstall          = $false
        Status                = if ($state -eq "present") { "present" } else { "install-needed" }
        FailureReason         = $null
        FailureClassification = "none"
        WarningMessage        = $null
    }
}

function Get-BoringAdminChocolateyPackageState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $PackageId,

        [string] $ExpectedVersion
    )

    $output = & choco.exe list --local-only --exact --limit-output $PackageId 2>&1 | Out-String
    return ConvertTo-BoringAdminChocolateyPackageState -PackageId $PackageId -ExpectedVersion $ExpectedVersion -Output $output -ExitCode $LASTEXITCODE
}

function Get-BoringAdminWinGetPackageState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $PackageId,

        [string] $ExpectedVersion
    )

    $output = & winget.exe list --id $PackageId --exact --accept-source-agreements 2>&1 | Out-String
    return ConvertTo-BoringAdminWinGetPackageState -PackageId $PackageId -ExpectedVersion $ExpectedVersion -Output $output -ExitCode $LASTEXITCODE
}
