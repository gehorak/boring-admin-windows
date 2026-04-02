Describe "script contract bootstrap checks" {
    BeforeAll {
        $script:RepositoryRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        $script:ScriptsRoot = Join-Path $script:RepositoryRoot "scripts"
        $script:ScriptFiles = @(
            Get-ChildItem $script:ScriptsRoot -Recurse -File -Filter *.ps1 |
                Sort-Object FullName
        )
        $script:VerifyFiles = @($script:ScriptFiles | Where-Object { $_.Name -like "*.verify.ps1" })
        $script:ManualFiles = @($script:ScriptFiles | Where-Object { $_.Name -like "*.manual.ps1" })
        $script:SafeFiles = @($script:ScriptFiles | Where-Object { $_.Name -like "*.safe.ps1" })
    }

    It "all script files use canonical filename patterns for their lifecycle class" {
        foreach ($file in $script:ScriptFiles) {
            $relativePath = $file.FullName.Substring($script:RepositoryRoot.Length + 1)

            if ($relativePath -match '^scripts\\migrate\\') {
                $file.Name | Should -Match '^\d{2}-.*(\.(safe))?\.ps1$'
                continue
            }

            $file.Name | Should -Match '^\d{2}-.*\.(safe|verify|manual)\.ps1$'
        }
    }

    It "all verify scripts expose explicit OutputFormat support" {
        foreach ($file in $script:VerifyFiles) {
            $content = Get-Content $file.FullName -Raw
            $content | Should -Match '\[string\]\s+\$OutputFormat\s*=\s*"Text"'
            $content | Should -Match '\$OutputFormat\s+-eq\s+"Json"'
        }
    }

    It "safe scripts support WhatIf or ShouldProcess semantics" {
        foreach ($file in $script:SafeFiles) {
            $content = Get-Content $file.FullName -Raw
            ($content -match '-WhatIf' -or $content -match 'ShouldProcess') | Should -Be $true
        }
    }

    It "manual scripts are not located under verify" {
        foreach ($file in $script:ManualFiles) {
            $relativePath = $file.FullName.Substring($script:RepositoryRoot.Length + 1)
            $relativePath | Should -Not -Match '^scripts\\verify\\'
        }
    }

    It "lifecycle scripts do not use Write-Error or Write-Warning directly" {
        foreach ($file in $script:ScriptFiles) {
            $content = Get-Content $file.FullName -Raw
            $content | Should -Not -Match '\bWrite-Error\b'
            $content | Should -Not -Match '\bWrite-Warning\b'
        }
    }
}
