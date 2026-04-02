Describe "common.ps1 helper surface" {
    BeforeAll {
        $script:RepositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        . (Join-Path $script:RepositoryRoot "core/lib/common.ps1")
    }

    BeforeEach {
        $script:HadWarnings = $false
    }

    It "Write-WarnFlagged sets both script and referenced warning flags" {
        $flag = $false

        Mock Write-Warn {}

        Write-WarnFlagged -Message "warning-test" -Flag ([ref]$flag)

        $script:HadWarnings | Should -Be $true
        Assert-MockCalled Write-Warn -Times 1 -Exactly
    }

    It "Test-PowerShellVersion matches the current host major version" {
        $result = Test-PowerShellVersion

        $result | Should -Be ($PSVersionTable.PSVersion.Major -ge 7)
    }

    It "Set-RegistryPreference writes HKCU and mounted DefUser targets" {
        $createdPaths = @()
        $writtenTargets = @()

        Mock Test-Path {
            param($Path)

            switch ($Path) {
                "HKLM:\DefUser" { return $true }
                "HKCU:\Software\Test" { return $false }
                "HKLM:\DefUser\Software\Test" { return $false }
                default { return $false }
            }
        }

        Mock New-Item {
            param($Path)
            $script:createdPaths += $Path
        }

        Mock New-ItemProperty {
            param($Path, $Name, $Value, $PropertyType)
            $script:writtenTargets += [pscustomobject]@{
                Path         = $Path
                Name         = $Name
                Value        = $Value
                PropertyType = $PropertyType
            }
        }

        Mock Write-Info {}

        $script:createdPaths = $createdPaths
        $script:writtenTargets = $writtenTargets

        Set-RegistryPreference -KeyPath "Software\Test" -ValueName "Flag" -Value 1 -ValueType DWord

        $script:createdPaths.Count | Should -Be 2
        $script:createdPaths[0] | Should -Be "HKCU:\Software\Test"
        $script:createdPaths[1] | Should -Be "HKLM:\DefUser\Software\Test"

        $script:writtenTargets.Count | Should -Be 2
        $script:writtenTargets[0].Path | Should -Be "HKCU:\Software\Test"
        $script:writtenTargets[1].Path | Should -Be "HKLM:\DefUser\Software\Test"
        $script:writtenTargets[0].Name | Should -Be "Flag"
        $script:writtenTargets[0].Value | Should -Be 1
        $script:writtenTargets[0].PropertyType | Should -Be "DWord"
    }

    It "Write-Section emits the expected section header format" {
        Mock Write-Host {}

        Write-Section -Title "Section Title"

        Assert-MockCalled Write-Host -Times 2
        Assert-MockCalled Write-Host -ParameterFilter { $Object -eq "=== Section Title ===" } -Times 1
    }
}
