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

You are expected to read and understand
the documentation **before**
executing any implementation artifacts.

---

## Documentation as architecture

This repository is incomplete without its documentation.

Normative documents define the operating model
and take precedence over implementation details.

Implementation follows documentation —
**not the other way around**.

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

## Final note

> **If nothing surprises you after a year of operation,
> this operating model has achieved its goal.**
