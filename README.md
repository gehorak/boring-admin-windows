# boring-admin-windows

Reference implementation of a **boring, predictable operating model**
for Windows workstation administration.

This repository documents an **explicit operating model**
for managing Windows systems in small environments
without Active Directory and without MDM.

It prioritizes clarity, lifecycle thinking, recoverability,
and **human-driven operation**
over automation, optimization, and enforcement.

---

## Scope

This repository applies to:

- Windows workstations (currently Windows 11 Pro)
- small environments (SMB, professional home offices)
- systems without Active Directory
- systems without Intune or other MDM solutions
- environments managed by a single administrator or a small team

The focus is on **workstation lifecycle management**,
not centralized control or continuous enforcement.

---

## Non-goals

This repository intentionally does **not**:

- replace Active Directory or MDM solutions
- provide centralized or continuous policy enforcement
- implement aggressive hardening or debloating
- disable Windows Update, Windows Defender, or core OS components
- provide unattended, one-click, or fully automated installation
- optimize Windows for performance or privacy extremes

If you require centralized enforcement,
compliance guarantees, or large-scale fleet management,
this operating model is **not appropriate**.

---

## Core principles

The operating model documented here is based on a small set
of **non-negotiable architectural principles**:

- **Explicit over implicit**  
  All actions are intentional, visible, and reviewable.

- **Process over state**  
  Procedures matter more than snapshots or images.

- **Reinstall over repair**  
  Recovery is preferred over fragile, stateful fixes.

- **Verification over enforcement**  
  Visibility and understanding precede control.

- **Boring is good**  
  Predictability is a feature, not a limitation.

---

## Repository role

This repository is **not a toolkit**.

It is a **documented operating model**
with a reference implementation.

Scripts and tooling included here exist
to **support the operating model**,
not to serve as a general-purpose Windows tweaking framework.

Internal AI execution-discipline material may exist in `.ai/`
inside the private governing repository,
but it is not part of the public operating model or release surface.

You are expected to read and understand
the documentation **before**
executing any implementation artifacts.

---

## Entry points

Repository entrypoints are intentionally split by audience and runtime:

- [boring-admin.ps1](./boring-admin.ps1)  
  Windows-native PowerShell entrypoint for discovery, audit, verify,
  apply, and overlay access.

- [Makefile](./Makefile)  
  Safe explorer and discovery entrypoint for Make-based environments.

- [Makefile.audit](./Makefile.audit)  
  Read-only audit, verify, and recovery visibility entrypoint.

- [Makefile.operational](./Makefile.operational)  
  Explicit apply and overlay entrypoint for Make-based environments.

Recommended rule:
- on Windows, start with `.\boring-admin.ps1 help`
- for machine-readable output, use `.\boring-admin.ps1 audit export`
- for archived human-readable output, use `.\boring-admin.ps1 audit save`
- for a short human summary, use `.\boring-admin.ps1 audit summary`
- in Make-based environments, start with `make help`
- review audit surfaces before running write-capable entrypoints

---

## Documentation as architecture

This repository is incomplete without its documentation.

Normative documents define the operating model
and take precedence over implementation details.

Implementation follows documentation —
**not the other way around**.

Repository interpretation and precedence are defined in:
- [docs/AUTHORITY.md](./docs/AUTHORITY.md)

Current repository status, including internal versus active product surface,
is defined in:
- [docs/REPOSITORY-STATUS.md](./docs/REPOSITORY-STATUS.md)

Public/private publication handling is documented in:
- [docs/PUBLIC-EXPORT.md](./docs/PUBLIC-EXPORT.md)

A compact operator-facing boundary summary is available in:
- [docs/BOUNDARIES.md](./docs/BOUNDARIES.md)

Command reference for the main entry surfaces is available in:
- [docs/COMMANDS.md](./docs/COMMANDS.md)

The current machine-readable audit export shape is documented in:
- [docs/AUDIT-EXPORT-FORMAT.md](./docs/AUDIT-EXPORT-FORMAT.md)

QA and test direction is documented in:
- [docs/TEST-STRATEGY.md](./docs/TEST-STRATEGY.md)

Public-facing test scaffolding is available in:
- [tests/](./tests/)

Current QA baseline includes:
- PowerShell lint via PSScriptAnalyzer
- integrity validation
- Pester-backed smoke tests
- Pester-backed unit tests
- Pester-backed contract tests
- GitHub Actions QA on Windows for lint, integrity, smoke, unit, and contract suites

Recommended first-setup order for a new workstation is documented in:
- [docs/FIRST-WORKSTATION-SETUP.md](./docs/FIRST-WORKSTATION-SETUP.md)

A compact operator onboarding path is available in:
- [docs/GETTING-STARTED.md](./docs/GETTING-STARTED.md)

Short scenario-based operator walkthroughs are available in:
- [docs/COMMON-SCENARIOS.md](./docs/COMMON-SCENARIOS.md)

---

## Releases

Releases represent **stable architectural reference points**,
not feature updates.

A release indicates that:

- the operating model is coherent
- architectural documents are frozen
- implementation (if present) aligns with the documentation

Releases are expected to be **infrequent**
and deliberate.

---

## Audience

This repository is intended for:

- system administrators
- technicians
- technically inclined owners

It is **not** intended for casual users
or environments requiring strict central enforcement.

---

## Project roadmap

Future evolution of the project is described in
[ROADMAP.md](./ROADMAP.md).

The roadmap expresses **intent**, not commitment,
and is **not part of the release contract**.

---

## Licensing Direction

This repository uses a single licensing model that protects:

- the **documented operating model and documentation**
- the **implementation code**
- the **project name and branding**
- **commercial monetization rights**

Selected structure:

- the whole repository:
  `Boring Admin Reference License 1.0`
- project name and official branding claims:
  reserved under a naming/trademark policy
- paid training, consulting, redistribution, and commercial packaging:
  reserved unless separately permitted

Reference documents:

- [LICENSE-SUMMARY.md](./LICENSE-SUMMARY.md)
- [LICENSE](./LICENSE)
- [TRADEMARKS.md](./TRADEMARKS.md)
- [COMMERCIAL.md](./COMMERCIAL.md)

---

## Final note

> **If nothing surprises you after a year of operation,
> this operating model has achieved its goal.**
