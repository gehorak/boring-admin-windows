Describe "config.ps1 loader boundary" {
    BeforeAll {
        $script:RepositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        . (Join-Path $script:RepositoryRoot "core/lib/config.ps1")
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

    It "imports the public example profile successfully" {
        $config = Import-BoringAdminConfig -ProfilePath "config/profiles/individual.example.json"

        $config.profileName | Should -Be "individual-example"
        $config.profileType | Should -Be "example"
    }

    It "fails clearly when an explicit profile path is missing" {
        { Import-BoringAdminConfig -ProfilePath "config/profiles/does-not-exist.json" } | Should -Throw "*Profile not found*"
    }

    It "prefers an explicit profile path over BORING_ADMIN_PROFILE" {
        $env:BORING_ADMIN_PROFILE = "config/profiles/individual.example.json"

        $resolved = Resolve-BoringAdminProfilePath -ProfilePath "config/profiles/individual.example.json"

        $resolved | Should -Match 'individual\.example\.json$'
    }

    It "uses BORING_ADMIN_PROFILE when no explicit profile path is provided" {
        $env:BORING_ADMIN_PROFILE = "config/profiles/individual.example.json"

        $resolved = Resolve-BoringAdminProfilePath

        $resolved | Should -Match 'individual\.example\.json$'
        $env:BORING_ADMIN_PROFILE = $null
    }

    It "rejects example profiles for state-changing host and identity work" {
        $config = Import-BoringAdminConfig -ProfilePath "config/profiles/individual.example.json"

        { Assert-BoringAdminWritableProfile -Config $config -Operation "test operation" } | Should -Throw "*requires a local profile*"
    }

    It "returns schema v2 package objects and keeps non-baseline classes explicit" {
        $config = Import-BoringAdminConfig -ProfilePath "config/profiles/individual.example.json"
        $baselinePackages = Get-BoringAdminSoftwarePackageList -Config $config -PackageClass baseline -PackageManager choco
        $networkPackages = Get-BoringAdminSoftwarePackageList -Config $config -PackageClass network -PackageManager choco
        $remoteAccessPackages = Get-BoringAdminSoftwarePackageList -Config $config -PackageClass remoteAccess -PackageManager choco

        $baselinePackages.Count | Should -BeGreaterThan 0
        $baselinePackages[0].packageManager | Should -Be "choco"
        $baselinePackages[0].packageClass | Should -Be "baseline"
        $baselinePackages[0].id | Should -Not -BeNullOrEmpty
        $baselinePackages[0].version | Should -Not -BeNullOrEmpty
        $baselinePackages[0].source | Should -Not -BeNullOrEmpty
        $baselinePackages[0].reviewedPublisher | Should -Not -BeNullOrEmpty
        ($baselinePackages[0].required -is [bool]) | Should -BeTrue

        @($networkPackages).Count | Should -Be 0
        @($remoteAccessPackages).Count | Should -Be 0
    }

    It "rejects duplicate managed account names before write-capable identity work" {
        $profilePath = New-TestProfilePath {
            param($config)
            $config.accounts.recoveryAdminName = "admin.local"
        }

        try {
            { Import-BoringAdminConfig -ProfilePath $profilePath } | Should -Throw "*Managed account names must be unique*"
        }
        finally {
            Remove-Item -LiteralPath $profilePath -Force
        }
    }

    It "rejects built-in Windows account names in managed profile fields" {
        $profilePath = New-TestProfilePath {
            param($config)
            $config.accounts.primaryAdminName = "Administrator"
        }

        try {
            { Import-BoringAdminConfig -ProfilePath $profilePath } | Should -Throw "*reserved built-in Windows account name*"
        }
        finally {
            Remove-Item -LiteralPath $profilePath -Force
        }
    }

    It "rejects invalid workstation computer names" {
        $profilePath = New-TestProfilePath {
            param($config)
            $config.hostIdentity.computerName = "WORKSTATION NAME"
        }

        try {
            { Import-BoringAdminConfig -ProfilePath $profilePath } | Should -Throw "*hostIdentity.computerName*"
        }
        finally {
            Remove-Item -LiteralPath $profilePath -Force
        }
    }

    It "rejects invalid local Windows host identity values" {
        $profilePath = New-TestProfilePath {
            param($config)
            $config.hostIdentity.timeZone = "Not A Real Time Zone"
        }

        try {
            { Import-BoringAdminConfig -ProfilePath $profilePath } | Should -Throw "*hostIdentity.timeZone*"
        }
        finally {
            Remove-Item -LiteralPath $profilePath -Force
        }
    }

    It "rejects invalid local Windows system locale values" {
        $profilePath = New-TestProfilePath {
            param($config)
            $config.hostIdentity.systemLocale = "xx-Invalid"
        }

        try {
            { Import-BoringAdminConfig -ProfilePath $profilePath } | Should -Throw "*hostIdentity.systemLocale*"
        }
        finally {
            Remove-Item -LiteralPath $profilePath -Force
        }
    }
}
