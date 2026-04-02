# AUTHORITY.md

Repository Authority Map  
boring-admin-windows

---

## Purpose

This document defines the **authority and precedence model**
for the `boring-admin-windows` repository.

Its purpose is to:

- make source-of-truth boundaries explicit
- resolve document precedence during normalization
- prevent authority drift between documentation, workflow, and implementation
- distinguish active authority from planning and internal working material

This document is **normative for repository interpretation**.

---

## Core Rule

If two files appear to conflict:

> **the higher-authority file wins**

Implementation never overrides documentation.
Planning never overrides normative architecture.
Internal AI workflow material never overrides repository documentation.

---

## Authority Levels

### Level 1 — Repository Contract

Highest active authority for repository identity and usage:

- `README.md`
- `DISCLAIMER.md`

These define:
- what the repository is
- what it is not
- who it is for
- responsibility boundaries

`README.md` is the human entry point.
It must not be silently contradicted by lower layers.

---

### Level 2 — Normative Architecture

Primary architectural authority:

- `docs/STRUCTURE.md`
- `docs/ARCHITECTURAL-POSITION.md`
- `docs/ARCHITECTURE-GUARD.md`
- `docs/ARCHITECTURE-v002.md`

These define:
- lifecycle and responsibility boundaries
- architectural identity
- non-negotiable invariants
- v002 operational boundary semantics

If implementation or planning diverges from these files,
these files win.

---

### Level 3 — Normative Script Behavior

Behavioral authority for script operation:

- `docs/SCRIPT-CONTRACT.md`
- domain-specific normative supplements such as:
  - `docs/IDENTITY.md`
  - `docs/SOFTWARE.md`

These define:
- script classes and allowed behavior
- output and exit expectations
- domain-specific operating constraints

These files are subordinate to Level 1 and Level 2.
They must not redefine architecture or repository identity.

---

### Level 4 — Operational Guidance

Supporting operational documents:

- `docs/OPERATING-MANUAL.md`
- `docs/ANNUAL-MAINTENANCE.md`
- `docs/DESIGN-RATIONALE.md`
- `docs/index.md`

These explain:
- usage rules
- maintenance practice
- rationale
- documentation navigation

These files support understanding and operation,
but they do not override higher authority.

---

### Level 5 — Planning and Release Tracking

Planning and historical tracking:

- `ROADMAP.md`
- `CHANGELOG.md`

`ROADMAP.md` is **planning-only**.
It is informative.
It is not normative authority.

`CHANGELOG.md` is historical.
It records change, not authority.

Neither file may redefine architecture, scope, or script meaning.

---

### Level 6 — Implementation

Implementation artifacts:

- `core/`
- `scripts/`
- `tests/`
- `Makefile`
- `Makefile.audit`
- `Makefile.operational`
- `boring-admin.ps1`
- `.github/workflows/qa.yml`

Implementation must follow documentation.
Implementation may reveal inconsistency,
but inconsistency in implementation does not create authority.

---

### Level 7 — Internal Working Material

Internal or non-public working material:

- `.ai/`
- task-local prompts
- internal working artifacts
- draft implementation prompts such as `v002-impl.md`

These materials:
- may guide execution discipline
- may support normalization work
- must not define product meaning
- must not override repository documentation

They are private-source operational materials,
not public architectural authority.

---

## Conflict Resolution Rules

### Rule 1 — Documentation beats implementation

If code and documentation conflict:
- documentation wins
- the conflict must be surfaced explicitly
- normalization may repair implementation or documentation only with explicit scope

### Rule 2 — Architecture beats planning

If `ROADMAP.md` conflicts with normative architecture:
- architecture wins

### Rule 3 — Product docs beat `.ai/`

If `.ai/` workflow material conflicts with repository docs:
- repository docs win

### Rule 4 — Supplements do not redefine baseline

Domain supplements such as `docs/IDENTITY.md` and `docs/SOFTWARE.md`
may refine behavior within a domain,
but they must not redefine baseline boundaries or repository scope.

---

## Current Interpretation for Normalization

For `v002` normalization, use this practical reading order:

1. `README.md`
2. `docs/STRUCTURE.md`
3. `docs/ARCHITECTURE-GUARD.md`
4. `docs/ARCHITECTURE-v002.md`
5. `docs/SCRIPT-CONTRACT.md`
6. domain supplements
7. operational guidance
8. planning and changelog
9. implementation
10. `.ai/`

---

## Final Rule

Authority must remain boring, explicit, and stable.

If authority is ambiguous,
work must stop until the ambiguity is resolved.
