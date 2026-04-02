# CHANGELOG

All notable changes to this project are documented in this file.

This changelog records **what changed**, not *why* it changed.
Architectural intent and rationale are documented separately.

The format is intentionally conservative and human-readable.

---

## [v0.0.2] — Phase 2 Software Delivery (Classified)

**Date:** 2026-01-20

### Changed

- Phase 2 (Software Delivery, lifecycle 30–39) was formally classified as
  **planned but non-core** under architecture v001.
- Software delivery mechanisms are explicitly documented as **optional** and
  excluded from mandatory core lifecycle guarantees.

### Added

- None.

### Deprecated

- Any implicit assumption that software delivery
  is part of the required baseline system lifecycle.

### Removed

- None.

### Fixed

- None.

### Notes

- This entry records a **classification and boundary clarification only**.
- No runtime behavior, defaults, or execution flow were changed.
- Presence of software delivery scripts does not imply requirement
  or automatic usage.



## [v0.0.1] — Phase 0 Architecture (Frozen)

**Date:** 2026-01-09

### Added

- Defined and frozen the **architectural operating model**
  for Windows workstation administration without AD or MDM.
- Introduced a complete set of **normative architectural documents**:
  - repository scope and expectations
  - lifecycle architecture and responsibility boundaries
  - system identity and architectural promise
  - design rationale and consciously rejected alternatives
  - non-negotiable architectural rules
  - responsibility and liability boundaries
- Established a clear **separation between architecture (Phase 0)**
  and future implementation work (Phase 1+).

### Changed

- Project status transitioned from exploratory
  to **architecturally defined and bounded**.
- The repository is now suitable as a
  **stable architectural reference point**.

### Deprecated

- Implicit or undocumented assumptions
  about system behavior or administration practices.

### Removed

- None.

### Fixed

- None.

### Notes

- This release freezes architecture only.
- No implementation completeness or runtime behavior
  is implied or guaranteed.
- Future changes to architectural meaning
  require a new architectural phase and a new tagged release.

---

## Changelog conventions

- Architectural releases document **contracts and boundaries**.
- Implementation releases document **behavioral changes**.
- Absence of an entry means no change in that category.

The changelog is **append-only**.
Past entries must not be modified.
