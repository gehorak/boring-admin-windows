Describe "boring-admin entrypoint smoke checks" {
    BeforeAll {
        . (Join-Path $PSScriptRoot "Smoke-Helpers.ps1")
    }

    It "help exits successfully and shows the primary title" {
        $result = Invoke-BoringAdminCapture -Arguments @("help")
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match "boring-admin-windows :: boring-admin\.ps1"
    }

    It "info exits successfully and lists documentation anchors" {
        $result = Invoke-BoringAdminCapture -Arguments @("info")
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match "Documentation anchors:"
    }

    It "audit help exits successfully and mentions summary mode" {
        $result = Invoke-BoringAdminCapture -Arguments @("audit", "help")
        $result.ExitCode | Should -Be 0
        $result.Output | Should -Match "audit summary"
    }

    It "check-env exits successfully" {
        $result = Invoke-BoringAdminCapture -Arguments @("check-env")
        $result.ExitCode | Should -Be 0
    }
}
