Set-StrictMode -Version Latest

function Get-RepositoryRoot {
    return (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

function Get-TrackedRepositoryFiles {
    param(
        [string[]] $Extensions = @("*.md", "*.ps1", "Makefile*")
    )

    $root = Get-RepositoryRoot
    $git = Get-Command git -ErrorAction SilentlyContinue

    if (-not $git) {
        return Get-RepositoryFiles -Extensions $Extensions
    }

    $tracked = & git -C $root ls-files
    if ($LASTEXITCODE -ne 0) {
        return Get-RepositoryFiles -Extensions $Extensions
    }

    $files = foreach ($relativePath in $tracked) {
        $fullPath = Join-Path $root $relativePath

        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            continue
        }

        if ($relativePath -like ".ai/*" -or $relativePath -like ".vscode/*") {
            continue
        }

        foreach ($pattern in $Extensions) {
            if ($relativePath -like $pattern) {
                Get-Item -LiteralPath $fullPath
                break
            }
        }
    }

    return $files | Sort-Object FullName -Unique
}

function Get-RepositoryFiles {
    param(
        [string[]] $Extensions = @("*.md", "*.ps1", "Makefile*")
    )

    $root = Get-RepositoryRoot
    $files = @()

    foreach ($pattern in $Extensions) {
        $files += Get-ChildItem -Path $root -Recurse -File -Filter $pattern
    }

    return $files | Where-Object {
        $_.FullName -notmatch '\\\.git\\' -and
        $_.FullName -notmatch '\\\.ai\\' -and
        $_.FullName -notmatch '\\\.vscode\\'
    } | Sort-Object FullName -Unique
}

function Write-CheckResult {
    param(
        [Parameter(Mandatory)]
        [string] $Check,

        [Parameter(Mandatory)]
        [bool] $Passed,

        [string] $Message = ""
    )

    if ($Passed) {
        Write-Host "[PASS] $Check" -ForegroundColor Green
    }
    else {
        Write-Host "[FAIL] $Check" -ForegroundColor Red
    }

    if ($Message) {
        Write-Host "       $Message"
    }
}

function Format-RelativePath {
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    $root = Get-RepositoryRoot
    return $Path.Replace($root + "\", "")
}
