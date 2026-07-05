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

    It "Get-Rfc3339Timestamp emits a local timestamp with explicit offset" {
        $timestamp = Get-Rfc3339Timestamp

        $timestamp | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$'
    }

    It "Get-StructuredErrorRecord returns the stable minimum error contract" {
        $record = Get-StructuredErrorRecord -ErrorId "test.error" -Message "failure" -ExitCode 1 -Scope "test-scope" -NextAction "retry safely"

        $record.scope | Should -Be "test-scope"
        $record.generatedAt | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$'
        $record.run_id | Should -Match '^[0-9a-f-]{36}$'
        $record.event_id | Should -Match '^[0-9a-f-]{36}$'
        $record.severity | Should -Be "error"
        $record.error_id | Should -Be "test.error"
        $record.exit_code | Should -Be 1
        $record.message | Should -Be "failure"
        $record.next_action | Should -Be "retry safely"
    }

    It "Get-StructuredEventRecord returns the stable minimum event contract" {
        $record = Get-StructuredEventRecord -RunId "run-123" -Severity "info" -Message "hello" -Scope "test-event" -Command "check" -Target "all" -ChangeId "chg-1" -Data @{ ok = $true }

        $record.scope | Should -Be "test-event"
        $record.generatedAt | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$'
        $record.run_id | Should -Be "run-123"
        $record.event_id | Should -Match '^[0-9a-f-]{36}$'
        $record.severity | Should -Be "info"
        $record.message | Should -Be "hello"
        $record.command | Should -Be "check"
        $record.target | Should -Be "all"
        $record.change_id | Should -Be "chg-1"
        $record.data.ok | Should -Be $true
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

    It "Test-BoringAdminNoColorRequested returns true when NO_COLOR is set" {
        $originalValue = $env:NO_COLOR
        $env:NO_COLOR = "1"

        try {
            Test-BoringAdminNoColorRequested | Should -BeTrue
        }
        finally {
            $env:NO_COLOR = $originalValue
        }
    }

    It "Write-BoringAdminHost omits ForegroundColor when NO_COLOR is set" {
        $originalValue = $env:NO_COLOR
        $env:NO_COLOR = "1"

        try {
            Mock Write-Host {}

            Write-BoringAdminHost -Message "[WARN] warning-text" -ForegroundColor Yellow

            Assert-MockCalled Write-Host -Times 1 -Exactly -ParameterFilter {
                $Object -eq "[WARN] warning-text" -and -not $PSBoundParameters.ContainsKey("ForegroundColor")
            }
        }
        finally {
            $env:NO_COLOR = $originalValue
        }
    }

    It "Write-BoringAdminHost omits ForegroundColor when output is redirected" {
        Mock Test-BoringAdminNoColorRequested { return $false }
        Mock Test-BoringAdminOutputRedirected { return $true }
        Mock Write-Host {}

        Write-BoringAdminHost -Message "[FAIL] redirected-output" -ForegroundColor Red

        Assert-MockCalled Write-Host -Times 1 -Exactly -ParameterFilter {
            $Object -eq "[FAIL] redirected-output" -and -not $PSBoundParameters.ContainsKey("ForegroundColor")
        }
    }

    It "Get-BoringAdminCommandResult returns an integer exit code and truncated output" {
        $result = Get-BoringAdminCommandResult -ExitCode 7 -Output ("x" * 20) -MaxOutputLength 10

        ($result.ExitCode -is [int]) | Should -BeTrue
        $result.ExitCode | Should -Be 7
        $result.Output | Should -Be "xxxxxxxxxx...[truncated]"
    }

    It "Invoke-BoringAdminApplyOperation records a partial failure without terminating the whole run" {
        Mock Write-Warn {}

        $null = Initialize-BoringAdminApplyResult -Target "consumer-noise"
        $result = Invoke-BoringAdminApplyOperation `
            -Id "consumer-noise.appx.installed.Microsoft.Clipchamp" `
            -Classification "consumer-noise" `
            -FailureReason "remove-installed-package-failed" `
            -FailureMessage "Failed to remove installed AppX package." `
            -Operation { throw "simulated failure" }

        $result.Success | Should -BeFalse
        $result.Reason | Should -Be "remove-installed-package-failed"
        $result.Error | Should -Match "simulated failure"
        $script:BoringAdminApplyResult.result | Should -Be "partial"
        $script:BoringAdminApplyResult.failed_items.Count | Should -Be 1
        $script:BoringAdminApplyResult.failed_items[0].id | Should -Be "consumer-noise.appx.installed.Microsoft.Clipchamp"
        $script:BoringAdminApplyResult.failed_items[0].classification | Should -Be "consumer-noise"
        $script:BoringAdminApplyResult.warnings.Count | Should -Be 1
        Assert-MockCalled Write-Warn -Times 1 -Exactly
    }

    It "Invoke-BoringAdminApplyOperation returns the scriptblock value on success" {
        $null = Initialize-BoringAdminApplyResult -Target "consumer-noise"
        $result = Invoke-BoringAdminApplyOperation `
            -Id "consumer-noise.registry.DisableConsumerFeatures" `
            -Classification "consumer-noise" `
            -FailureReason "set-registry-value-failed" `
            -FailureMessage "Failed to apply registry value." `
            -Operation { return 42 }

        $result.Success | Should -BeTrue
        $result.Value | Should -Be 42
        $script:BoringAdminApplyResult.result | Should -Be "completed"
        $script:BoringAdminApplyResult.failed_items.Count | Should -Be 0
        $script:BoringAdminApplyResult.warnings.Count | Should -Be 0
    }
}
