# ============================================================================
# 15-bootstrap-consumer-noise.safe.ps1
#
# PURPOSE
# -------
# Reduce Windows "consumer noise" while preserving system stability,
# update compatibility, security model, and recovery strategy.
#
# LIFECYCLE
# ---------
# Stage: 10–19 — OS Bootstrap
#
# SCOPE
# -----
# - remove selected consumer UWP apps (whitelist)
# - disable consumer experiences (policy-based)
# - disable tips / ads (per-user UX noise)
# - disable Widgets & Chat (policy-based)
# - apply sane Explorer defaults
#
# SAFETY
# ------
# - SAFE-ONLY changes
# - Idempotent
# - Supports -WhatIf
# - No reboots
#
# CONTRACT
# --------
# This script follows docs/SCRIPT-CONTRACT.md
# and the lifecycle model defined in docs/STRUCTURE.md
# ============================================================================


[CmdletBinding(SupportsShouldProcess = $true)]
param()

# ============================================================================
# 0. BOOTSTRAP
# ============================================================================
# Establish execution context and load runtime helpers.
# ============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptRoot\.."

. "$ProjectRoot\lib\common.ps1"

# Initialize warning state for this script
$script:HadWarnings = $false

# ============================================================================
# 1. EXECUTION CONTEXT
# ============================================================================
# Ensure administrative privileges for system-level operations.
# ============================================================================

Assert-Administrator
Test-PowerShellVersion | Out-Null

Write-Section "15-bootstrap — Consumer Noise Reduction (SAFE-ONLY)"

# ============================================================================
# 2. REMOVE SELECTED CONSUMER UWP APPS (WHITELIST)
# ============================================================================
# Explicit whitelist avoids accidental dependency removal.
# Apps remain reinstallable via Microsoft Store.
# ============================================================================

Write-Section "Removing consumer UWP apps (Whitelist)"

$UwpWhitelist = @(
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

foreach ($app in $UwpWhitelist) {
    
    Write-Info "Processing UWP app(if present): $app"

    # Remove for existing users
    $installed = Get-AppxPackage -AllUsers -Name $app -ErrorAction Stop
    if ($installed) {
        if ($PSCmdlet.ShouldProcess($app, "Remove AppxPackage (AllUsers)")) {
            $installed | Remove-AppxPackage -AllUsers -ErrorAction Stop
            Write-Info "Removed installed package: $app"
        }
    }

    # Remove from provisioning (new users)
    $prov = Get-AppxProvisionedPackage -Online |
        Where-Object DisplayName -EQ $app

    if ($prov) {
        if ($PSCmdlet.ShouldProcess($app, "Remove AppxProvisionedPackage")) {
            $prov | Remove-AppxProvisionedPackage -Online -ErrorAction Stop
            Write-Info "Removed provisioned package: $app"
        }
    }
}

# ============================================================================
# 3. DISABLE WINDOWS CONSUMER EXPERIENCES (POLICY)
# ============================================================================
# Uses official Microsoft policy keys.
# ============================================================================

Write-Section "Disabling Windows consumer experiences (policy)"

$CloudContentPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"

if (-not (Test-Path $CloudContentPath)) {
    if ($PSCmdlet.ShouldProcess($CloudContentPath, "Create policy key")) {
        New-Item -Path $CloudContentPath -Force | Out-Null
    }
}

$ConsumerPolicies = @{
    "DisableConsumerFeatures"                        = 1
    "DisableTailoredExperiencesWithDiagnosticData"   = 1
}


foreach ($name in $ConsumerPolicies.Keys) {
    $current = Get-ItemPropertyValue `
        -Path $CloudContentPath `
        -Name $name `
        -ErrorAction SilentlyContinue

    if ($current -ne $ConsumerPolicies[$name]) {
        if ($PSCmdlet.ShouldProcess($name, "Apply policy value")) {
            New-ItemProperty `
                -Path $CloudContentPath `
                -Name $name `
                -PropertyType DWord `
                -Value $ConsumerPolicies[$name] `
                -Force | Out-Null

            Write-Info "Policy applied: $name"
        }
    }
}


# ============================================================================
# 4. DISABLE TIPS, ADS, SUGGESTIONS (PER-USER UX)
# ============================================================================
# Per-user preferences; intentionally not system-wide.
# ============================================================================

Write-Section "Disabling tips, suggestions and ads (per-user)"

$CdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"

