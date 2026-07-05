$RepositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:BoringAdmin = Join-Path $RepositoryRoot "boring-admin.ps1"
$script:PowerShellExe = (Get-Process -Id $PID).Path

function Invoke-BoringAdminCapture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]] $Arguments,

        [hashtable] $Environment = @{}
    )

    $originalEnvironment = @{}
    foreach ($name in $Environment.Keys) {
        $originalEnvironment[$name] = [System.Environment]::GetEnvironmentVariable($name, "Process")
        [System.Environment]::SetEnvironmentVariable($name, [string]$Environment[$name], "Process")
    }

    try {
        $output = & $script:PowerShellExe -NoProfile -File $script:BoringAdmin @Arguments 2>&1 | Out-String
    }
    finally {
        foreach ($name in $Environment.Keys) {
            [System.Environment]::SetEnvironmentVariable($name, $originalEnvironment[$name], "Process")
        }
    }

    [pscustomobject]@{
        Output   = $output
        ExitCode = $LASTEXITCODE
    }
}

function Get-SmokeFixtureDirectory {
    return Join-Path $PSScriptRoot "fixtures\audit-export"
}

function Get-NormalizedBoringAdminOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Output
    )

    $normalized = ($Output -replace "`r`n", "`n").Trim()
    $normalized = $normalized -replace '(?m)^\[INFO\] Generated at: .+$', '[INFO] Generated at: <generatedAt>'
    $normalized = $normalized -replace '(?m)^\[INFO\] Computer name: .+$', '[INFO] Computer name: <computerName>'
    $normalized = $normalized -replace '(?m)^\[INFO\] run_id: .+$', '[INFO] run_id: <run_id>'
    $normalized = $normalized -replace '(?m)^\[INFO\] change_id: .+$', '[INFO] change_id: <change_id>'
    $normalized = $normalized -replace '(?m)^\[INFO\] audit_log: .+$', '[INFO] audit_log: <audit_log>'
    return $normalized
}

function Get-SmokeSnapshot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Name
    )

    $snapshotPath = Join-Path $PSScriptRoot ("snapshots\{0}" -f $Name)
    return Get-NormalizedBoringAdminOutput -Output (Get-Content -Raw -LiteralPath $snapshotPath)
}
