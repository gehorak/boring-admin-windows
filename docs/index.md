# Documentation

This directory contains the **normative documentation**
for the `boring-admin-windows` operating model.

These documents define architecture, lifecycle boundaries,
usage rules, and long-term maintenance expectations.

Implementation details follow this documentation
and must not contradict it.

---

## Current documentation set

The following documents define the complete operating contract
of the system:

### Architecture and structure

- **STRUCTURE.md**  
  Defines lifecycle domains, script responsibilities,
  and structural boundaries.

- **DESIGN-RATIONALE.md**  
  Explains why architectural decisions were made,
  including constraints and trade-offs.

- **ARCHITECTURE-GUARD.md**  
  Defines non-negotiable rules protecting the architecture
  from erosion over time.

---

### Operation and usage

- **OPERATING-MANUAL.md**  
  User-facing rules describing how the system is intended
  to be used on a daily basis.

- **ANNUAL-MAINTENANCE.md**  
  Minimal yearly maintenance checklist ensuring long-term
  predictability and recoverability.

---

## Document authority

These documents are **normative**.

If documentation and implementation diverge,
documentation is considered authoritative.

Changes to system behavior must be reflected here
before or together with implementation changes.

---

## Article series (planned)

This repository is accompanied by a series of articles
intended to explain the underlying philosophy and adoption model.

Each article introduces a single concept
and corresponds to one adoption step.

Planned topics include:

- Why boring administration scales better
- Treating the operating system as disposable
- Baseline versus overlays
- Human-driven orchestration
- Recovery-first system design

Articles will be published in this documentation tree
and rendered via GitHub Pages.

---

## How to read this documentation

Recommended reading order:

1. `README.md` (repository contract)
2. `STRUCTURE.md` (lifecycle and responsibilities)
3. `DESIGN-RATIONALE.md` (architectural decisions)
4. `ARCHITECTURE-GUARD.md` (non-negotiable rules)
5. `OPERATING-MANUAL.md` (usage rules)
6. `ANNUAL-MAINTENANCE.md` (long-term operation)

This order reflects the intended mental model.

---

## Status

The documentation set is considered **complete and stable**.

Future changes are expected to be:
- additive
- infrequent
- explicitly documented

---

## Final note

This documentation exists to make the system
understandable, transferable, and sustainable.

If these documents can be read and understood
without access to the original author,
they have fulfilled their purpose.
