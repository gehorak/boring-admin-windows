$RepositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:BoringAdmin = Join-Path $RepositoryRoot "boring-admin.ps1"
$script:PowerShellExe = (Get-Process -Id $PID).Path

function Invoke-BoringAdminCapture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]] $Arguments
    )

    $output = & $script:PowerShellExe -NoProfile -ExecutionPolicy Bypass -File $script:BoringAdmin @Arguments 2>&1 | Out-String

    [pscustomobject]@{
        Output   = $output
        ExitCode = $LASTEXITCODE
    }
}
