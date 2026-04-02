# REPOSITORY-STATUS.md

Repository Status  
boring-admin-windows

---

## Purpose

This document defines the **current repository status**
for normalization work and release preparation.

Its purpose is to:

- distinguish active product material from internal working material
- describe what belongs to `v002`
- identify what is excluded from public release output
- provide a stable operational view during normalization

This document is **status and classification guidance**.
It does not redefine architecture.

---

## Current Repository Mode

This repository is currently the **private governing source**
for the `boring-admin-windows` project.

It is not yet treated as a public-clean release repository.

Public publication is expected to occur only after:
- normalization completes
- internal-only material is excluded
- active files are consistent and production-acceptable

---

## Active Product Surface

The following areas are part of the active product repository surface:

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

These files and directories are part of the repository content
that must become internally consistent before `v002` can be considered green.

---

## Internal Working Surface

The following areas are internal working material:

- `.ai/`
- internal prompts
- task-local execution guidance

These materials:
- support AI-assisted development
- are intentionally private-source
- are not part of the public release surface

They must remain subordinate to repository documentation.

---

## Internal Non-Product Artifacts

The following items are not part of the intended public product surface:

- `v002-impl.md`
- temporary task-local artifacts
- accidental repository artifacts such as `NUL`

These items require explicit cleanup, archival, or removal
before public green publication.

---

## v002 Scope Status

For normalization purposes, `v002` currently includes:

- repository contract and architecture documents
- script contract and supporting documentation
- reference PowerShell scripts in `scripts/`
- helper library files in `core/lib/`
- human-facing execution entrypoints in Makefiles and `boring-admin.ps1`
- public PowerShell lint settings in `PSScriptAnalyzerSettings.psd1`
- public-facing QA and test scaffolding in `tests/`
- public GitHub Actions QA workflow for lint, integrity, smoke, unit, and contract verification
- limited recovery visibility, not automated recovery orchestration

For normalization purposes, `v002` does NOT include:

- active state modeling
- `v003` state-driven behavior
- GPO-based system state expansion
- hidden workflow automation

---

## state/ Classification

`state/` is **not part of active `v002`**.

Current interpretation:
- it does not belong to the normative `v002` operating model
- it must not be treated as an active authority source
- it is absent from the normalized `v002` repository surface
- it may be introduced only by explicit `v003` work

During `v002` normalization,
`state/` must remain absent from the active product tree.

---

## boring-admin.ps1 Classification

`boring-admin.ps1` is intended to remain part of the active product surface
as the Windows-native alternative to the Makefile-based entrypoints.

It must therefore be:
- completed
- internally consistent
- aligned with repository naming and authority

It must not remain a partial or misleading active entrypoint.

---

## ROADMAP Status

`ROADMAP.md` is planning-only.

It may describe:
- intent
- direction
- planned phases
- possible future work

It must not be used as higher authority
than normative architecture or repository contract documents.

---

## Green Publication Readiness

`v002` may be considered ready for public green publication only when:

- active files are consistent
- broken references are removed
- script entrypoints are functional
- script/helper loading is valid
- baseline and overlay meanings are stable
- internal-only artifacts are excluded from release output

Until then,
this repository remains the private governing source,
not the final public-clean publication form.

---

## Final Rule

Status classification exists to prevent confusion.

If a file cannot be clearly classified as:
- active product
- internal working material
- or non-product artifact

then its place in the repository must be reconsidered.
