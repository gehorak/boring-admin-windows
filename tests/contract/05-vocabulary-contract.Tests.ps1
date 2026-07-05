Describe "top-level vocabulary contracts" {
    BeforeAll {
        $script:RepositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $script:BoringAdminContent = Get-Content (Join-Path $script:RepositoryRoot "boring-admin.ps1") -Raw
        $script:CommandsContent = Get-Content (Join-Path $script:RepositoryRoot "docs/COMMANDS.md") -Raw
        $script:ArchitectureContent = Get-Content (Join-Path $script:RepositoryRoot "docs/ARCHITECTURE.md") -Raw
    }

    It "boring-admin exposes the preferred public verbs and does not add undocumented top-level mutations" {
        $dispatchBlock = [regex]::Match(
            $script:BoringAdminContent,
            '(?ms)switch \(\$command\)\s*\{(?<body>.*)^\s*default\s*\{'
        ).Groups['body'].Value

        foreach ($command in @("help", "version", "check", "plan", "apply")) {
            $dispatchBlock | Should -Match ('(?m)^ {8}"' + [regex]::Escape($command) + '"\s*\{')
        }

        foreach ($forbiddenCommand in @("validate", "status", "export", "rollback")) {
            $dispatchBlock | Should -Not -Match ('(?m)^ {8}"' + [regex]::Escape($forbiddenCommand) + '"\s*\{')
        }
    }

    It "public docs keep the check-plan-apply boundary explicit" {
        $script:CommandsContent | Should -Match 'Read-only:'
        $script:CommandsContent | Should -Match 'Write-capable:'
        $script:CommandsContent | Should -Match '`apply security` is intentionally unsupported'
        $script:CommandsContent | Should -Match 'Additional compatibility entrypoints may still exist in dispatch'
        $script:ArchitectureContent | Should -Match '`check`'
        $script:ArchitectureContent | Should -Match '`plan`'
        $script:ArchitectureContent | Should -Match '`apply`'
        $script:ArchitectureContent | Should -Match 'The tool may write local runtime records'
    }
}
