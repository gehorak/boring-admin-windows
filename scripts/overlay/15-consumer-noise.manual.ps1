# ============================================================================
# 15-consumer-noise.manual.ps1
#
# PURPOSE
# -------
# Apply optional consumer-noise reduction that is intentionally excluded from
# the public bootstrap baseline.
#
# This script remains operator-owned and MANUAL because it removes selected
# inbox apps and applies opinionated UX policy toggles.
#
# CONTRACT
# --------
# This script follows docs/ARCHITECTURE.md
# ============================================================================

[CmdletBinding(SupportsShouldProcess = $true)]
param()

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptRoot "..")
if (-not (Test-Path (Join-Path $ProjectRoot "core\lib\common.ps1"))) {
    $ProjectRoot = Resolve-Path (Join-Path $ScriptRoot "..\..")
}

. (Join-Path $ProjectRoot "core\lib\common.ps1")

$script:HadWarnings = $false
$null = Initialize-BoringAdminApplyResult -Target "consumer-noise"
$operationResults = [System.Collections.Generic.List[object]]::new()

function Add-ConsumerNoiseOperationRecord {
    param(
        [Parameter(Mandatory)]
        [string] $Id,

        [Parameter(Mandatory)]
        [string] $Kind,

        [Parameter(Mandatory)]
        [string] $Status,

        [AllowNull()]
        [object] $Current,

        [AllowNull()]
        [object] $Desired,

        [string] $ErrorMessage
    )

    $record = [ordered]@{
        id      = $Id
        kind    = $Kind
        status  = $Status
        current = $Current
        desired = $Desired
    }

    if ($ErrorMessage) {
        $record.error = $ErrorMessage
    }

    $operationResults.Add([pscustomobject]$record) | Out-Null
}

$publicApplyTarget = [System.Environment]::GetEnvironmentVariable("BORING_ADMIN_PUBLIC_APPLY_TARGET", "Process")
if ($publicApplyTarget -ne "consumer-noise") {
    Exit-Fatal "Use boring-admin.ps1 apply consumer-noise --change-id <id>."
}

Assert-Administrator
Test-PowerShellVersion | Out-Null

Write-Section "15-consumer-noise - Optional Consumer Noise Reduction"
Write-Warn "This path is intentionally NOT part of public bootstrap."
Write-Warn "It removes selected inbox apps and applies opinionated UX policy changes."
Write-Warn "Review rollback expectations before continuing."
Write-Info "Public confirmation is handled before this script executes."

Write-Section "Removing consumer UWP apps (whitelist)"

$uwpWhitelist = @(
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
)

