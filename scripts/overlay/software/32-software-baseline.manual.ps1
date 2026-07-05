# ============================================================================
# 32-software-baseline.manual.ps1
#
# PURPOSE
# -------
# Apply the profile-defined software baseline through the active package
# manager with explicit package identity, version, source, and reviewed
# publisher metadata.
#
# This script is the public write-capable software path used by
# boring-admin.ps1 apply software.
#
# CONTRACT
# --------
# This script follows docs/ARCHITECTURE.md
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
. (Join-Path $ProjectRoot "core\lib\software-inventory.ps1")

$script:HadWarnings = $false
$config = Import-BoringAdminConfigOrFail
$null = Initialize-BoringAdminApplyResult -Target "software"

function Invoke-ChocolateyInstall {
    param(
        [Parameter(Mandatory)]
        [psobject] $Package
    )

    $output = & choco.exe install $Package.id --yes --no-progress --limit-output --source $Package.source --version $Package.version 2>&1 | Out-String
    return Get-BoringAdminCommandResult -ExitCode $LASTEXITCODE -Output $output -MaxOutputLength 600
}

function Invoke-WinGetInstall {
    param(
        [Parameter(Mandatory)]
        [psobject] $Package
    )

    $output = & winget.exe install --id $Package.id --exact --version $Package.version --source $Package.source --silent --accept-package-agreements --accept-source-agreements 2>&1 | Out-String
    return Get-BoringAdminCommandResult -ExitCode $LASTEXITCODE -Output $output -MaxOutputLength 600
}

Assert-Administrator
Test-PowerShellVersion | Out-Null

$packageManager = Get-BoringAdminSoftwarePackageManager -Config $config
$baselinePackages = @(Get-BoringAdminSoftwarePackageList -Config $config -PackageClass baseline -PackageManager $packageManager)
$packageResults = [System.Collections.Generic.List[object]]::new()
$optionalFailures = 0

Add-BoringAdminApplyDetail -Name "package_manager" -Value $packageManager
Add-BoringAdminApplyDetail -Name "package_class" -Value "baseline"
Add-BoringAdminApplyDetail -Name "reviewed_publisher_enforcement" -Value "review-metadata-only"

Write-Section "32-software-baseline - Profile Software Baseline"
Write-Info "Active package manager: $packageManager"
Write-Info "Baseline packages declared: $($baselinePackages.Count)"
Write-Info "reviewedPublisher metadata is recorded for operator review only; it is not a cryptographic verification step."

if ($baselinePackages.Count -eq 0) {
    Add-BoringAdminApplyWarning "No baseline packages are defined in the active profile."
    Add-BoringAdminApplyDetail -Name "packages" -Value @()
    Write-BoringAdminApplyResult
    Exit-Warn
}

$transportCommand = switch ($packageManager) {
    "choco" { Get-Command choco.exe -ErrorAction SilentlyContinue }
    "winget" { Get-Command winget.exe -ErrorAction SilentlyContinue }
    default { $null }
}

if (-not $transportCommand) {
    $message = "Configured package manager '$packageManager' is not available in PATH."
    Write-WarnFlagged $message
    Add-BoringAdminApplyWarning $message
    if (@($baselinePackages | Where-Object { $_.required }).Count -gt 0) {
        Register-BoringAdminApplyResultState -Result "partial"
    }
    else {
        Add-BoringAdminApplyDetail -Name "completion_classification" -Value "completed-with-warnings"
    }

    foreach ($package in $baselinePackages) {
        $failureClassification = if ($package.required) { "required" } else { "optional" }
        if ($package.required) {
            Add-BoringAdminApplyFailedItem -Id $package.id -Reason "package-manager-missing" -Classification $package.packageClass -ExpectedVersion $package.version
        }
        else {
            Add-BoringAdminApplyOptionalFailedItem -Id $package.id -Reason "package-manager-missing" -Classification $package.packageClass -ExpectedVersion $package.version
            $optionalFailures++
        }

        $packageResults.Add([pscustomobject]@{
            id                     = $package.id
            packageManager         = $packageManager
            expectedVersion        = $package.version
            observedVersion        = $null
            required               = [bool]$package.required
            source                 = $package.source
            reviewedPublisher      = $package.reviewedPublisher
            status                 = "skipped"
            failure_classification = $failureClassification
            installExitCode        = $null
            installOutputPreview   = ""
        }) | Out-Null
    }

    Add-BoringAdminApplyDetail -Name "packages" -Value @($packageResults)
    Write-BoringAdminApplyResult
    Exit-Warn
}

