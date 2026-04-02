# TEST-STRATEGY.md

Test Strategy  
boring-admin-windows

---

## Purpose

This document defines the intended **test and QA model**
for `boring-admin-windows`.

Its purpose is to:

- distinguish repository validation from product testing
- define a durable test pyramid for PowerShell-based maintenance code
- prevent accidental drift between script classes and test execution
- guide future CI and local QA work without changing repository authority

This document is **supporting QA guidance**.
It does not override repository authority or script behavior contracts.

---

## Core principle

Testing in this repository exists to prove that the operating model remains:

- predictable
- reviewable
- read-only where expected
- explicit where state changes occur

The goal is not maximal automation.
The goal is **bounded confidence without architectural drift**.

---

## QA layers

`boring-admin-windows` uses five complementary QA layers:

1. normalization validation
2. lint
3. integrity tests
4. unit and contract tests
5. smoke verification

These layers are not interchangeable.

---

## 1. Normalization validation

Current internal validation lives in:

- `.ai/validation/`

This layer exists to detect repository consistency problems during active work.

It currently covers:

- reference integrity
- PowerShell parse validity
- helper import pattern checks
- known broken legacy name detection
- verify/apply separation text checks

This layer is:

- internal
- read-only
- non-authoritative
- fast enough to run before each commit

It is not a substitute for product tests.

---

## 2. Lint

Current public location:

- `tests/lint/`

Purpose:

- PowerShell static analysis
- early detection of quality and safety regressions
- CI-fast feedback before runtime suites

Primary tool:

- `PSScriptAnalyzer`

Current public support files:

- `PSScriptAnalyzerSettings.psd1`
- `tests/ScriptAnalyzer-Bootstrap.ps1`

Lint should remain:

- fast
- deterministic
- repository-scoped
- suitable for local execution and GitHub Actions

Current `v002` baseline:

- public lint entrypoint exists in `tests/lint/Invoke-Lint.ps1`
- `tests/Invoke-Tests.ps1 -Suite lint` is supported
- GitHub Actions runs lint before runtime suites

---

## 3. Integrity tests

Current public location:

- `tests/integrity/`

Purpose:

- repository-level static checks
- structural consistency checks
- behavior-independent safety checks

Typical checks:

- parse validation for PowerShell files
- reference integrity
- naming consistency
- script class placement checks
- required file presence
- export surface checks for public release

These tests should remain:

- fast
- deterministic
- OS-safe
- suitable for local execution and future CI

---

## 4. Unit tests

Current public location:

- `tests/unit/`

Purpose:

- verify helper functions and bounded shared runtime behavior

Primary targets:

- `core/lib/common.ps1`
- `core/lib/ux.ps1`

Examples:

- output helper behavior
- warning and fatal helper behavior
- path resolution helpers
- confirmation helper behavior
- helper functions that wrap bounded Windows queries

Preferred framework:

- **Pester**

Unit tests must avoid becoming hidden integration tests.

Current `v002` baseline:

- unit coverage exists for `core/lib/common.ps1`
- unit coverage exists for `core/lib/ux.ps1`

---

## 5. Contract tests

Current public location:

- `tests/contract/`

Purpose:

- verify that script classes still obey their documented rules

Primary contract source:

- [SCRIPT-CONTRACT.md](./SCRIPT-CONTRACT.md)

Examples:

- VERIFY scripts remain read-only by text and behavior contract
- SAFE scripts expose `-WhatIf` when applicable
- MANUAL scripts are not auto-executed in test runs
- lifecycle naming patterns remain canonical
- machine-readable output modes remain explicit and read-only

Preferred framework:

- **Pester**

Contract tests exist to guard repository semantics,
not to restate architecture in a second hidden authority layer.

Current `v002` baseline:

- initial contract checks exist for script naming
- verify output-format support is checked
- safe-script `WhatIf` / `ShouldProcess` semantics are checked
- direct `Write-Error` / `Write-Warning` bans are checked

---

## 6. Smoke tests

Current public location:

- `tests/smoke/`

Purpose:

- limited runtime verification of the most important entry surfaces

Examples:

- `boring-admin.ps1 help`
- `boring-admin.ps1 info`
- `boring-admin.ps1 audit help`
- `boring-admin.ps1 check-env`
- selected VERIFY scripts in an explicitly supported environment

Smoke tests must remain:

- bounded
- explicit
- safe
- intentionally narrower than full integration testing

MANUAL scripts must not be executed automatically as smoke tests.

Current `v002` baseline:

- smoke coverage exists for the main `boring-admin.ps1` discovery surface
- current smoke scope includes `help`, `info`, `audit help`, and `check-env`

---

## Pester role

For the PowerShell product surface,
the preferred framework for unit and contract testing is:

- **Pester**

Recommended use:

- `tests/unit/` -> helper functions
- `tests/contract/` -> script behavior rules
- `tests/Pester-Bootstrap.ps1` -> local bootstrap and version gate

Pester should not be forced onto every QA layer.

Specifically:

- integrity checks may remain plain `.ps1` scripts
- smoke checks may mix Pester and plain PowerShell when appropriate

---

## Current test tree

```text
tests/
├─ README.md
├─ Invoke-Tests.ps1
├─ Pester-Bootstrap.ps1
├─ ScriptAnalyzer-Bootstrap.ps1
├─ lint/
│  └─ README.md
├─ integrity/
│  └─ README.md
├─ unit/
│  └─ README.md
├─ contract/
│  └─ README.md
└─ smoke/
   └─ README.md
```

This tree begins as scaffolding and should grow deliberately.

---

## Execution model

### Local fast path

For normal repository work:

1. run `tests/integrity/validate-repo.ps1`
2. run `tests/Invoke-Tests.ps1 -Suite lint`
3. run relevant integrity or unit checks for the edited scope
3. commit only after the intended QA layer passes

### Future CI path

The active CI order is:

1. lint
2. integrity checks
3. selected smoke tests
4. Pester unit tests
5. Pester contract tests

MANUAL scripts remain excluded from automatic execution.

Current repository CI implementation:

- `.github/workflows/qa.yml`
- GitHub Actions
- `windows-latest`
- read-only QA only

The current workflow runs:

1. `tests/Invoke-Tests.ps1 -Suite lint`
2. `tests/Invoke-Tests.ps1 -Suite integrity`
3. `tests/Invoke-Tests.ps1 -Suite smoke`
4. `tests/Invoke-Tests.ps1 -Suite unit`
5. `tests/Invoke-Tests.ps1 -Suite contract`

---

## Non-goals

This test strategy does **not** aim to introduce:

- hidden policy enforcement
- unattended lifecycle execution
- automatic execution of MANUAL scripts
- domain, Intune, or MDM integration tests
- full state-driven verification before `v003`

---

## v002 QA status

Current `v002` QA baseline includes:

- public PowerShell lint in `tests/lint/`
- public integrity validation in `tests/integrity/`
- public `tests/` tree and entrypoint
- lint and integrity execution through the public `tests/Invoke-Tests.ps1` entrypoint
- passing Pester smoke suite
- passing Pester unit coverage for `common.ps1` and `ux.ps1`
- passing initial Pester contract suite

This is sufficient to strengthen `v002`
without prematurely introducing `v003` state logic.

---

## See also

- [AUTHORITY.md](./AUTHORITY.md)
- [REPOSITORY-STATUS.md](./REPOSITORY-STATUS.md)
- [SCRIPT-CONTRACT.md](./SCRIPT-CONTRACT.md)
- [PUBLIC-EXPORT.md](./PUBLIC-EXPORT.md)
