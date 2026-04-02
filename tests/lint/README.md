# LINT

PowerShell static analysis layer
for `boring-admin-windows`.

---

## Purpose

This suite runs repository lint checks with:

- `PSScriptAnalyzer`

It exists to catch:

- PowerShell quality issues
- risky patterns
- regressions that should fail CI before runtime tests

---

## Entrypoint

```text
.\tests\Invoke-Tests.ps1 -Suite lint
```

Direct entrypoint:

```text
.\tests\lint\Invoke-Lint.ps1
```

Bootstrap:

```text
.\tests\ScriptAnalyzer-Bootstrap.ps1
```

---

## Scope

The lint suite analyzes:

- `boring-admin.ps1`
- `core/`
- `scripts/`
- `tests/`

Settings are defined in:

- `PSScriptAnalyzerSettings.psd1`
