Describe "software inventory helpers" {
    BeforeAll {
        $script:RepositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        . (Join-Path $script:RepositoryRoot "core/lib/software-inventory.ps1")
    }

    It "ConvertTo-BoringAdminChocolateyPackageState reports present when the expected version matches" {
        $result = ConvertTo-BoringAdminChocolateyPackageState -PackageId "git" -ExpectedVersion "2.45.1" -Output "git|2.45.1" -ExitCode 0

        $result.Success | Should -BeTrue
        $result.State | Should -Be "present"
        $result.Version | Should -Be "2.45.1"
        $result.Source | Should -Be "choco"
    }

    It "ConvertTo-BoringAdminWinGetPackageState reports version drift when the installed version differs" {
        $result = ConvertTo-BoringAdminWinGetPackageState -PackageId "Git.Git" -ExpectedVersion "2.45.1" -Output @'
Name                           Id        Version Source
-------------------------------------------------------
Git                            Git.Git   2.44.0  winget
'@ -ExitCode 0

        $result.Success | Should -BeTrue
        $result.State | Should -Be "version-drift"
        $result.Version | Should -Be "2.44.0"
    }

    It "ConvertTo-BoringAdminWinGetPackageState treats a header-only table as locale-safe missing" {
        $result = ConvertTo-BoringAdminWinGetPackageState -PackageId "Git.Git" -ExpectedVersion "2.45.1" -Output @'
Name                           Id        Version Source
-------------------------------------------------------
'@ -ExitCode 0

        $result.Success | Should -BeTrue
        $result.State | Should -Be "missing"
        $result.Version | Should -Be $null
    }

    It "ConvertTo-BoringAdminWinGetPackageState does not treat Czech textual output as trusted missing" {
        $result = ConvertTo-BoringAdminWinGetPackageState -PackageId "Git.Git" -ExpectedVersion "2.45.1" -Output 'Nebyl nalezen zadny nainstalovany balicek odpovidajici vstupnim kriteriim.' -ExitCode 0

        $result.Success | Should -BeFalse
        $result.State | Should -Be "unknown"
        $result.Error | Should -Match 'locale-safe package absence detection'
    }

    It "ConvertTo-BoringAdminWinGetPackageState fails safely on unparseable output" {
        $result = ConvertTo-BoringAdminWinGetPackageState -PackageId "Git.Git" -ExpectedVersion "2.45.1" -Output 'unexpected output without a parseable table or package row' -ExitCode 0

        $result.Success | Should -BeFalse
        $result.State | Should -Be "unknown"
        $result.Error | Should -Not -BeNullOrEmpty
    }
}
