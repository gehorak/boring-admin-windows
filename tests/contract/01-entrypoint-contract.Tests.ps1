Describe "entrypoint dispatch contracts" {
    BeforeAll {
        $script:RepositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $script:BoringAdminContent = Get-Content (Join-Path $script:RepositoryRoot "boring-admin.ps1") -Raw
        $script:MakefileContent = Get-Content (Join-Path $script:RepositoryRoot "Makefile") -Raw
    }

    It "comment-based help uses the public local-profile naming" {
        $script:BoringAdminContent | Should -Match 'individual\.local\.json'
        $script:BoringAdminContent | Should -Not -Match 'internal\.local\.json'
        $script:BoringAdminContent | Should -Not -Match 'internal\.example\.json'
    }

    It "boring-admin keeps read-only legacy review mappings separate from write-capable apply targets" {
        $script:BoringAdminContent | Should -Match 'scripts/apply/security/21-security-baseline\.manual\.ps1'
        $script:BoringAdminContent | Should -Match 'scripts/apply/identity/40-identity-local-orchestrator\.manual\.ps1'
        $script:BoringAdminContent | Should -Match 'scripts/apply/host/50-host-identity-orchestrator\.manual\.ps1'
        $script:BoringAdminContent | Should -Match 'scripts/migrate/10-bootstrap-orchestrator\.ps1'
        $script:BoringAdminContent | Should -Match 'scripts/apply/identity/41-identity-local-admin-model\.manual\.ps1'
        $script:BoringAdminContent | Should -Match 'scripts/apply/host/51-host-identity-core\.manual\.ps1'
        $script:BoringAdminContent | Should -Match 'scripts/overlay/software/32-software-baseline\.manual\.ps1'
        $script:BoringAdminContent | Should -Match 'scripts/overlay/ux/25-system-explorer-ux\.manual\.ps1'
        $script:BoringAdminContent | Should -Match 'scripts/overlay/15-consumer-noise\.manual\.ps1'
        $script:BoringAdminContent | Should -Match 'No write-capable security apply flow is implemented in v002'
    }

    It "the root Makefile stays read-only and small" {
        $script:MakefileContent | Should -Match '(?m)^help:'
        $script:MakefileContent | Should -Match '(?m)^info:'
        $script:MakefileContent | Should -Match '(?m)^check-env:'
        $script:MakefileContent | Should -Not -Match '(?m)^apply-[a-z0-9-]+:'
        $script:MakefileContent | Should -Not -Match '(?m)^plan-[a-z0-9-]+:'
        $script:MakefileContent | Should -Not -Match 'Makefile\.operational'
        $script:MakefileContent | Should -Not -Match 'Makefile\.audit'
    }
}
