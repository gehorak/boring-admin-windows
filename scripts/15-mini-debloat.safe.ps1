# ============================================================================
# 15-mini-debloat.safe.ps1
#
# PURPOSE
# -------
# Reduce Windows 11 "consumer noise" while preserving:
# - system stability
# - update compatibility
# - security model
# - recovery strategy
#
# THIS IS NOT:
# -----------
# - a hardening script
# - a performance tuning script
# - a telemetry killing script
#
# DESIGN PRINCIPLES
# -----------------
# - SAFE-ONLY changes
# - official policies where possible
# - reversible without reinstall
# - survive feature updates
#
# SCOPE
# -----
# - remove selected consumer UWP apps (whitelist)
# - disable consumer experiences (policy-based)
# - disable tips / ads (per-user UX noise)
# - disable Widgets & Chat (policy-based)
# - apply sane Explorer defaults
#
# EXPLICIT NON-GOALS
# ------------------
# - do NOT touch Windows Update
# - do NOT touch Defender / Firewall
# - do NOT touch Edge
# - do NOT touch Microsoft Store
# - do NOT touch OneDrive
# - do NOT disable services or scheduled tasks
# ============================================================================


# -----------------------------------------------------------------------------
# Bootstrap
# -----------------------------------------------------------------------------

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptRoot\.."

. "$ProjectRoot\lib\common.ps1"


Assert-Administrator
Test-PowerShellVersion | Out-Null

Write-Section "Mini Debloat (SAFE-ONLY)"

# ---------------------------------------------------------------------------
# 1) Remove selected consumer UWP applications (WHITELIST)
# ---------------------------------------------------------------------------
# WHY
# ---
# These apps are:
# - consumer-facing
# - not required by OS core
# - not dependencies of Windows Update
# - reinstallable from Microsoft Store if needed
#
# WHY A WHITELIST (not blacklist)
# ------------------------------
# Blacklists rot over time and accidentally remove new dependencies.
# A whitelist makes intent explicit and future-safe.
# ---------------------------------------------------------------------------

Write-Section "Removing selected consumer UWP apps"

$UwpWhitelist = @(
    "Microsoft.Clipchamp",              # video editor (consumer)
    "MicrosoftTeams",                   # personal Teams (not M365)
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
    Write-Info "Removing UWP app (if present): $app"

    # Remove for existing users
    Get-AppxPackage -AllUsers -Name $app -ErrorAction SilentlyContinue |
        Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

    # Remove from provisioning (new users)
    Get-AppxProvisionedPackage -Online |
        Where-Object DisplayName -EQ $app |
        Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# 2) Disable Windows consumer experiences (OFFICIAL POLICY)
# ---------------------------------------------------------------------------
# WHY
# ---
# These settings disable:
# - consumer app suggestions
# - promotional content
# - "tailored experiences"
#
# IMPORTANT
# ---------
# This uses OFFICIAL Microsoft policy keys.
# This is common in enterprise baselines and update-safe.
# ---------------------------------------------------------------------------

Write-Section "Disabling Windows consumer experiences (policy)"

$CloudContentPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
New-Item -Path $CloudContentPath -Force | Out-Null

# Disable consumer features
New-ItemProperty `
    -Path $CloudContentPath `
    -Name "DisableConsumerFeatures" `
    -PropertyType DWord `
    -Value 1 `
    -Force | Out-Null

# Disable tailored experiences using diagnostic data
New-ItemProperty `
    -Path $CloudContentPath `
    -Name "DisableTailoredExperiencesWithDiagnosticData" `
    -PropertyType DWord `
    -Value 1 `
    -Force | Out-Null

# ---------------------------------------------------------------------------
# 3) Disable tips, suggestions and ads (PER-USER UX NOISE)
# ---------------------------------------------------------------------------
# WHY
# ---
# These settings reduce UI noise and distractions.
# They do NOT affect system behavior or security.
#
# NOTE
# ----
# HKCU means this applies to the current user only.
# This is intentional: UX preferences belong to users.
# ---------------------------------------------------------------------------

Write-Section "Disabling tips, suggestions and ads (per-user)"

$CdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"

$ContentDeliveryKeys = @(
    "SubscribedContent-338388Enabled",   # Tips
    "SubscribedContent-338389Enabled",   # Suggestions
    "SubscribedContent-338393Enabled"    # Ads / promotions
)

foreach ($key in $ContentDeliveryKeys) {
    New-ItemProperty `
        -Path $CdmPath `
        -Name $key `
        -PropertyType DWord `
        -Value 0 `
        -Force | Out-Null
}

# ---------------------------------------------------------------------------
# 4) Disable Widgets and Chat (POLICY-BASED)
# ---------------------------------------------------------------------------
# WHY
# ---
# Widgets and Chat are:
# - consumer-focused
# - non-essential in SMB environments
#
# Using policies ensures:
# - update compatibility
# - predictable behavior
# - easy rollback
# ---------------------------------------------------------------------------

Write-Section "Disabling Widgets and Chat (policy)"

# Disable Widgets
$WidgetsPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
New-Item -Path $WidgetsPolicyPath -Force | Out-Null
New-ItemProperty `
    -Path $WidgetsPolicyPath `
    -Name "AllowNewsAndInterests" `
    -PropertyType DWord `
    -Value 0 `
    -Force | Out-Null

# Disable Chat
$ChatPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat"
New-Item -Path $ChatPolicyPath -Force | Out-Null
New-ItemProperty `
    -Path $ChatPolicyPath `
    -Name "ChatIcon" `
    -PropertyType DWord `
    -Value 3 `
    -Force | Out-Null

# ---------------------------------------------------------------------------
# 5) Explorer sane defaults (BEST PRACTICE)
# ---------------------------------------------------------------------------
# WHY
# ---
# These settings improve clarity and reduce user mistakes:
# - visible file extensions prevent spoofing
# - opening Explorer to "This PC" improves orientation
#
# NOTE
# ----
# These are per-user preferences, not system policies.
# ---------------------------------------------------------------------------

Write-Section "Applying Explorer sane defaults (per-user)"

$ExplorerAdvancedPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# Show file extensions
New-ItemProperty `
    -Path $ExplorerAdvancedPath `
    -Name "HideFileExt" `
    -PropertyType DWord `
    -Value 0 `
    -Force | Out-Null

# Open Explorer to "This PC"
New-ItemProperty `
    -Path $ExplorerAdvancedPath `
    -Name "LaunchTo" `
    -PropertyType DWord `
    -Value 1 `
    -Force | Out-Null

# ---------------------------------------------------------------------------
# 6) Explicit guarantees (DOCUMENTATION IN CODE)
# ---------------------------------------------------------------------------
# WHY
# ---
# Future maintainers need to know not only what we changed,
# but also what we intentionally DID NOT change.
# ---------------------------------------------------------------------------

Write-Section "SAFE-ONLY guarantees"

Write-Info "Windows Update: untouched"
Write-Info "Windows Defender / Firewall: untouched"
Write-Info "Microsoft Edge: untouched"
Write-Info "Microsoft Store: untouched"
Write-Info "OneDrive: untouched"
Write-Info "No services disabled"
Write-Info "No scheduled tasks removed"
Write-Info "No telemetry services forcibly blocked"

Write-Info "Mini debloat completed successfully."
