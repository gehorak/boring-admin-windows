Describe "boring-admin entrypoint smoke checks" {
    BeforeAll {
        . (Join-Path $PSScriptRoot "Smoke-Helpers.ps1")
        $script:RepositoryRoot = $RepositoryRoot
        $script:AuditFixtureDirectory = Get-SmokeFixtureDirectory
    }

    It "help exits successfully and matches the public snapshot" {
        $result = Invoke-BoringAdminCapture -Arguments @("help")
        $result.ExitCode | Should -Be 0
        (Get-NormalizedBoringAdminOutput -Output $result.Output) | Should -Be (Get-SmokeSnapshot -Name "help.txt")
    }

    It "version exits successfully and matches the public snapshot" {
        $result = Invoke-BoringAdminCapture -Arguments @("version")
        $result.ExitCode | Should -Be 0
        (Get-NormalizedBoringAdminOutput -Output $result.Output) | Should -Be (Get-SmokeSnapshot -Name "version.txt")
    }

    It "version json exits successfully with the public machine-readable metadata" {
        $result = Invoke-BoringAdminCapture -Arguments @("version", "--json")
        $result.ExitCode | Should -Be 0

        $record = $result.Output | ConvertFrom-Json -ErrorAction Stop
        $record.command | Should -Be "version"
        $record.severity | Should -Be "info"
        $record.exit_code | Should -Be 0
        $record.run_id | Should -Not -BeNullOrEmpty
        $record.event_id | Should -Not -BeNullOrEmpty
        $record.data.architecture_surface | Should -Be "v002"
        $record.data.public_contract | Should -Be "sprint7"
    }

    It "check json exits successfully with fixture data and matches the public schema" {
        $result = Invoke-BoringAdminCapture -Arguments @("check", "--json") -Environment @{
            BORING_ADMIN_VERIFY_FIXTURE_DIR = $script:AuditFixtureDirectory
        }

        $result.ExitCode | Should -Be 0
        ([regex]::Matches($result.Output, '"generatedAt"\s*:\s*"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}"')).Count | Should -Be 8

        $record = $result.Output | ConvertFrom-Json -ErrorAction Stop
        $record.command | Should -Be "check"
        $record.target | Should -Be "all"
        $record.exit_code | Should -Be 0
        $record.data.result.scope | Should -Be "check-export"
        $record.data.result.computerName | Should -Not -BeNullOrEmpty
        $record.data.result.results.Count | Should -Be 6
        (@($record.data.result.results.scope) -join ",") | Should -Be "security,software,identity,host,system,recovery"

        $expectedDomainFields = @{
            security = @("security")
            software = @("packageManager", "inventory")
            identity = @("identity")
            host     = @("host")
            system   = @("system")
            recovery = @("recovery")
        }

        foreach ($resultItem in $record.data.result.results) {
            $resultItem.data.scope | Should -Match '.+-visibility$|system-state|software-inventory'
            $resultItem.data.PSObject.Properties.Name | Should -Contain "warnings"

            foreach ($fieldName in $expectedDomainFields[$resultItem.scope]) {
                $resultItem.data.PSObject.Properties.Name | Should -Contain $fieldName
            }
        }

        $software = @($record.data.result.results | Where-Object { $_.scope -eq "software" })[0].data
        $software.PSObject.Properties.Name | Should -Contain "computerName"
        $software.packageManager.PSObject.Properties.Name | Should -Contain "configured"
        $software.packageManager.chocolatey.PSObject.Properties.Name | Should -Contain "present"
        $software.packageManager.chocolatey.PSObject.Properties.Name | Should -Contain "version"
        $software.packageManager.winget.PSObject.Properties.Name | Should -Contain "present"
        $software.packageManager.winget.PSObject.Properties.Name | Should -Contain "version"
        $software.inventory.PSObject.Properties.Name | Should -Contain "baselinePackageCount"
        $software.inventory.PSObject.Properties.Name | Should -Contain "baselinePackages"
        $software.inventory.baselinePackages[0].PSObject.Properties.Name | Should -Contain "id"
        $software.inventory.baselinePackages[0].PSObject.Properties.Name | Should -Contain "expectedVersion"
        $software.inventory.baselinePackages[0].PSObject.Properties.Name | Should -Contain "observedVersion"
        $software.inventory.baselinePackages[0].PSObject.Properties.Name | Should -Contain "required"
        $software.inventory.baselinePackages[0].PSObject.Properties.Name | Should -Contain "source"
        $software.inventory.baselinePackages[0].PSObject.Properties.Name | Should -Contain "reviewedPublisher"
        $software.inventory.baselinePackages[0].PSObject.Properties.Name | Should -Contain "status"

        $identity = @($record.data.result.results | Where-Object { $_.scope -eq "identity" })[0].data.identity
        $identity.PSObject.Properties.Name | Should -Contain "administratorsGroupName"
        $identity.localUsers[0].PSObject.Properties.Name | Should -Contain "name"
        $identity.localUsers[0].PSObject.Properties.Name | Should -Contain "enabled"
        $identity.localUsers[0].PSObject.Properties.Name | Should -Contain "passwordExpires"
        $identity.administratorsGroup[0].PSObject.Properties.Name | Should -Contain "name"
        $identity.managedAccounts[0].PSObject.Properties.Name | Should -Contain "name"
        $identity.managedAccounts[0].PSObject.Properties.Name | Should -Contain "exists"
        $identity.managedAccounts[0].PSObject.Properties.Name | Should -Contain "enabled"
        $identity.PSObject.Properties.Name | Should -Contain "disabledAdministrators"

        $hostResult = @($record.data.result.results | Where-Object { $_.scope -eq "host" })[0].data.host
        $hostResult.PSObject.Properties.Name | Should -Contain "current"
        $hostResult.PSObject.Properties.Name | Should -Contain "desired"
        $hostResult.PSObject.Properties.Name | Should -Contain "drift"
        $hostResult.PSObject.Properties.Name | Should -Contain "pendingRebootSignals"
        $hostResult.PSObject.Properties.Name | Should -Contain "nextStepReady"
        $hostResult.current.PSObject.Properties.Name | Should -Contain "computerName"
        $hostResult.current.PSObject.Properties.Name | Should -Contain "timeZone"
        $hostResult.current.PSObject.Properties.Name | Should -Contain "systemLocale"
        $hostResult.desired.PSObject.Properties.Name | Should -Contain "computerName"
        $hostResult.desired.PSObject.Properties.Name | Should -Contain "timeZone"
        $hostResult.desired.PSObject.Properties.Name | Should -Contain "systemLocale"
        $hostResult.drift.PSObject.Properties.Name | Should -Contain "computerName"
        $hostResult.drift.PSObject.Properties.Name | Should -Contain "timeZone"
        $hostResult.drift.PSObject.Properties.Name | Should -Contain "systemLocale"
    }

    It "check summary exits successfully and matches the public snapshot" {
        $result = Invoke-BoringAdminCapture -Arguments @("check", "--summary") -Environment @{
            BORING_ADMIN_VERIFY_FIXTURE_DIR = $script:AuditFixtureDirectory
        }

        $result.ExitCode | Should -Be 0
        (Get-NormalizedBoringAdminOutput -Output $result.Output) | Should -Be (Get-SmokeSnapshot -Name "audit-summary.txt")
    }

    It "compatibility alias for machine-readable check output remains available" {
        $result = Invoke-BoringAdminCapture -Arguments @("audit", "export") -Environment @{
            BORING_ADMIN_VERIFY_FIXTURE_DIR = $script:AuditFixtureDirectory
        }

        $result.ExitCode | Should -Be 0
        ($result.Output | ConvertFrom-Json -ErrorAction Stop).command | Should -Be "check"
    }

    It "plan bootstrap json exits successfully as capability preview" {
        $result = Invoke-BoringAdminCapture -Arguments @("plan", "bootstrap", "--json")
        $result.ExitCode | Should -Be 0

        $record = $result.Output | ConvertFrom-Json -ErrorAction Stop
        $record.command | Should -Be "plan"
        $record.target | Should -Be "bootstrap"
        $record.exit_code | Should -Be 0
        $record.data.plan_kind | Should -Be "capability-preview"
        $record.data.change_count | Should -Be 0
        $record.data.state_determination | Should -Be "unavailable"
    }

    It "plan host json exits 0 when fixture data shows no drift" {
        $profilePath = Join-Path ([System.IO.Path]::GetTempPath()) ("boring-admin-profile-{0}.json" -f ([guid]::NewGuid().ToString("N")))
        $profileContent = Get-Content -Raw -LiteralPath (Join-Path $script:RepositoryRoot "config/profiles/individual.example.json")
        $profileContent = $profileContent -replace '"profileType": "example"', '"profileType": "local"'
        [System.IO.File]::WriteAllText($profilePath, $profileContent, [System.Text.Encoding]::UTF8)

        try {
            $result = Invoke-BoringAdminCapture -Arguments @("plan", "host", "--json", "--profile", $profilePath) -Environment @{
                BORING_ADMIN_VERIFY_FIXTURE_DIR = $script:AuditFixtureDirectory
            }
        }
        finally {
            Remove-Item -LiteralPath $profilePath -Force
        }

        $result.ExitCode | Should -Be 0
        $record = $result.Output | ConvertFrom-Json -ErrorAction Stop
        $record.data.plan_kind | Should -Be "state-diff"
        $record.data.change_count | Should -Be 0
        $record.data.state_determination | Should -Be "complete"
    }

    It "plan consumer-noise json exits 10 when fixture data shows pending overlay changes" {
        $fixtureDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $fixtureDirectory -Force | Out-Null

        try {
            @'
{
  "scope": "consumer-noise-plan",
  "appx": [
    {
      "id": "Microsoft.Clipchamp",
      "installed": true,
      "provisioned": false
    }
  ],
  "registry": [
    {
      "path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\CloudContent",
      "name": "DisableConsumerFeatures",
      "current": 0,
      "desired": 1
    }
  ],
  "warnings": []
}
'@ | Set-Content -LiteralPath (Join-Path $fixtureDirectory "consumer-noise.json") -Encoding UTF8

            $result = Invoke-BoringAdminCapture -Arguments @("plan", "consumer-noise", "--json") -Environment @{
                BORING_ADMIN_VERIFY_FIXTURE_DIR = $fixtureDirectory
            }
        }
        finally {
            Remove-Item -LiteralPath $fixtureDirectory -Force -Recurse
        }

        $result.ExitCode | Should -Be 10
        $record = $result.Output | ConvertFrom-Json -ErrorAction Stop
        $record.target | Should -Be "consumer-noise"
        $record.data.change_count | Should -Be 2
        $record.data.changes[0].id | Should -Match '^consumer-noise\.'
    }

    It "apply consumer-noise dry-run stays on the public boundary" {
        $fixtureDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $fixtureDirectory -Force | Out-Null

        try {
            @'
{
  "scope": "consumer-noise-plan",
  "appx": [],
  "registry": [
    {
      "path": "HKCU:\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced",
      "name": "HideFileExt",
      "current": 1,
      "desired": 0
    }
  ],
  "warnings": []
}
'@ | Set-Content -LiteralPath (Join-Path $fixtureDirectory "consumer-noise.json") -Encoding UTF8

            $result = Invoke-BoringAdminCapture -Arguments @("apply", "consumer-noise", "--change-id", "INC-1", "--dry-run") -Environment @{
                BORING_ADMIN_VERIFY_FIXTURE_DIR = $fixtureDirectory
            }
        }
        finally {
            Remove-Item -LiteralPath $fixtureDirectory -Force -Recurse
        }

        $result.ExitCode | Should -Be 10
        $result.Output | Should -Match 'Plan :: consumer-noise'
    }

    It "compatibility env preflight alias exits successfully" {
        $result = Invoke-BoringAdminCapture -Arguments @("check-env")
        $result.ExitCode | Should -Be 0
    }

    It "apply security fails fast and matches the public snapshot" {
        $result = Invoke-BoringAdminCapture -Arguments @("apply", "security")
        $result.ExitCode | Should -Be 12
        (Get-NormalizedBoringAdminOutput -Output $result.Output) | Should -Be (Get-SmokeSnapshot -Name "apply-security.txt")
    }

    It "check json returns a structured JSON error when fixture data is incomplete" {
        $fixtureDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $fixtureDirectory -Force | Out-Null

        try {
            $result = Invoke-BoringAdminCapture -Arguments @("check", "--json") -Environment @{
                BORING_ADMIN_VERIFY_FIXTURE_DIR = $fixtureDirectory
            }
        }
        finally {
            Remove-Item -LiteralPath $fixtureDirectory -Force -Recurse
        }

        $result.ExitCode | Should -Be 6

        $errorRecord = $result.Output | ConvertFrom-Json -ErrorAction Stop
        $errorRecord.scope | Should -Be "check-error"
        ([DateTimeOffset]$errorRecord.generatedAt).ToString("yyyy-MM-ddTHH:mm:sszzz", [System.Globalization.CultureInfo]::InvariantCulture) | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$'
        $errorRecord.error_id | Should -Be "check.fixture_missing"
        $errorRecord.exit_code | Should -Be 6
    }
}
