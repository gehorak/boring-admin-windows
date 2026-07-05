Describe "runtime timestamp and error contracts" {
    BeforeAll {
        $script:RepositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $script:BoringAdmin = Join-Path $script:RepositoryRoot "boring-admin.ps1"
        $script:PowerShellExe = (Get-Process -Id $PID).Path
        $script:Rfc3339Pattern = '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}$'
    }

    It "apply security exposes the stable public unsupported-operation metadata" {
        $output = & $script:PowerShellExe -NoProfile -File $script:BoringAdmin apply security 2>&1 | Out-String

        $LASTEXITCODE | Should -Be 12
        $output | Should -Match '\[FAIL\] No write-capable security apply flow is implemented in v002\.'
        $output | Should -Match '\[INFO\] error_id: apply\.security\.unsupported'
        $output | Should -Match '\[INFO\] exit_code: 12'
        $output | Should -Match '\[INFO\] next_action: Use the documented read-only check target instead\.'
        $output | Should -Match '\[INFO\] run_id: '
    }

    It "version is a stable discovery surface with a successful exit code" {
        $output = & $script:PowerShellExe -NoProfile -File $script:BoringAdmin version 2>&1 | Out-String

        $LASTEXITCODE | Should -Be 0
        $output.Trim() | Should -Be "boring-admin-windows v002"
    }

    It "version json exposes the public machine-readable metadata surface" {
        $output = & $script:PowerShellExe -NoProfile -File $script:BoringAdmin version --json 2>&1 | Out-String

        $LASTEXITCODE | Should -Be 0
        $record = $output | ConvertFrom-Json -ErrorAction Stop
        $record.command | Should -Be "version"
        $record.run_id | Should -Match '^[0-9a-f-]{36}$'
        $record.event_id | Should -Match '^[0-9a-f-]{36}$'
        $record.severity | Should -Be "info"
        $record.exit_code | Should -Be 0
        $record.data.architecture_surface | Should -Be "v002"
    }

    It "unknown top-level commands keep the stable fail-fast metadata surface" {
        $output = & $script:PowerShellExe -NoProfile -File $script:BoringAdmin nope 2>&1 | Out-String

        $LASTEXITCODE | Should -Be 2
        $output | Should -Match '\[FAIL\] Unknown command: nope'
        $output | Should -Match '\[INFO\] error_id: top_level\.unknown_command'
        $output | Should -Match '\[INFO\] exit_code: 2'
        $output | Should -Match '\[INFO\] next_action: Run \.\\boring-admin\.ps1 help to see the supported public commands\.'
    }

    It "check json returns a structured JSON error when fixture data is missing" {
        $fixtureDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $fixtureDirectory -Force | Out-Null
        $originalFixtureDirectory = [System.Environment]::GetEnvironmentVariable("BORING_ADMIN_VERIFY_FIXTURE_DIR", "Process")
        [System.Environment]::SetEnvironmentVariable("BORING_ADMIN_VERIFY_FIXTURE_DIR", $fixtureDirectory, "Process")

        try {
            $output = & $script:PowerShellExe -NoProfile -File $script:BoringAdmin check --json 2>&1 | Out-String
        }
        finally {
            [System.Environment]::SetEnvironmentVariable("BORING_ADMIN_VERIFY_FIXTURE_DIR", $originalFixtureDirectory, "Process")
            Remove-Item -LiteralPath $fixtureDirectory -Force -Recurse
        }

        $LASTEXITCODE | Should -Be 6

        $errorRecord = $output | ConvertFrom-Json -ErrorAction Stop
        $errorRecord.scope | Should -Be "check-error"
        ([DateTimeOffset]$errorRecord.generatedAt).ToString("yyyy-MM-ddTHH:mm:sszzz", [System.Globalization.CultureInfo]::InvariantCulture) | Should -Match $script:Rfc3339Pattern
        $errorRecord.run_id | Should -Match '^[0-9a-f-]{36}$'
        $errorRecord.event_id | Should -Match '^[0-9a-f-]{36}$'
        $errorRecord.severity | Should -Be "error"
        $errorRecord.error_id | Should -Be "check.fixture_missing"
        $errorRecord.exit_code | Should -Be 6
        $errorRecord.message | Should -Match '^Check fixture not found: '
    }

    It "boring-admin keeps the current stable public boundary failure identifiers" {
        $content = Get-Content -Raw -LiteralPath $script:BoringAdmin

        $content | Should -Match 'check\.fixture_missing'
        $content | Should -Match 'check\.fixture_invalid_json'
        $content | Should -Match 'check\.scope_failed'
        $content | Should -Match 'check\.invalid_json'
        $content | Should -Match 'apply\.security\.unsupported'
        $content | Should -Match 'apply\.reboot_pending'
        $content | Should -Match 'top_level\.unknown_command'
    }

    It "Get-Help exposes the documented check, plan, and apply examples" {
        $output = & $script:PowerShellExe -NoProfile -Command "Get-Help -Full '$script:BoringAdmin' | Out-String" 2>&1 | Out-String

        $output | Should -Match '\.\\boring-admin\.ps1 check'
        $output | Should -Match '\.\\boring-admin\.ps1 plan host --profile'
        $output | Should -Match '\.\\boring-admin\.ps1 apply software --profile'
        $output | Should -Match '--change-id'
        $output | Should -Match '--json'
    }
}
