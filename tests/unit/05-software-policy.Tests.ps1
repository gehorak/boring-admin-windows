Describe "software policy helpers" {
    BeforeAll {
        $script:RepositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        . (Join-Path $script:RepositoryRoot "core/lib/config.ps1")
        . (Join-Path $script:RepositoryRoot "core/lib/software-inventory.ps1")
        $script:OriginalProfileEnv = $env:BORING_ADMIN_PROFILE
        $env:BORING_ADMIN_PROFILE = $null

        function New-TestProfilePath {
            [CmdletBinding(SupportsShouldProcess)]
            param(
                [scriptblock] $Mutator
            )

            $profilePath = Join-Path ([System.IO.Path]::GetTempPath()) ("boring-admin-profile-{0}.json" -f ([guid]::NewGuid().ToString("N")))
            $config = Get-Content -Raw -LiteralPath (Join-Path $script:RepositoryRoot "config/profiles/individual.example.json") | ConvertFrom-Json -ErrorAction Stop

            if ($Mutator) {
                & $Mutator $config
            }

            if ($PSCmdlet.ShouldProcess($profilePath, "Write test profile")) {
                $config | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $profilePath -Encoding UTF8
            }

            return $profilePath
        }
    }

    AfterAll {
        $env:BORING_ADMIN_PROFILE = $script:OriginalProfileEnv
    }

    It "rejects insecure HTTP Chocolatey sources" {
        $profilePath = New-TestProfilePath {
            param($config)
            $config.software.packageManager = "choco"
            $config.software.baseline[0].source = "http://example.invalid/api/v2/"
        }

        try {
            { Import-BoringAdminConfig -ProfilePath $profilePath } | Should -Throw "*unsupported source*Chocolatey package sources*"
        }
        finally {
            Remove-Item -LiteralPath $profilePath -Force
        }
    }

    It "accepts explicit WinGet source identifiers" {
        $profilePath = New-TestProfilePath {
            param($config)
            $config.software.packageManager = "winget"
            foreach ($package in @($config.software.baseline)) {
                $package.source = "winget"
            }
        }

        try {
            $config = Import-BoringAdminConfig -ProfilePath $profilePath

            $config.software.packageManager | Should -Be "winget"
            $config.software.baseline[0].source | Should -Be "winget"
        }
        finally {
            Remove-Item -LiteralPath $profilePath -Force
        }
    }

    It "rejects URL-like WinGet sources" {
        $profilePath = New-TestProfilePath {
            param($config)
            $config.software.packageManager = "winget"
        }

        try {
            { Import-BoringAdminConfig -ProfilePath $profilePath } | Should -Throw "*unsupported source*WinGet package sources*"
        }
        finally {
            Remove-Item -LiteralPath $profilePath -Force
        }
    }

    It "blocks install when package inventory is unknown" {
        $decision = Get-BoringAdminPackagePreflightDecision `
            -Package ([pscustomobject]@{ id = "git"; required = $true }) `
            -ObservedState ([pscustomobject]@{
                Success = $false
                State   = "unknown"
                Version = $null
                Error   = "WinGet inventory output is not trustworthy for locale-safe package absence detection."
            })

        $decision.BlockInstall | Should -BeTrue
        $decision.Status | Should -Be "blocked"
        $decision.FailureReason | Should -Be "precheck-state-unknown"
        $decision.FailureClassification | Should -Be "required"
        $decision.WarningMessage | Should -Match "could not be safely verified before install"
    }

    It "allows install planning when the package is simply missing" {
        $decision = Get-BoringAdminPackagePreflightDecision `
            -Package ([pscustomobject]@{ id = "git"; required = $false }) `
            -ObservedState ([pscustomobject]@{
                Success = $true
                State   = "missing"
                Version = $null
                Error   = $null
            })

        $decision.BlockInstall | Should -BeFalse
        $decision.Status | Should -Be "install-needed"
        $decision.FailureReason | Should -Be $null
        $decision.FailureClassification | Should -Be "none"
    }
}
