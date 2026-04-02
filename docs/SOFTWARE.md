# SOFTWARE LIFECYCLE (30–39)

This document defines the **software lifecycle model** used in
`boring-admin-windows`.

Software management is treated as a **conscious, explicit activity**,
not an automated optimization process.

> Boring is a feature.  
> Explicit intent beats hidden automation.

---

## 1. Design Philosophy

Software in this project is managed according to these principles:

- **Transport ≠ Baseline ≠ UX**
- Installation is always **explicit**
- No software is installed “because it might be useful”
- Reinstallation is preferred over repair
- Visibility is more important than optimization

Automation exists only where:
- intent is clear
- scope is bounded
- behavior is predictable
- rollback is obvious

---

## 2. Lifecycle Overview

Software lifecycle occupies **Stage 30–39** and is intentionally split
into independent layers:

```

30-software-orchestrator
│
├─ 31-software-packager-*        (transport)
├─ 32-software-baseline-*        (minimal expected tools)
├─ 39-software-inventory.verify  (visibility)
└─ 34-software-ux-*              (optional operator UX)

```

Each layer answers a different question.

---

## 3. Transport Layer (31)

### Purpose

The transport layer ensures that **package managers are available and
configured**, nothing more.

### Key rules

- Transport layers **do not install software**
- They do not define *what* should be installed
- They exist only to provide a reliable delivery mechanism

### Implementations

- `31-software-packager-choco.manual.ps1`
- `31-software-packager-winget.manual.ps1`

Current support posture:

- **Chocolatey** is the primary manually tested software path
- **WinGet** is the secondary native / minimal-compatibility path

Both scripts:
- are idempotent
- configure non-interactive behavior
- reduce telemetry and noise
- do not perform upgrades

---

## 4. Software Baseline (32)

### Purpose

The software baseline defines a **minimal, role-agnostic set of tools**
expected on every administered system.

This is **not a developer stack**  
This is **not personalization**

Baseline software should be:
- broadly useful
- long-term stable
- low-risk
- understandable years later

### Characteristics

- MANUAL execution
- explicit package list
- no auto-upgrades
- no background services introduced implicitly

### Implementations

- `32-software-baseline-choco.manual.ps1`
- `32-software-baseline-winget.manual.ps1`

The two baselines are **not package-equivalent**.

Current intent:

- `choco` baseline is the broader, primary supported admin/tooling baseline
- `winget` baseline is a reduced secondary baseline for environments that intentionally stay on the native package path

That asymmetry is intentional and should be documented, not hidden.

---

## 5. UX Baseline (34)

### Purpose

The UX baseline improves **operator comfort and clarity** without
changing system policy or security posture.

UX baseline software:
- improves daily usability
- reduces friction and mistakes
- remains optional by design

### Important

- UX baseline is **never required**
- It is never executed by default
- Execution always requires conscious confirmation

### Implementations

- `34-software-ux-choco.manual.ps1`
- `34-software-ux-winget.manual.ps1`

The two UX paths are also **not package-equivalent**.

Current intent:

- `choco` UX is the primary curated UX surface
- `winget` UX is a reduced secondary UX surface aligned to the more conservative supported subset

UX baselines may include:
- password managers
- document viewers
- media tools
- remote access utilities

But never:
- developer environments
- background agents with unclear behavior
- auto-updaters outside package manager control

---

## 6. Orchestration (30)

### Purpose

`30-software-orchestrator.manual.ps1` is the **human-first entry point**
to the software lifecycle.

It:
- explains available components
- provides explicit choices
- never runs anything automatically
- enforces conscious decision-making
- exposes the support posture between primary `choco` and secondary `winget`

Orchestrators exist to **reduce mistakes**, not to speed things up.

---

## 7. Phase Alignment

### Current `v002` reality

The current repository already includes:

- transport scripts
- baseline software scripts
- UX overlay scripts
- read-only software visibility via `39-software-inventory.verify.ps1`

This means software visibility is part of the **current implemented optional software surface**,
not a future placeholder.

### Future direction beyond the current surface

Potential later expansion may include:

- stronger drift awareness
- richer software review tooling
- role-based software profiles
- explicit enforcement, if ever introduced under a new architectural decision

---

## 8. What This Layer Does NOT Do

Explicit non-goals of the software lifecycle:

- automatic remediation
- “keep everything updated”
- opinionated developer tooling
- system tuning
- security hardening

Those belong to other lifecycle stages or future phases.

---

## 9. Visibility / Inventory

### Purpose

Software visibility exists to answer:

> What software transport is available and what software signals are visible right now?

This layer is read-only.

### Implementation

- `39-software-inventory.verify.ps1`

It may be used for:

- annual review
- workstation takeover
- software sanity checks
- machine-readable export

Optional software approval and review guidance is documented in:

- [SOFTWARE-APPROVAL-MODEL.md](./SOFTWARE-APPROVAL-MODEL.md)

---

## 10. Mental Model Summary

| Layer | Question answered |
|-----|-------------------|
| Transport | *How can software be delivered?* |
| Baseline | *What is minimally expected?* |
| UX | *What improves daily work?* |
| Orchestrator | *What do I want to do now?* |

If you cannot clearly answer which layer a change belongs to,
it does not belong here.

---

## 11. Closing Note

Software is not configuration.
Software is not policy.
Software is not identity.

Software is a **tool**, and tools must remain:
- understandable
- replaceable
- optional

This document exists to keep it that way.

---

