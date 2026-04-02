# TESTS

Public Test Surface  
boring-admin-windows

---

## Purpose

This directory contains the **public-facing test tree**
for `boring-admin-windows`.

It exists to separate:

- internal normalization validation in `.ai/validation/`
- product-facing QA and test layers in `tests/`

The long-term goal is to keep repository QA:

- explicit
- bounded
- readable
- compatible with the `v002` operating model

---

## Current state

This tree begins as intentional scaffolding.

Initial public QA focus:

- keep PowerShell lint explicit and CI-friendly
- establish stable test locations
- keep integrity checks explicit
- add Pester-based unit and contract coverage gradually
- avoid hidden automation or premature CI claims

---

## Structure

```text
tests/
├─ README.md
├─ Invoke-Tests.ps1
├─ Pester-Bootstrap.ps1
├─ ScriptAnalyzer-Bootstrap.ps1
├─ lint/
├─ integrity/
├─ unit/
├─ contract/
└─ smoke/
```

---

## Layer summary

- `lint/`  
  PSScriptAnalyzer-based static analysis for public PowerShell surfaces.

- `integrity/`  
  Repository-level static checks and consistency guards.

- `unit/`  
  Pester-based helper and library tests.

- `contract/`  
  Pester-based checks for script class rules and contract behavior.

- `smoke/`  
  Bounded runtime checks for supported read-only entry surfaces.

---

## Current entrypoint

Primary local test entrypoint:

```text
.\tests\Invoke-Tests.ps1
```

Examples:

```text
.\tests\Invoke-Tests.ps1
.\tests\Invoke-Tests.ps1 -Suite integrity
.\\tests\\Invoke-Tests.ps1 -Suite lint
.\tests\Invoke-Tests.ps1 -Suite unit
```

Pester-backed suites use:

```text
.\tests\Pester-Bootstrap.ps1
```

This bootstrap script:

- locates the highest available Pester module
- enforces the minimum supported version
- imports Pester before suite execution

Lint uses:

```text
.\tests\ScriptAnalyzer-Bootstrap.ps1
```

This bootstrap script:

- locates the highest available PSScriptAnalyzer module
- enforces the minimum supported version
- imports PSScriptAnalyzer before lint execution

---

## Relationship to .ai validation

`.ai/validation/` may remain available as an internal working aid.

`tests/` is the public-facing QA tree
and now contains the public integrity baseline directly in `tests/integrity/`.

Both may coexist.

They serve different purposes.

---

## See also

- [../docs/TEST-STRATEGY.md](../docs/TEST-STRATEGY.md)
- [../docs/SCRIPT-CONTRACT.md](../docs/SCRIPT-CONTRACT.md)
