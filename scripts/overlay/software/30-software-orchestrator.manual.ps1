# ============================================================================
# 30-software-orchestrator.manual.ps1
#
# PURPOSE
# -------
# Human-first entry point for software lifecycle management.
#
# This orchestrator provides a controlled, explicit way to execute
# software-related scripts in the correct order and intent.
#
# It does NOT install software by itself.
#
# LIFECYCLE
# ---------
# Stage: 30–39 — Software
#
# MODE
# ----
# MANUAL
# - Explicit human choice required
# - No unattended execution
# - No implicit actions
#
# DESIGN PRINCIPLES
# -----------------
# - clarity over convenience
# - no automation magic
# - explicit intent before execution
#
# CONTRACT
# --------
# This script follows docs/SCRIPT-CONTRACT.md
# ============================================================================


# ---------------------------------------------------------------------------
# Bootstrap
# ---------------------------------------------------------------------------

$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptRoot "..\..")
if (-not (Test-Path (Join-Path $ProjectRoot "core\lib\common.ps1"))) {
    $ProjectRoot = Resolve-Path (Join-Path $ScriptRoot "..\..\..")
}

. (Join-Path $ProjectRoot "core\lib\common.ps1")

$script:HadWarnings = $false

Assert-Administrator
Test-PowerShellVersion | Out-Null

Write-Section "Software Lifecycle Orchestrator"

function Invoke-SoftwareAction {
    param(
        [Parameter(Mandatory)]
        [string] $RelativeName
    )

    $target = Join-Path $ScriptRoot $RelativeName
    if (-not (Test-Path $target)) {
        Exit-Fatal "Software lifecycle script not found: $RelativeName"
    }

    & $target
    if ($LASTEXITCODE -ne 0) {
        Exit-Fatal "Software lifecycle script failed: $RelativeName"
    }

    Exit-Warn
}


# ---------------------------------------------------------------------------
# Context
# ---------------------------------------------------------------------------

Write-Info "This orchestrator manages SOFTWARE lifecycle scripts (30-39)."
Write-Info "Nothing will run without your explicit choice."
Write-Info "You are responsible for understanding each action."
Write-Info "Chocolatey is the primary manually tested software path."
Write-Warn "WinGet is a secondary, minimal-compatibility path and is not package-equivalent to Chocolatey."


# ---------------------------------------------------------------------------
# Available components
# ---------------------------------------------------------------------------

Write-Section "Available Software Components"

Write-Host ""
Write-Host "Core / Transport:" -ForegroundColor Cyan
Write-Host "  1  - 31-software-packager-choco.manual.ps1   (primary supported path)"
Write-Host "  2  - 31-software-packager-winget.manual.ps1  (secondary native path)"
Write-Host "  3  - 32-software-baseline-choco.manual.ps1   (primary admin baseline)"
Write-Host "  4  - 32-software-baseline-winget.manual.ps1  (secondary minimal baseline)"

Write-Host ""
Write-Host "UX Baseline (MANUAL):" -ForegroundColor Cyan
Write-Host "  5  - 34-software-ux-choco.manual.ps1         (primary curated UX set)"
Write-Host "  6  - 34-software-ux-winget.manual.ps1        (secondary reduced UX set)"

Write-Host ""
Write-Host "  0  - Exit"


# ---------------------------------------------------------------------------
# Selection
# ---------------------------------------------------------------------------

$choice = Read-Host "Select action (number)"

switch ($choice) {

    "1" {
        Write-Info "Selected: Chocolatey packager"
        Invoke-SoftwareAction "31-software-packager-choco.manual.ps1"
    }

    "2" {
        Write-Warn "Selected: WinGet packager (secondary native path)"
        Invoke-SoftwareAction "31-software-packager-winget.manual.ps1"
    }

    "3" {
        Write-Info "Selected: Baseline software set (Chocolatey)"
        Invoke-SoftwareAction "32-software-baseline-choco.manual.ps1"
    }

    "4" {
        Write-Warn "Selected: Baseline software set (WinGet minimal compatibility path)"
        Invoke-SoftwareAction "32-software-baseline-winget.manual.ps1"
    }

    "5" {
        Write-Warn "UX baseline is a conscious decision."
        Write-Warn "This is NOT required for system operation."
        $confirm = Read-Host "Type YES to continue"

        if ($confirm -eq "YES") {
            Invoke-SoftwareAction "34-software-ux-choco.manual.ps1"
        } else {
            Write-Info "UX baseline execution aborted."
        }
    }

    "6" {
        Write-Warn "UX baseline is a conscious decision."
        Write-Warn "This is NOT required for system operation."
        Write-Warn "WinGet UX is a reduced secondary path, not a package-equivalent mirror of Chocolatey UX."
        $confirm = Read-Host "Type YES to continue"

        if ($confirm -eq "YES") {
            Invoke-SoftwareAction "34-software-ux-winget.manual.ps1"
        } else {
            Write-Info "UX baseline execution aborted."
        }
    }

    "0" {
        Write-Info "No action selected. Exiting orchestrator."
    }

    default {
        Write-Warn "Invalid selection. No action taken."
    }
}

Exit-Warn