$CmdKeys = @(
    "SubscribedContent-338388Enabled",   # Tips
    "SubscribedContent-338389Enabled",   # Suggestions
    "SubscribedContent-338393Enabled"    # Ads / promotions
)

foreach ($key in $CmdKeys) {
 
    $current = Get-ItemPropertyValue `
        -Path $CdmPath `
        -Name $key `
        -ErrorAction SilentlyContinue

    if ($current -ne 0) {
        if ($PSCmdlet.ShouldProcess($key, "Disable UX noise")) {
            New-ItemProperty `
                -Path $CdmPath `
                -Name $key `
                -PropertyType DWord `
                -Value 0 `
                -Force | Out-Null
        
            Write-Info "Per-user UX setting disabled: $key"
        }
    }
}


# ============================================================================
# 5. DISABLE WIDGETS AND CHAT (POLICY)
# ============================================================================
# Policy-based for update-safe and predictable behavior.
# ============================================================================

Write-Section "Disabling Widgets and Chat (policy)"


# Disable Widgets
$WidgetsPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
if (-not (Test-Path $WidgetsPolicyPath)) {
    if ($PSCmdlet.ShouldProcess($WidgetsPolicyPath, "Create Widgets policy key")) {
        New-Item -Path $WidgetsPolicyPath -Force | Out-Null
    }
}

$currentWidgets = Get-ItemPropertyValue `
    -Path $WidgetsPolicyPath `
    -Name "AllowNewsAndInterests" `
    -ErrorAction SilentlyContinue

if ($currentWidgets -ne 0) {
    if ($PSCmdlet.ShouldProcess("Widgets", "Disable")) {
        New-ItemProperty `
            -Path $WidgetsPolicyPath `
            -Name "AllowNewsAndInterests" `
            -PropertyType DWord `
            -Value 0 `
            -Force | Out-Null

        Write-Info "Widgets disabled via policy."
    }
}

# Disable Chat
$ChatPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat"
if (-not (Test-Path $ChatPolicyPath)) {
    if ($PSCmdlet.ShouldProcess($ChatPolicyPath, "Create Chat policy key")) {
        New-Item -Path $ChatPolicyPath -Force | Out-Null
    }
}

$currentChat = Get-ItemPropertyValue `
    -Path $ChatPolicyPath `
    -Name "ChatIcon" `
    -ErrorAction SilentlyContinue


if ($currentChat -ne 3) {
    if ($PSCmdlet.ShouldProcess("Chat", "Disable")) {
        New-ItemProperty `
            -Path $ChatPolicyPath `
            -Name "ChatIcon" `
            -PropertyType DWord `
            -Value 3 `
            -Force | Out-Null

        Write-Info "Chat disabled via policy."
    }
}

# ============================================================================
# 6. EXPLORER SANE DEFAULTS (PER-USER)
# ============================================================================
# Improves clarity and reduces user error.
# ============================================================================

Write-Section "Applying Explorer sane defaults (per-user)"

$ExplorerAdvancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

$ExplorerSettings = @{
    "HideFileExt" = 0   # show file extensions
    "LaunchTo"    = 1   # This PC
}

foreach ($name in $ExplorerSettings.Keys) {

    $current = Get-ItemPropertyValue `
        -Path $ExplorerAdvancedPath `
        -Name $name `
        -ErrorAction SilentlyContinue

    if ($current -ne $ExplorerSettings[$name]) {
        if ($PSCmdlet.ShouldProcess($name, "Apply Explorer UX default")) {
            New-ItemProperty `
                -Path $ExplorerAdvancedPath `
                -Name $name `
                -PropertyType DWord `
                -Value $ExplorerSettings[$name] `
                -Force | Out-Null

            Write-Info "Explorer setting applied: $name"
        }
    }
}

# ============================================================================
# 7. SAFE-ONLY GUARANTEES (DOCUMENTED INTENT)
# ============================================================================
# Explicitly state what this script does NOT change.
# ============================================================================

Write-Section "SAFE-ONLY guarantees"

Write-Info "Windows Update: untouched"
Write-Info "Windows Defender / Firewall: untouched"
Write-Info "Microsoft Edge: untouched"
Write-Info "Microsoft Store: untouched"
Write-Info "OneDrive: untouched"
Write-Info "No services disabled"
Write-Info "No scheduled tasks removed"
Write-Info "No telemetry services forcibly blocked"

# ============================================================================
# 8. COMPLETION & EXIT STRATEGY
# ============================================================================
# Deterministic SAFE exit via unified helper.
# ============================================================================

Write-Info "Consumer noise reduction completed."

Exit-Warn