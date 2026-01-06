# boring-admin-windows

Reference implementation of boring, predictable Windows workstation administration.

This repository documents an explicit operating model
for managing Windows systems in small environments
without Active Directory and without MDM.

It prioritizes clarity, lifecycle thinking, recoverability,
and human-driven operation over automation and optimization.

---

## Scope

This repository applies to:

- Windows workstations (currently Windows 11 Pro)
- small environments (SMB, professional home offices)
- systems without Active Directory
- systems without Intune or other MDM solutions
- environments managed by a single administrator or a small team

The focus is on **workstation lifecycle management**, not centralized control.

---

## Non-goals

This repository intentionally does NOT:

- replace Active Directory or MDM
- provide centralized policy enforcement
- implement aggressive hardening or debloating
- disable Windows Update, Defender, or core OS components
- provide unattended or one-click installation
- optimize Windows for performance or privacy extremes

If you require centralized enforcement or compliance guarantees,
this operating model is not appropriate.

---

## Core principles

The operating model documented here is based on a small set
of non-negotiable principles:

- **Explicit over implicit**  
  All actions are intentional and visible.

- **Process over state**  
  Procedures matter more than snapshots.

- **Reinstall over repair**  
  Recovery is preferred over fragile fixes.

- **Verification over enforcement**  
  Visibility before control.

- **Boring is good**  
  Predictability is a feature, not a limitation.

---

## Repository role

This repository is **not a toolkit**.

It is a **documented operating model with a reference implementation**.

Scripts and tooling included here exist to support the model,
not to serve as a general-purpose Windows tweaking framework.

You are expected to read and understand the documentation
before executing any implementation artifacts.

---

## Documentation

This repository is incomplete without its documentation.

Normative documents define the operating model
and take precedence over implementation details.

Implementation follows documentation — not the other way around.

---

## Releases

Releases represent **stable reference points**, not feature updates.

A release indicates that:

- the operating model is coherent
- documentation and implementation are aligned
- the repository can be safely referenced externally

Releases are expected to be infrequent.

---

## Audience

This repository is intended for:

- system administrators
- technicians
- technically inclined owners

It is not intended for casual users
or environments requiring strict central enforcement.

---

## Final note

If nothing surprises you after a year of operation,
this repository has achieved its goal.
