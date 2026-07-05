Describe "ux.ps1 helper surface" {
    BeforeAll {
        $script:RepositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        . (Join-Path $script:RepositoryRoot "core/lib/ux.ps1")
    }

    It "Ux-Context writes the label prefix and trailing separator without newline" {
        Mock Write-Host {}

        Ux-Context -Label "CTX"

        Assert-MockCalled Write-Host -Times 2
        Assert-MockCalled Write-Host -ParameterFilter { $Object -eq "[CTX]" -and $NoNewline -eq $true } -Times 1
        Assert-MockCalled Write-Host -ParameterFilter { $Object -eq " " -and $NoNewline -eq $true } -Times 1
    }

    It "Ux-H1 writes a spacer line and formatted title" {
        Mock Write-Host {}

        Ux-H1 -Title "Primary"

        Assert-MockCalled Write-Host -ParameterFilter { $Object -eq "=== Primary ===" } -Times 1
    }

    It "Ux-Info writes the canonical info prefix" {
        Mock Write-Host {}

        Ux-Info -Message "hello"

        Assert-MockCalled Write-Host -ParameterFilter { $Object -eq "[INFO] hello" } -Times 1
    }

    It "Ux-Ok writes the canonical ok prefix" {
        Mock Write-Host {}

        Ux-Ok -Message "done"

        Assert-MockCalled Write-Host -ParameterFilter { $Object -eq "[OK]   done" } -Times 1
    }

    It "Ux-Divider writes the divider line and a blank separator" {
        Mock Write-Host {}

        Ux-Divider

        Assert-MockCalled Write-Host -ParameterFilter { $Object -eq "--------------------------------------------------" } -Times 1
    }
}
