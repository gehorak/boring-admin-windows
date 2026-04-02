# ============================================================================
# 55-host-identity-visibility.verify.ps1
#
# PURPOSE
# -------
# Provide read-only visibility into HOST IDENTITY state.
#
# This script exposes how the machine currently identifies itself:
# - computer name
# - system time zone
# - system locale (non-Unicode)
#
# The script performs OBSERVATION ONLY.
# It does NOT enforce or modify any configuration.
#
# LIFECYCLE
# ---------
# Stage: 50–59 — Host & Device Identity
#
# MODE
# ----
# VERIFY
# - Read-only
# - Safe to run repeatedly
# - No side effects
#
# EXIT MODEL
# ----------
# Variant A:
# - exit 0 : completed (with or without warnings)
# - exit 1 : fatal error only
#
# CONTRACT
# --------
# Follows docs/SCRIPT-CONTRACT.md
# and docs/STRUCTURE.md
# ============================================================================


[CmdletBinding()]
param(
    [ValidateSet("Text", "Json")]
    [string] $OutputFormat = "Text"
)


# ============================================================================
# 0. BOOTSTRAP
# ============================================================================

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptRoot "..\..")
if (-not (Test-Path (Join-Path $ProjectRoot "core\lib\common.ps1"))) {
    $ProjectRoot = Resolve-Path (Join-Path $ScriptRoot "..\..\..")
}

. (Join-Path $ProjectRoot "core\lib\common.ps1")

$script:HadWarnings = $false
$warnings = [System.Collections.Generic.List[string]]::new()

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


# ============================================================================
# 1. EXECUTION CONTEXT
# ============================================================================

Assert-Administrator
Test-PowerShellVersion | Out-Null

$computerName = $null
$timeZone = $null
$systemLocale = $null


# ============================================================================
# 2. HOST IDENTITY SNAPSHOT
# ============================================================================
# Pure visibility. No expectations, no enforcement.
# ============================================================================

# --- Computer name -----------------------------------------------------------

try {
    $computerName = $env:COMPUTERNAME
}
catch {
    Add-HostVisibilityWarning "Unable to read computer name."
}

# --- Time zone ---------------------------------------------------------------

try {
    $tz = Get-TimeZone
    $timeZone = [pscustomobject]@{
        id        = $tz.Id
        utcOffset = $tz.BaseUtcOffset.ToString()
    }
}
catch {
    Add-HostVisibilityWarning "Unable to read system time zone."
}

# --- System locale -----------------------------------------------------------

try {
    $locale = Get-WinSystemLocale
    $systemLocale = $locale.Name
}
catch {
    Add-HostVisibilityWarning "Unable to read system locale."
}

$result = [pscustomobject]@{
    scope       = "host-identity-visibility"
    generatedAt = (Get-Date).ToString("s")
    host        = [pscustomobject]@{
        computerName = $computerName
        timeZone     = $timeZone
        systemLocale = $systemLocale
    }
    warnings    = @($warnings)
}

if ($OutputFormat -eq "Json") {
    $result | ConvertTo-Json -Depth 5
    Exit-Warn
}

Write-Section "55-host-identity — Visibility (VERIFY)"
Write-Section "Host identity snapshot"

if ($computerName) {
    Write-Info "Computer name : $computerName"
}

if ($timeZone) {
    Write-Info "Time zone     : $($timeZone.id)"
    Write-Info "UTC offset    : $($timeZone.utcOffset)"
}

if ($systemLocale) {
    Write-Info "System locale : $systemLocale"
}


# ============================================================================
# 3. CONTEXTUAL NOTES (NON-ENFORCING)
# ============================================================================
# Human hints only. No judgement.
# ============================================================================

Write-Section "Contextual notes"

Write-Info "Host identity affects:"
Write-Info "- log readability"
Write-Info "- incident and forensic timelines"
Write-Info "- remote administration clarity"

Write-Host ""
Write-Info "Changes to host identity:"
Write-Info "- are rare and intentional"
Write-Info "- may require a manual reboot"
Write-Info "- should be documented when performed"


# ============================================================================
# 4. INTENTIONAL NON-ACTIONS
# ============================================================================
# Explicit declaration for audit clarity.
# ============================================================================

Write-Section "Intentional non-actions"

Write-Info "No configuration was modified"
Write-Info "No reboot was scheduled or performed"
Write-Info "No enforcement or remediation occurred"
Write-Info "No network or security settings were accessed"


# ============================================================================
# 5. SUMMARY & EXIT
# ============================================================================

Write-Section "Summary"

Write-Info "Host identity visibility check completed."

if ($script:HadWarnings) {
    Write-Warn "Some host identity information could not be retrieved."
    Exit-Warn
}

Exit-Warn