foreach ($package in $baselinePackages) {
    $observedBeforeState = switch ($packageManager) {
        "choco" { Get-BoringAdminChocolateyPackageState -PackageId $package.id -ExpectedVersion $package.version }
        "winget" { Get-BoringAdminWinGetPackageState -PackageId $package.id -ExpectedVersion $package.version }
    }
    $observedBefore = $observedBeforeState.Version
    $preflightDecision = Get-BoringAdminPackagePreflightDecision -Package $package -ObservedState $observedBeforeState

    $installResult = $null
    $observedAfter = $observedBefore
    $status = "present"
    $failureClassification = "none"

    Write-Info ("Evaluating package {0} -> expected {1} from {2}" -f $package.id, $package.version, $package.source)

    if ($preflightDecision.BlockInstall) {
        $status = $preflightDecision.Status
        $failureClassification = $preflightDecision.FailureClassification

        Write-WarnFlagged $preflightDecision.WarningMessage
        Add-BoringAdminApplyWarning $preflightDecision.WarningMessage

        if ($package.required) {
            Add-BoringAdminApplyFailedItem -Id $package.id -Reason $preflightDecision.FailureReason -Classification $package.packageClass -ExpectedVersion $package.version -ObservedVersion $observedBefore
            Register-BoringAdminApplyResultState -Result "partial"
        }
        else {
            Add-BoringAdminApplyOptionalFailedItem -Id $package.id -Reason $preflightDecision.FailureReason -Classification $package.packageClass -ExpectedVersion $package.version -ObservedVersion $observedBefore
            $optionalFailures++
        }
    }
    elseif ($observedBeforeState.State -eq "present") {
        Write-Info "Package already matches expected version."
        $observedAfter = $observedBefore
    }
    else {
        Write-Info "Installing package through the configured manager."
        $installResult = switch ($packageManager) {
            "choco" { Invoke-ChocolateyInstall -Package $package }
            "winget" { Invoke-WinGetInstall -Package $package }
        }

        $observedAfterState = switch ($packageManager) {
            "choco" { Get-BoringAdminChocolateyPackageState -PackageId $package.id -ExpectedVersion $package.version }
            "winget" { Get-BoringAdminWinGetPackageState -PackageId $package.id -ExpectedVersion $package.version }
        }
        $observedAfter = $observedAfterState.Version

        if ($observedAfterState.State -eq "present") {
            $status = "installed"
            Write-Info "Package matches expected version after install."
        }
        else {
            $status = "failed"
            $installExitCode = if ($installResult) { [int]$installResult.ExitCode } else { $null }
            $reason = if ($null -ne $installExitCode -and $installExitCode -ne 0) {
                "install-exit-code-$installExitCode"
            }
            else {
                "version-verification-failed"
            }
            if ($observedAfterState.Error) {
                Add-BoringAdminApplyWarning ("Package '{0}' post-install verification is incomplete: {1}" -f $package.id, $observedAfterState.Error)
            }

            $failureClassification = if ($package.required) { "required" } else { "optional" }
            $warningMessage = if ($package.required) {
                "Required package '$($package.id)' did not reach expected version '$($package.version)'."
            }
            else {
                "Optional package '$($package.id)' did not reach expected version '$($package.version)'."
            }
            Write-WarnFlagged $warningMessage
            Add-BoringAdminApplyWarning $warningMessage
            if ($package.required) {
                Add-BoringAdminApplyFailedItem -Id $package.id -Reason $reason -Classification $package.packageClass -ExpectedVersion $package.version -ObservedVersion $observedAfter
                Register-BoringAdminApplyResultState -Result "partial"
            }
            else {
                Add-BoringAdminApplyOptionalFailedItem -Id $package.id -Reason $reason -Classification $package.packageClass -ExpectedVersion $package.version -ObservedVersion $observedAfter
                $optionalFailures++
            }
        }
    }

    $packageResults.Add([pscustomobject]@{
        id                     = $package.id
        packageManager         = $packageManager
        expectedVersion        = $package.version
        observedVersion        = $observedAfter
        required               = [bool]$package.required
        source                 = $package.source
        reviewedPublisher      = $package.reviewedPublisher
        status                 = $status
        failure_classification = $failureClassification
        installExitCode        = if ($installResult) { [int]$installResult.ExitCode } else { $null }
        installOutputPreview   = if ($installResult) { [string]$installResult.Output } else { "" }
    }) | Out-Null
}

if ($optionalFailures -gt 0 -and [string]$script:BoringAdminApplyResult.result -eq "completed") {
    Add-BoringAdminApplyDetail -Name "completion_classification" -Value "completed-with-warnings"
}

Add-BoringAdminApplyDetail -Name "packages" -Value @($packageResults)
Write-Info "Software baseline evaluation completed."
Write-BoringAdminApplyResult
Exit-Warn
