Describe "machine-readable check export contracts" {
    BeforeAll {
        $script:RepositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $script:BoringAdmin = Join-Path $script:RepositoryRoot "boring-admin.ps1"
        $script:PowerShellExe = (Get-Process -Id $PID).Path
        $script:AuditFixtureDirectory = Join-Path $script:RepositoryRoot "tests\smoke\fixtures\audit-export"
        $script:Rfc3339Pattern = '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$'
        $script:VerifyJsonContracts = @(
            @{
                AggregateScope = "security"
                VerifyScope    = "security-visibility"
                File           = "scripts\verify\security\29-security-visibility.verify.ps1"
                DomainFields   = @("security")
            },
            @{
                AggregateScope = "software"
                VerifyScope    = "software-inventory"
                File           = "scripts\verify\software\39-software-inventory.verify.ps1"
                DomainFields   = @("packageManager", "inventory")
            },
            @{
                AggregateScope = "identity"
                VerifyScope    = "identity-local-visibility"
                File           = "scripts\verify\identity\46-identity-local-visibility.verify.ps1"
                DomainFields   = @("identity")
            },
            @{
                AggregateScope = "host"
                VerifyScope    = "host-identity-visibility"
                File           = "scripts\verify\host\55-host-identity-visibility.verify.ps1"
                DomainFields   = @("host")
            },
            @{
                AggregateScope = "system"
                VerifyScope    = "system-state"
                File           = "scripts\verify\system\90-system-state.verify.ps1"
                DomainFields   = @("system")
            },
            @{
                AggregateScope = "recovery"
                VerifyScope    = "recovery-visibility"
                File           = "scripts\verify\recovery\60-recovery-visibility.verify.ps1"
                DomainFields   = @("recovery")
            }
        )
        $script:InvokeCheckExportWithFixtures = {
            $originalFixtureDirectory = [System.Environment]::GetEnvironmentVariable("BORING_ADMIN_VERIFY_FIXTURE_DIR", "Process")
            [System.Environment]::SetEnvironmentVariable("BORING_ADMIN_VERIFY_FIXTURE_DIR", $script:AuditFixtureDirectory, "Process")

            try {
                $output = & $script:PowerShellExe -NoProfile -File $script:BoringAdmin check --json 2>&1 | Out-String
            }
            finally {
                [System.Environment]::SetEnvironmentVariable("BORING_ADMIN_VERIFY_FIXTURE_DIR", $originalFixtureDirectory, "Process")
            }

            return [pscustomobject]@{
                Output   = $output
                ExitCode = $LASTEXITCODE
            }
        }
    }

    It "boring-admin check json returns parse-valid JSON with the guaranteed top-level fields" {
        $result = & $script:InvokeCheckExportWithFixtures

        $result.ExitCode | Should -Be 0

        $export = $result.Output | ConvertFrom-Json -ErrorAction Stop
        $export.PSObject.Properties.Name | Should -Contain "command"
        $export.PSObject.Properties.Name | Should -Contain "target"
        $export.PSObject.Properties.Name | Should -Contain "generatedAt"
        $export.PSObject.Properties.Name | Should -Contain "run_id"
        $export.PSObject.Properties.Name | Should -Contain "event_id"
        $export.PSObject.Properties.Name | Should -Contain "severity"
        $export.PSObject.Properties.Name | Should -Contain "exit_code"
        $export.PSObject.Properties.Name | Should -Contain "data"
        $export.command | Should -Be "check"
        $export.target | Should -Be "all"
        ([DateTimeOffset]$export.generatedAt).ToString("yyyy-MM-ddTHH:mm:sszzz", [System.Globalization.CultureInfo]::InvariantCulture) | Should -Match $script:Rfc3339Pattern
        $export.data.result.scope | Should -Be "check-export"
        $export.data.result.computerName | Should -Not -BeNullOrEmpty
        (@($export.data.result.results).Count -gt 0) | Should -BeTrue
        ($export.data.result.results -is [System.Array]) | Should -BeTrue
    }

    It "check json exposes the current declared aggregate scopes without depending on ordering" {
        $result = & $script:InvokeCheckExportWithFixtures
        $export = $result.Output | ConvertFrom-Json -ErrorAction Stop

        $actualScopes = @($export.data.result.results | ForEach-Object { $_.scope } | Sort-Object -Unique)
        $expectedScopes = @($script:VerifyJsonContracts | ForEach-Object { $_.AggregateScope } | Sort-Object)

        $actualScopes.Count | Should -Be $expectedScopes.Count
        Compare-Object -ReferenceObject $expectedScopes -DifferenceObject $actualScopes | Should -BeNullOrEmpty

        foreach ($resultItem in $export.data.result.results) {
            $resultItem.PSObject.Properties.Name | Should -Contain "scope"
            $resultItem.PSObject.Properties.Name | Should -Contain "data"
        }
    }

    It "check json surfaces the documented common per-scope JSON fields and current domain sections" {
        $result = & $script:InvokeCheckExportWithFixtures
        $export = $result.Output | ConvertFrom-Json -ErrorAction Stop

        foreach ($contract in $script:VerifyJsonContracts) {
            $resultItem = @($export.data.result.results | Where-Object { $_.scope -eq $contract.AggregateScope })
            $resultItem.Count | Should -Be 1

            $data = $resultItem[0].data
            $data.PSObject.Properties.Name | Should -Contain "scope"
            $data.PSObject.Properties.Name | Should -Contain "generatedAt"
            $data.PSObject.Properties.Name | Should -Contain "warnings"
            $data.scope | Should -Be $contract.VerifyScope
            ([DateTimeOffset]$data.generatedAt).ToString("yyyy-MM-ddTHH:mm:sszzz", [System.Globalization.CultureInfo]::InvariantCulture) | Should -Match $script:Rfc3339Pattern
            ($data.warnings -is [System.Array]) | Should -BeTrue

            foreach ($domainField in $contract.DomainFields) {
                $data.PSObject.Properties.Name | Should -Contain $domainField
            }
        }
    }

    It "verify scripts keep the documented machine-readable JSON minimum contract" {
        foreach ($contract in $script:VerifyJsonContracts) {
            $filePath = Join-Path $script:RepositoryRoot $contract.File
            $content = Get-Content -Raw -LiteralPath $filePath

            $content | Should -Match '\[ValidateSet\("Text", "Json"\)\]'
            $content | Should -Match '\[string\]\s+\$OutputFormat\s*=\s*"Text"'
            $content | Should -Match '\$OutputFormat\s+-eq\s+"Json"'
            $content | Should -Match ('scope\s*=\s*"{0}"' -f [regex]::Escape($contract.VerifyScope))
            $content | Should -Match 'generatedAt\s*=\s*Get-Rfc3339Timestamp'
            $content | Should -Match 'warnings\s*=\s*@\(\$warnings\)'
            $content | Should -Match 'ConvertTo-Json'

            foreach ($domainField in $contract.DomainFields) {
                $content | Should -Match ('{0}\s*=' -f [regex]::Escape($domainField))
            }
        }
    }
}