foreach ($app in $uwpWhitelist) {
    Write-Info "Processing UWP app (if present): $app"

    $installedQuery = Invoke-BoringAdminApplyOperation `
        -Id ("consumer-noise.appx.installed-query.{0}" -f $app) `
        -Classification "consumer-noise" `
        -FailureReason "appx-installed-query-failed" `
        -FailureMessage ("Failed to query installed AppX package '{0}'." -f $app) `
        -Operation { @(Get-AppxPackage -AllUsers -Name $app -ErrorAction Stop) }
    $installed = if ($installedQuery.Success -and $null -ne $installedQuery.Value) { @($installedQuery.Value) } else { @() }

    if (-not $installedQuery.Success) {
        Add-ConsumerNoiseOperationRecord `
            -Id ("consumer-noise.appx.installed.{0}" -f $app) `
            -Kind "appx-installed-package" `
            -Status "query-failed" `
            -Current "unknown" `
            -Desired "absent" `
            -ErrorMessage $installedQuery.Error
    }
    elseif ($installed.Count -eq 0) {
        Add-ConsumerNoiseOperationRecord `
            -Id ("consumer-noise.appx.installed.{0}" -f $app) `
            -Kind "appx-installed-package" `
            -Status "absent" `
            -Current "absent" `
            -Desired "absent"
    }
    elseif ($PSCmdlet.ShouldProcess($app, "Remove AppxPackage (AllUsers)")) {
        $removeInstalled = Invoke-BoringAdminApplyOperation `
            -Id ("consumer-noise.appx.installed.{0}" -f $app) `
            -Classification "consumer-noise" `
            -FailureReason "remove-installed-package-failed" `
            -FailureMessage ("Failed to remove installed AppX package '{0}'." -f $app) `
            -Operation { $installed | Remove-AppxPackage -AllUsers -ErrorAction Stop }

        if ($removeInstalled.Success) {
            Write-Info "Removed installed package: $app"
            Add-ConsumerNoiseOperationRecord `
                -Id ("consumer-noise.appx.installed.{0}" -f $app) `
                -Kind "appx-installed-package" `
                -Status "removed" `
                -Current "present" `
                -Desired "absent"
        }
        else {
            Add-ConsumerNoiseOperationRecord `
                -Id ("consumer-noise.appx.installed.{0}" -f $app) `
                -Kind "appx-installed-package" `
                -Status "failed" `
                -Current "present" `
                -Desired "absent" `
                -ErrorMessage $removeInstalled.Error
        }
    }
    else {
        Add-ConsumerNoiseOperationRecord `
            -Id ("consumer-noise.appx.installed.{0}" -f $app) `
            -Kind "appx-installed-package" `
            -Status "skipped" `
            -Current "present" `
            -Desired "absent"
    }

    $provisionedQuery = Invoke-BoringAdminApplyOperation `
        -Id ("consumer-noise.appx.provisioned-query.{0}" -f $app) `
        -Classification "consumer-noise" `
        -FailureReason "appx-provisioned-query-failed" `
        -FailureMessage ("Failed to query provisioned AppX package '{0}'." -f $app) `
        -Operation { @(Get-AppxProvisionedPackage -Online | Where-Object DisplayName -EQ $app) }
    $provisioned = if ($provisionedQuery.Success -and $null -ne $provisionedQuery.Value) { @($provisionedQuery.Value) } else { @() }

    if (-not $provisionedQuery.Success) {
        Add-ConsumerNoiseOperationRecord `
            -Id ("consumer-noise.appx.provisioned.{0}" -f $app) `
            -Kind "appx-provisioned-package" `
            -Status "query-failed" `
            -Current "unknown" `
            -Desired "absent" `
            -ErrorMessage $provisionedQuery.Error
    }
    elseif ($provisioned.Count -eq 0) {
        Add-ConsumerNoiseOperationRecord `
            -Id ("consumer-noise.appx.provisioned.{0}" -f $app) `
            -Kind "appx-provisioned-package" `
            -Status "absent" `
            -Current "absent" `
            -Desired "absent"
    }
    elseif ($PSCmdlet.ShouldProcess($app, "Remove AppxProvisionedPackage")) {
        $removeProvisioned = Invoke-BoringAdminApplyOperation `
            -Id ("consumer-noise.appx.provisioned.{0}" -f $app) `
            -Classification "consumer-noise" `
            -FailureReason "remove-provisioned-package-failed" `
            -FailureMessage ("Failed to remove provisioned AppX package '{0}'." -f $app) `
            -Operation { $provisioned | Remove-AppxProvisionedPackage -Online -ErrorAction Stop }

        if ($removeProvisioned.Success) {
            Write-Info "Removed provisioned package: $app"
            Add-ConsumerNoiseOperationRecord `
                -Id ("consumer-noise.appx.provisioned.{0}" -f $app) `
                -Kind "appx-provisioned-package" `
                -Status "removed" `
                -Current "present" `
                -Desired "absent"
        }
        else {
            Add-ConsumerNoiseOperationRecord `
                -Id ("consumer-noise.appx.provisioned.{0}" -f $app) `
                -Kind "appx-provisioned-package" `
                -Status "failed" `
                -Current "present" `
                -Desired "absent" `
                -ErrorMessage $removeProvisioned.Error
        }
    }
    else {
        Add-ConsumerNoiseOperationRecord `
            -Id ("consumer-noise.appx.provisioned.{0}" -f $app) `
            -Kind "appx-provisioned-package" `
            -Status "skipped" `
            -Current "present" `
            -Desired "absent"
    }
}

Write-Section "Disabling consumer experiences (policy)"

$cloudContentPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
$cloudContentReady = Test-Path -LiteralPath $cloudContentPath -PathType Container
if (-not $cloudContentReady -and $PSCmdlet.ShouldProcess($cloudContentPath, "Create policy key")) {
    $createCloudContent = Invoke-BoringAdminApplyOperation `
        -Id "consumer-noise.registry-key.CloudContent" `
        -Classification "consumer-noise" `
        -FailureReason "create-policy-key-failed" `
        -FailureMessage "Failed to create CloudContent policy key." `
        -Operation { New-Item -Path $cloudContentPath -Force | Out-Null }
    $cloudContentReady = $createCloudContent.Success -or (Test-Path -LiteralPath $cloudContentPath -PathType Container)

    Add-ConsumerNoiseOperationRecord `
        -Id "consumer-noise.registry-key.CloudContent" `
        -Kind "registry-key" `
        -Status $(if ($createCloudContent.Success) { "created" } else { "failed" }) `
        -Current "missing" `
        -Desired "present" `
        -ErrorMessage $createCloudContent.Error
}

$consumerPolicies = @{
    DisableConsumerFeatures                      = 1
    DisableTailoredExperiencesWithDiagnosticData = 1
}

foreach ($name in $consumerPolicies.Keys) {
    if (-not $cloudContentReady) {
        Add-ConsumerNoiseOperationRecord `
            -Id ("consumer-noise.registry.{0}" -f $name) `
            -Kind "registry-value" `
            -Status "blocked" `
            -Current "unavailable" `
            -Desired $consumerPolicies[$name] `
            -ErrorMessage "CloudContent policy key is unavailable."
        continue
    }

    $current = Get-ItemPropertyValue -Path $cloudContentPath -Name $name -ErrorAction SilentlyContinue
    if ($current -ne $consumerPolicies[$name] -and $PSCmdlet.ShouldProcess($name, "Apply policy value")) {
        $setPolicy = Invoke-BoringAdminApplyOperation `
            -Id ("consumer-noise.registry.{0}" -f $name) `
            -Classification "consumer-noise" `
            -FailureReason "set-policy-value-failed" `
            -FailureMessage ("Failed to apply policy value '{0}'." -f $name) `
            -Operation { New-ItemProperty -Path $cloudContentPath -Name $name -PropertyType DWord -Value $consumerPolicies[$name] -Force | Out-Null }

        if ($setPolicy.Success) {
            Write-Info "Policy applied: $name"
            Add-ConsumerNoiseOperationRecord `
                -Id ("consumer-noise.registry.{0}" -f $name) `
                -Kind "registry-value" `
                -Status "applied" `
                -Current $current `
                -Desired $consumerPolicies[$name]
        }
        else {
            Add-ConsumerNoiseOperationRecord `
                -Id ("consumer-noise.registry.{0}" -f $name) `
                -Kind "registry-value" `
                -Status "failed" `
                -Current $current `
                -Desired $consumerPolicies[$name] `
                -ErrorMessage $setPolicy.Error
        }
    }
    elseif ($current -eq $consumerPolicies[$name]) {
        Add-ConsumerNoiseOperationRecord `
            -Id ("consumer-noise.registry.{0}" -f $name) `
            -Kind "registry-value" `
            -Status "already-set" `
            -Current $current `
            -Desired $consumerPolicies[$name]
    }
    else {
        Add-ConsumerNoiseOperationRecord `
            -Id ("consumer-noise.registry.{0}" -f $name) `
            -Kind "registry-value" `
            -Status "skipped" `
            -Current $current `
            -Desired $consumerPolicies[$name]
    }
}

Write-Section "Disabling tips, suggestions, and ads (per-user)"

$cdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
$cdmReady = Test-Path -LiteralPath $cdmPath -PathType Container
if (-not $cdmReady -and $PSCmdlet.ShouldProcess($cdmPath, "Create ContentDeliveryManager path")) {
    $createCdmPath = Invoke-BoringAdminApplyOperation `
        -Id "consumer-noise.registry-key.ContentDeliveryManager" `
        -Classification "consumer-noise" `
        -FailureReason "create-registry-key-failed" `
        -FailureMessage "Failed to create ContentDeliveryManager registry path." `
        -Operation { New-Item -Path $cdmPath -Force | Out-Null }
    $cdmReady = $createCdmPath.Success -or (Test-Path -LiteralPath $cdmPath -PathType Container)

    Add-ConsumerNoiseOperationRecord `
        -Id "consumer-noise.registry-key.ContentDeliveryManager" `
        -Kind "registry-key" `
        -Status $(if ($createCdmPath.Success) { "created" } else { "failed" }) `
        -Current "missing" `
        -Desired "present" `
        -ErrorMessage $createCdmPath.Error
}

$cdmKeys = @(
    "SubscribedContent-338388Enabled",
    "SubscribedContent-338389Enabled",
    "SubscribedContent-338393Enabled"
)

foreach ($key in $cdmKeys) {
    if (-not $cdmReady) {
        Add-ConsumerNoiseOperationRecord `
            -Id ("consumer-noise.registry.{0}" -f $key) `
            -Kind "registry-value" `
            -Status "blocked" `
            -Current "unavailable" `
            -Desired 0 `
            -ErrorMessage "ContentDeliveryManager registry path is unavailable."
        continue
    }

    $current = Get-ItemPropertyValue -Path $cdmPath -Name $key -ErrorAction SilentlyContinue
    if ($current -ne 0 -and $PSCmdlet.ShouldProcess($key, "Disable UX noise")) {
        $setCdmValue = Invoke-BoringAdminApplyOperation `
            -Id ("consumer-noise.registry.{0}" -f $key) `
            -Classification "consumer-noise" `
            -FailureReason "set-registry-value-failed" `
            -FailureMessage ("Failed to disable UX noise value '{0}'." -f $key) `
            -Operation { New-ItemProperty -Path $cdmPath -Name $key -PropertyType DWord -Value 0 -Force | Out-Null }

        if ($setCdmValue.Success) {
            Write-Info "Per-user UX setting disabled: $key"
            Add-ConsumerNoiseOperationRecord `
                -Id ("consumer-noise.registry.{0}" -f $key) `
                -Kind "registry-value" `
                -Status "applied" `
                -Current $current `
                -Desired 0
        }
        else {
            Add-ConsumerNoiseOperationRecord `
                -Id ("consumer-noise.registry.{0}" -f $key) `
                -Kind "registry-value" `
                -Status "failed" `
                -Current $current `
                -Desired 0 `
                -ErrorMessage $setCdmValue.Error
        }
    }
    elseif ($current -eq 0) {
        Add-ConsumerNoiseOperationRecord `
            -Id ("consumer-noise.registry.{0}" -f $key) `
            -Kind "registry-value" `
            -Status "already-set" `
            -Current $current `
            -Desired 0
    }
    else {
        Add-ConsumerNoiseOperationRecord `
            -Id ("consumer-noise.registry.{0}" -f $key) `
            -Kind "registry-value" `
            -Status "skipped" `
            -Current $current `
            -Desired 0
    }
}

Write-Section "Disabling Widgets and Chat (policy)"

$widgetsPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
$widgetsPolicyReady = Test-Path -LiteralPath $widgetsPolicyPath -PathType Container
if (-not $widgetsPolicyReady -and $PSCmdlet.ShouldProcess($widgetsPolicyPath, "Create Widgets policy key")) {
    $createWidgetsPolicyPath = Invoke-BoringAdminApplyOperation `
        -Id "consumer-noise.registry-key.WidgetsPolicy" `
        -Classification "consumer-noise" `
        -FailureReason "create-policy-key-failed" `
        -FailureMessage "Failed to create Widgets policy key." `
        -Operation { New-Item -Path $widgetsPolicyPath -Force | Out-Null }
    $widgetsPolicyReady = $createWidgetsPolicyPath.Success -or (Test-Path -LiteralPath $widgetsPolicyPath -PathType Container)

    Add-ConsumerNoiseOperationRecord `
        -Id "consumer-noise.registry-key.WidgetsPolicy" `
        -Kind "registry-key" `
        -Status $(if ($createWidgetsPolicyPath.Success) { "created" } else { "failed" }) `
        -Current "missing" `
        -Desired "present" `
        -ErrorMessage $createWidgetsPolicyPath.Error
}

if (-not $widgetsPolicyReady) {
    Add-ConsumerNoiseOperationRecord `
        -Id "consumer-noise.registry.AllowNewsAndInterests" `
        -Kind "registry-value" `
        -Status "blocked" `
        -Current "unavailable" `
        -Desired 0 `
        -ErrorMessage "Widgets policy key is unavailable."
}
else {
    $currentWidgets = Get-ItemPropertyValue -Path $widgetsPolicyPath -Name "AllowNewsAndInterests" -ErrorAction SilentlyContinue
    if ($currentWidgets -ne 0 -and $PSCmdlet.ShouldProcess("Widgets", "Disable")) {
        $disableWidgets = Invoke-BoringAdminApplyOperation `
            -Id "consumer-noise.registry.AllowNewsAndInterests" `
            -Classification "consumer-noise" `
            -FailureReason "set-policy-value-failed" `
            -FailureMessage "Failed to disable Widgets via policy." `
            -Operation { New-ItemProperty -Path $widgetsPolicyPath -Name "AllowNewsAndInterests" -PropertyType DWord -Value 0 -Force | Out-Null }

        if ($disableWidgets.Success) {
            Write-Info "Widgets disabled via policy."
            Add-ConsumerNoiseOperationRecord `
                -Id "consumer-noise.registry.AllowNewsAndInterests" `
                -Kind "registry-value" `
                -Status "applied" `
                -Current $currentWidgets `
                -Desired 0
        }
        else {
            Add-ConsumerNoiseOperationRecord `
                -Id "consumer-noise.registry.AllowNewsAndInterests" `
                -Kind "registry-value" `
                -Status "failed" `
                -Current $currentWidgets `
                -Desired 0 `
                -ErrorMessage $disableWidgets.Error
        }
    }
    elseif ($currentWidgets -eq 0) {
        Add-ConsumerNoiseOperationRecord `
            -Id "consumer-noise.registry.AllowNewsAndInterests" `
            -Kind "registry-value" `
            -Status "already-set" `
            -Current $currentWidgets `
            -Desired 0
    }
    else {
        Add-ConsumerNoiseOperationRecord `
            -Id "consumer-noise.registry.AllowNewsAndInterests" `
            -Kind "registry-value" `
            -Status "skipped" `
            -Current $currentWidgets `
            -Desired 0
    }
}

$chatPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat"
$chatPolicyReady = Test-Path -LiteralPath $chatPolicyPath -PathType Container
if (-not $chatPolicyReady -and $PSCmdlet.ShouldProcess($chatPolicyPath, "Create Chat policy key")) {
    $createChatPolicyPath = Invoke-BoringAdminApplyOperation `
        -Id "consumer-noise.registry-key.ChatPolicy" `
        -Classification "consumer-noise" `
        -FailureReason "create-policy-key-failed" `
        -FailureMessage "Failed to create Chat policy key." `
        -Operation { New-Item -Path $chatPolicyPath -Force | Out-Null }
    $chatPolicyReady = $createChatPolicyPath.Success -or (Test-Path -LiteralPath $chatPolicyPath -PathType Container)

    Add-ConsumerNoiseOperationRecord `
        -Id "consumer-noise.registry-key.ChatPolicy" `
        -Kind "registry-key" `
        -Status $(if ($createChatPolicyPath.Success) { "created" } else { "failed" }) `
        -Current "missing" `
        -Desired "present" `
        -ErrorMessage $createChatPolicyPath.Error
}

if (-not $chatPolicyReady) {
    Add-ConsumerNoiseOperationRecord `
        -Id "consumer-noise.registry.ChatIcon" `
        -Kind "registry-value" `
        -Status "blocked" `
        -Current "unavailable" `
        -Desired 3 `
        -ErrorMessage "Chat policy key is unavailable."
}
else {
    $currentChat = Get-ItemPropertyValue -Path $chatPolicyPath -Name "ChatIcon" -ErrorAction SilentlyContinue
    if ($currentChat -ne 3 -and $PSCmdlet.ShouldProcess("Chat", "Disable")) {
        $disableChat = Invoke-BoringAdminApplyOperation `
            -Id "consumer-noise.registry.ChatIcon" `
            -Classification "consumer-noise" `
            -FailureReason "set-policy-value-failed" `
            -FailureMessage "Failed to disable Chat via policy." `
            -Operation { New-ItemProperty -Path $chatPolicyPath -Name "ChatIcon" -PropertyType DWord -Value 3 -Force | Out-Null }

        if ($disableChat.Success) {
            Write-Info "Chat disabled via policy."
            Add-ConsumerNoiseOperationRecord `
                -Id "consumer-noise.registry.ChatIcon" `
                -Kind "registry-value" `
                -Status "applied" `
                -Current $currentChat `
                -Desired 3
        }
        else {
            Add-ConsumerNoiseOperationRecord `
                -Id "consumer-noise.registry.ChatIcon" `
                -Kind "registry-value" `
                -Status "failed" `
                -Current $currentChat `
                -Desired 3 `
                -ErrorMessage $disableChat.Error
        }
    }
    elseif ($currentChat -eq 3) {
        Add-ConsumerNoiseOperationRecord `
            -Id "consumer-noise.registry.ChatIcon" `
            -Kind "registry-value" `
            -Status "already-set" `
            -Current $currentChat `
            -Desired 3
    }
    else {
        Add-ConsumerNoiseOperationRecord `
            -Id "consumer-noise.registry.ChatIcon" `
            -Kind "registry-value" `
            -Status "skipped" `
            -Current $currentChat `
            -Desired 3
    }
}

Write-Section "Applying Explorer sane defaults (per-user)"

$explorerAdvancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$explorerAdvancedReady = Test-Path -LiteralPath $explorerAdvancedPath -PathType Container
if (-not $explorerAdvancedReady -and $PSCmdlet.ShouldProcess($explorerAdvancedPath, "Create Explorer advanced path")) {
    $createExplorerAdvancedPath = Invoke-BoringAdminApplyOperation `
        -Id "consumer-noise.registry-key.ExplorerAdvanced" `
        -Classification "consumer-noise" `
        -FailureReason "create-registry-key-failed" `
        -FailureMessage "Failed to create Explorer advanced registry path." `
        -Operation { New-Item -Path $explorerAdvancedPath -Force | Out-Null }
    $explorerAdvancedReady = $createExplorerAdvancedPath.Success -or (Test-Path -LiteralPath $explorerAdvancedPath -PathType Container)

    Add-ConsumerNoiseOperationRecord `
        -Id "consumer-noise.registry-key.ExplorerAdvanced" `
        -Kind "registry-key" `
        -Status $(if ($createExplorerAdvancedPath.Success) { "created" } else { "failed" }) `
        -Current "missing" `
        -Desired "present" `
        -ErrorMessage $createExplorerAdvancedPath.Error
}

$explorerSettings = @{
    HideFileExt = 0
    LaunchTo    = 1
}

foreach ($name in $explorerSettings.Keys) {
    if (-not $explorerAdvancedReady) {
        Add-ConsumerNoiseOperationRecord `
            -Id ("consumer-noise.registry.{0}" -f $name) `
            -Kind "registry-value" `
            -Status "blocked" `
            -Current "unavailable" `
            -Desired $explorerSettings[$name] `
            -ErrorMessage "Explorer advanced registry path is unavailable."
        continue
    }

    $current = Get-ItemPropertyValue -Path $explorerAdvancedPath -Name $name -ErrorAction SilentlyContinue
    if ($current -ne $explorerSettings[$name] -and $PSCmdlet.ShouldProcess($name, "Apply Explorer UX default")) {
        $setExplorerValue = Invoke-BoringAdminApplyOperation `
            -Id ("consumer-noise.registry.{0}" -f $name) `
            -Classification "consumer-noise" `
            -FailureReason "set-registry-value-failed" `
            -FailureMessage ("Failed to apply Explorer setting '{0}'." -f $name) `
            -Operation { New-ItemProperty -Path $explorerAdvancedPath -Name $name -PropertyType DWord -Value $explorerSettings[$name] -Force | Out-Null }

        if ($setExplorerValue.Success) {
            Write-Info "Explorer setting applied: $name"
            Add-ConsumerNoiseOperationRecord `
                -Id ("consumer-noise.registry.{0}" -f $name) `
                -Kind "registry-value" `
                -Status "applied" `
                -Current $current `
                -Desired $explorerSettings[$name]
        }
        else {
            Add-ConsumerNoiseOperationRecord `
                -Id ("consumer-noise.registry.{0}" -f $name) `
                -Kind "registry-value" `
                -Status "failed" `
                -Current $current `
                -Desired $explorerSettings[$name] `
                -ErrorMessage $setExplorerValue.Error
        }
    }
    elseif ($current -eq $explorerSettings[$name]) {
        Add-ConsumerNoiseOperationRecord `
            -Id ("consumer-noise.registry.{0}" -f $name) `
            -Kind "registry-value" `
            -Status "already-set" `
            -Current $current `
            -Desired $explorerSettings[$name]
    }
    else {
        Add-ConsumerNoiseOperationRecord `
            -Id ("consumer-noise.registry.{0}" -f $name) `
            -Kind "registry-value" `
            -Status "skipped" `
            -Current $current `
            -Desired $explorerSettings[$name]
    }
}

Write-Section "Intentional non-actions"
Write-Info "Windows Update: untouched"
Write-Info "Windows Defender / Firewall: untouched"
Write-Info "Microsoft Edge: untouched"
Write-Info "Microsoft Store: untouched"
Write-Info "OneDrive: untouched"
Write-Info "No services disabled"
Write-Info "No scheduled tasks removed"
Write-Info "No telemetry services forcibly blocked"

Add-BoringAdminApplyDetail -Name "operations" -Value @($operationResults)

Write-Info "Optional consumer noise reduction completed."
Write-BoringAdminApplyResult
Exit-Warn
