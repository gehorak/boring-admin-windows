<#
===============================================================================
core/lib/ux.ps1 — UX CORE (v002)

PURPOSE
-------
Provide a minimal, explicit, CLI-facing UX layer for boring-admin tools.

This file EXISTS TO:
- unify visual output (sections, messages, structure)
- provide a consistent output vocabulary
- serve as the ONLY place for NEW UX behavior in v002

This file DOES NOT:
- read or inspect system state
- make decisions or validations
- control execution flow
- exit the process
- store or mutate state
- import or depend on other libraries (including common.ps1)

DESIGN PRINCIPLES
-----------------
- visual only
- text in, text out
- no logic, no branching
- no side effects except console output
- duplication over coupling (intentional)

SCOPE
-----
- CLI-facing, interactive output only
- Not intended for background jobs or logging pipelines

FORBIDDEN (CONTRACT)
--------------------
The following MUST NEVER appear in this file:
- if / switch / try / catch
- loops of any kind
- state ($script:, $global:)
- exit / throw / return values
- environment or system inspection
- confirmation, validation, or guidance helpers
===============================================================================
#>

# -----------------------------------------------------------------------------
# CONTEXT (visual prefix only)
# -----------------------------------------------------------------------------
# Context is OPTIONAL and purely textual.
# Caller is responsible for providing meaningful content.
# -----------------------------------------------------------------------------

function Ux-Context {
    param (
        [Parameter(Mandatory)]
        [string] $Label
    )

    Write-Host "[$Label]" -NoNewline -ForegroundColor DarkGray
    Write-Host " " -NoNewline
}

# -----------------------------------------------------------------------------
# STRUCTURE / HIERARCHY
# -----------------------------------------------------------------------------

function Ux-H1 {
    param (
        [Parameter(Mandatory)]
        [string] $Title
    )

    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
}

function Ux-H2 {
    param (
        [Parameter(Mandatory)]
        [string] $Title
    )

    Write-Host ""
    Write-Host "-- $Title --" -ForegroundColor DarkCyan
}

function Ux-Step {
    param (
        [Parameter(Mandatory)]
        [string] $Title
    )

    Write-Host "-> $Title" -ForegroundColor Gray
}

# -----------------------------------------------------------------------------
# MESSAGE TYPES (OUTPUT VOCABULARY)
# -----------------------------------------------------------------------------

function Ux-Info {
    param (
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-Host "[INFO] $Message" -ForegroundColor White
}

function Ux-Warn {
    param (
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Ux-Ok {
    param (
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-Host "[OK]   $Message"
}

function Ux-Fail {
    param (
        [Parameter(Mandatory)]
        [string] $Message
    )

    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

# -----------------------------------------------------------------------------
# SPACING / VISUAL SEPARATORS
# -----------------------------------------------------------------------------

function Ux-Spacer {
    <#
    Visual separation between logical blocks.
    No semantic meaning.
    #>
    Write-Host ""
}

function Ux-Divider {
    <#
    Visual separation between major sections.
    Implies a stronger break than a spacer.
    #>
    Write-Host "--------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
}

# -----------------------------------------------------------------------------
# END OF FILE
