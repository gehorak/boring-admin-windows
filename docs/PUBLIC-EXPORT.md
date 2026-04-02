# PUBLIC-EXPORT.md

Public Export Guide  
boring-admin-windows

---

## Purpose

This document defines how the **private governing repository**
is transformed into a **public-clean release repository**.

Its purpose is to:

- distinguish public product material from private working material
- prevent accidental publication of internal execution artifacts
- make release preparation explicit and repeatable
- protect repository clarity during public publication

This document is **operational guidance**.
It does not override repository authority.

---

## Public export principle

The private repository is the **governing source**.

The public repository is a **clean derivative**
intended for external readers and operators.

Public export exists to preserve:

- architectural clarity
- operational trust
- release hygiene

It does not exist to expose every internal working artifact.

---

## Public include set

The following areas belong to the intended public release surface:

- `README.md`
- `DISCLAIMER.md`
- `CHANGELOG.md`
- `LICENSE`
- `LICENSE-SUMMARY.md`
- `TRADEMARKS.md`
- `COMMERCIAL.md`
- `ROADMAP.md`
- `Makefile`
- `Makefile.audit`
- `Makefile.operational`
- `boring-admin.ps1`
- `PSScriptAnalyzerSettings.psd1`
- `docs/`
- `core/`
- `scripts/`
- `tests/`
- `.github/workflows/qa.yml`

These files represent the active product surface
and must remain internally consistent before publication.

---

## Public exclude set

The following areas do **not** belong to the public release surface:

- `.ai/`
- `.vscode/`
- task-local prompts
- internal execution notes
- temporary working artifacts

These materials may support development and normalization,
but they are not part of the public operating model.

---

## Export checklist

Before public publication:

1. confirm [AUTHORITY.md](./AUTHORITY.md) and [REPOSITORY-STATUS.md](./REPOSITORY-STATUS.md) are current
2. confirm no internal-only artifacts remain in the active product surface
3. confirm public integrity validation passes before export
4. confirm release-facing documentation matches implementation
5. confirm the public tree excludes `.ai/`, `.vscode/`, and other private working material

Helper:

- [../export/New-PublicSkeleton.ps1](../export/New-PublicSkeleton.ps1)
  creates a clean export directory and copies only the approved public include
  set

---

## Non-goals

Public export does **not**:

- publish internal AI workflow material
- publish local editor configuration
- expose draft prompts or task scaffolding
- redefine the product surface

---

## Final rule

Public release must remain **boring, explicit, and clean**.

If an artifact cannot be justified as public product material,
it should not be exported.
