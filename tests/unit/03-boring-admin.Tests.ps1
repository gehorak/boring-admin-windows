Describe "boring-admin helper surface" {
    BeforeAll {
        $script:RepositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $script:BoringAdminPath = Join-Path $script:RepositoryRoot "boring-admin.ps1"
        $script:OriginalProgramData = $env:ProgramData
        $script:OriginalFixtureDirectory = $env:BORING_ADMIN_VERIFY_FIXTURE_DIR

        . $script:BoringAdminPath

        function Get-TestLocalProfilePath {
            $tempPath = Join-Path ([System.IO.Path]::GetTempPath()) ("boring-admin-profile-{0}.json" -f ([guid]::NewGuid().ToString("N")))
            $content = Get-Content -Raw -LiteralPath (Join-Path $script:RepositoryRoot "config/profiles/individual.example.json")
            $content = $content -replace '"profileType": "example"', '"profileType": "local"'
            [System.IO.File]::WriteAllText($tempPath, $content, [System.Text.Encoding]::UTF8)
            return $tempPath
        }
    }

    AfterAll {
        $env:ProgramData = $script:OriginalProgramData
        $env:BORING_ADMIN_VERIFY_FIXTURE_DIR = $script:OriginalFixtureDirectory
    }

    It "Get-PublicPlanOutcome returns exit 0 when host fixture has no drift" {
        $fixtureDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
        $profilePath = Get-TestLocalProfilePath
        $originalFixtureDirectory = $env:BORING_ADMIN_VERIFY_FIXTURE_DIR

        try {
            New-Item -ItemType Directory -Path $fixtureDirectory -Force | Out-Null
            Copy-Item -LiteralPath (Join-Path $script:RepositoryRoot "tests/smoke/fixtures/audit-export/host.json") -Destination (Join-Path $fixtureDirectory "host.json")
            $env:BORING_ADMIN_VERIFY_FIXTURE_DIR = $fixtureDirectory

            $config = Import-BoringAdminConfig -ProfilePath $profilePath
            $outcome = Get-PublicPlanOutcome -Spec (Get-PlanSpec -Target "host") -Config $config

            $outcome.PlanKind | Should -Be "state-diff"
            $outcome.ExitCode | Should -Be 0
            $outcome.ChangeCount | Should -Be 0
            $outcome.StateDetermination | Should -Be "complete"
        }
        finally {
            $env:BORING_ADMIN_VERIFY_FIXTURE_DIR = $originalFixtureDirectory
            Remove-Item -LiteralPath $fixtureDirectory -Force -Recurse
            Remove-Item -LiteralPath $profilePath -Force
        }
    }

    It "Get-PublicPlanOutcome returns exit 10 when host fixture drifts" {
        $fixtureDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
        $profilePath = Get-TestLocalProfilePath
        $originalFixtureDirectory = $env:BORING_ADMIN_VERIFY_FIXTURE_DIR

        try {
            New-Item -ItemType Directory -Path $fixtureDirectory -Force | Out-Null
            $fixture = Get-Content -Raw -LiteralPath (Join-Path $script:RepositoryRoot "tests/smoke/fixtures/audit-export/host.json") | ConvertFrom-Json -ErrorAction Stop
            $fixture.host.current.computerName = "DIFFERENT-HOST"
            $fixture.host.drift.computerName = $true
            $fixture | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $fixtureDirectory "host.json") -Encoding UTF8
            $env:BORING_ADMIN_VERIFY_FIXTURE_DIR = $fixtureDirectory

            $config = Import-BoringAdminConfig -ProfilePath $profilePath
            $outcome = Get-PublicPlanOutcome -Spec (Get-PlanSpec -Target "host") -Config $config

            $outcome.ExitCode | Should -Be 10
            $outcome.ChangeCount | Should -Be 1
            $outcome.Changes[0].id | Should -Be "host.computer_name"
        }
        finally {
            $env:BORING_ADMIN_VERIFY_FIXTURE_DIR = $originalFixtureDirectory
            Remove-Item -LiteralPath $fixtureDirectory -Force -Recurse
            Remove-Item -LiteralPath $profilePath -Force
        }
    }

    It "Get-PublicPlanOutcome keeps capability preview targets out of exit 10" {
        $outcome = Get-PublicPlanOutcome -Spec (Get-PlanSpec -Target "bootstrap")

        $outcome.PlanKind | Should -Be "capability-preview"
        $outcome.ExitCode | Should -Be 0
        $outcome.ChangeCount | Should -Be 0
        $outcome.StateDetermination | Should -Be "unavailable"
    }

    It "Get-PublicPlanOutcome blocks non-admin consumer-noise planning before elevated AppX discovery" {
        $originalFixtureDirectory = $env:BORING_ADMIN_VERIFY_FIXTURE_DIR
        $env:BORING_ADMIN_VERIFY_FIXTURE_DIR = $null

        try {
            Mock Test-IsAdministrator { return $false }
            Mock Get-AppxPackage { throw "should not be called" }
            Mock Get-AppxProvisionedPackage { throw "should not be called" }

            $outcome = Get-PublicPlanOutcome -Spec (Get-PlanSpec -Target "consumer-noise")

            $outcome.PlanKind | Should -Be "state-diff"
            $outcome.ExitCode | Should -Be 4
            $outcome.StateDetermination | Should -Be "partial"
            @($outcome.BlockingConditions).Count | Should -Be 1
            Assert-MockCalled Get-AppxPackage -Times 0
            Assert-MockCalled Get-AppxProvisionedPackage -Times 0
        }
        finally {
            $env:BORING_ADMIN_VERIFY_FIXTURE_DIR = $originalFixtureDirectory
        }
    }

    It "Get-PublicApplyPrecheck blocks write-capable apply when pending reboot markers exist" {
        Mock Get-BoringAdminPendingRebootSignals {
            return @(
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
            )
        }

        $precheck = Get-PublicApplyPrecheck -Spec (Get-PlanSpec -Target "ux")

        $precheck.Allowed | Should -BeFalse
        $precheck.ErrorId | Should -Be "apply.reboot_pending"
        $precheck.ExitCode | Should -Be $script:PublicExitCodes.Environment
        @($precheck.AuditData.pending_reboot_signals).Count | Should -Be 1
    }

    It "Test-BoringAdminShouldProcess falls back to WhatIfPreference when no cmdlet is available" {
        $previousEntryPointCmdlet = $script:EntryPointCmdlet
        $previousWhatIfPreference = $WhatIfPreference

        try {
            $script:EntryPointCmdlet = $null

            $WhatIfPreference = $false
            (Test-BoringAdminShouldProcess -Target "software" -Action "Apply planned changes") | Should -BeTrue

            $WhatIfPreference = $true
            (Test-BoringAdminShouldProcess -Target "software" -Action "Apply planned changes") | Should -BeFalse
        }
        finally {
            $script:EntryPointCmdlet = $previousEntryPointCmdlet
            $WhatIfPreference = $previousWhatIfPreference
        }
    }

    It "Write-WorkstationRecord preserves failure metadata and optional failures" {
        $tempProgramData = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempProgramData -Force | Out-Null
        $env:ProgramData = $tempProgramData
        $script:RunId = "run-test"
        $script:CurrentTarget = "software"
        $script:CliOptions = [pscustomobject]@{
            Json     = $false
            Quiet    = $false
            Verbose  = $false
            DryRun   = $false
            Help     = $false
            Version  = $false
            Summary  = $false
            Save     = $false
            Profile  = $null
            ChangeId = "CHG-1"
        }

        try {
            $applyResult = Get-ApplyFailureResult -Target "software" -FailureStage "child-execution" -ErrorId "apply.child_failed" -Message "Child failed." -NextAction "Inspect child output." -ChildExitCode 5
            $applyResult.optional_failed_items = @(
                [pscustomobject]@{
                    id             = "optional.pkg"
                    reason         = "install-exit-code-1"
                    classification = "baseline"
                }
            )

            $recordPath = Write-WorkstationRecord -Target "software" -ChangeId "CHG-1" -ExitCode 6 -ApplyResult $applyResult
            $record = Get-Content -Raw -LiteralPath $recordPath | ConvertFrom-Json -ErrorAction Stop

            $record.result | Should -Be "failed"
            $record.exit_code | Should -Be 6
            $record.child_exit_code | Should -Be 5
            $record.failure_stage | Should -Be "child-execution"
            $record.error_id | Should -Be "apply.child_failed"
            $record.next_action | Should -Be "Inspect child output."
            $record.optional_failed_items.Count | Should -Be 1
        }
        finally {
            Remove-Item -LiteralPath $tempProgramData -Force -Recurse
        }
    }

    It "Complete-BoringAdminPublicApply writes failure evidence for child execution errors" {
        $tempProgramData = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempProgramData -Force | Out-Null
        $env:ProgramData = $tempProgramData
        $script:RunId = "run-test"
        $script:CurrentTarget = "software"
        $script:CliOptions = [pscustomobject]@{
            Json     = $false
            Quiet    = $false
            Verbose  = $false
            DryRun   = $false
            Help     = $false
            Version  = $false
            Summary  = $false
            Save     = $false
            Profile  = $null
            ChangeId = "CHG-2"
        }

        try {
            $auditPath = Join-Path $tempProgramData "apply-audit.jsonl"
            $applyResultPath = Join-Path $tempProgramData "missing-result.json"
            $completion = Complete-BoringAdminPublicApply -Target "software" -ChangeId "CHG-2" -ChildExitCode 5 -ApplyResultPath $applyResultPath -AuditPath $auditPath -RunId "run-test"

            $completion.PublicExitCode | Should -Be 6
            $completion.ApplyResult.result | Should -Be "failed"
            $completion.ApplyResult.failure_stage | Should -Be "child-execution"
            $completion.ApplyResult.error_id | Should -Be "apply.child_failed"
            $completion.ApplyResult.next_action | Should -Not -BeNullOrEmpty
            (Test-Path -LiteralPath $completion.WorkstationPath) | Should -BeTrue

            $record = Get-Content -Raw -LiteralPath $completion.WorkstationPath | ConvertFrom-Json -ErrorAction Stop
            $record.result | Should -Be "failed"
            $record.failure_stage | Should -Be "child-execution"
            $record.child_exit_code | Should -Be 5

            $auditEvents = @(Get-Content -LiteralPath $auditPath | ForEach-Object { $_ | ConvertFrom-Json -ErrorAction Stop })
            $auditEvents.Count | Should -Be 1
            $auditEvents[0].message | Should -Be "Apply failed."
            $auditEvents[0].data.error_id | Should -Be "apply.child_failed"
        }
        finally {
            Remove-Item -LiteralPath $tempProgramData -Force -Recurse
        }
    }

    It "Complete-BoringAdminPublicApply writes failure evidence when the apply result file is missing" {
        $tempProgramData = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $tempProgramData -Force | Out-Null
        $env:ProgramData = $tempProgramData
        $script:RunId = "run-test"
        $script:CurrentTarget = "software"
        $script:CliOptions = [pscustomobject]@{
            Json     = $false
            Quiet    = $false
            Verbose  = $false
            DryRun   = $false
            Help     = $false
            Version  = $false
            Summary  = $false
            Save     = $false
            Profile  = $null
            ChangeId = "CHG-3"
        }

        try {
            $auditPath = Join-Path $tempProgramData "apply-audit.jsonl"
            $applyResultPath = Join-Path $tempProgramData "missing-result.json"
            $completion = Complete-BoringAdminPublicApply -Target "software" -ChangeId "CHG-3" -ChildExitCode 0 -ApplyResultPath $applyResultPath -AuditPath $auditPath -RunId "run-test"

            $completion.PublicExitCode | Should -Be 6
            $completion.ApplyResult.result | Should -Be "failed"
            $completion.ApplyResult.failure_stage | Should -Be "result-read"
            (Test-Path -LiteralPath $completion.WorkstationPath) | Should -BeTrue

            $auditEvents = @(Get-Content -LiteralPath $auditPath | ForEach-Object { $_ | ConvertFrom-Json -ErrorAction Stop })
            $auditEvents.Count | Should -Be 1
            $auditEvents[0].data.failure_stage | Should -Be "result-read"
        }
        finally {
            Remove-Item -LiteralPath $tempProgramData -Force -Recurse
        }
    }

    It "Invoke-PublicApply routes ShouldProcess through the entrypoint helper" {
        $content = Get-Content -Raw -LiteralPath $script:BoringAdminPath

        $content | Should -Match 'function Test-BoringAdminShouldProcess'
        $content | Should -Match 'Test-BoringAdminShouldProcess -Target \$Target -Action "Apply planned changes" -InvocationCmdlet \$PSCmdlet'
        $content | Should -Not -Match '\$PSCmdlet\.ShouldProcess\(\$Target,\s*"Apply planned changes"\)'
    }
}
