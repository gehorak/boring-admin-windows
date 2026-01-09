# DESIGN-RATIONALE.md

Design Rationale  
Windows Workstation — No Domain Environment

---

## Purpose

This document explains **why the system is designed the way it is**.

It exists to:

- preserve architectural decisions over time
- protect the system from accidental overengineering
- enable handover to another technician
- provide justification during audits or reviews

This document is **not** a how-to guide.  
It documents **intent, constraints, and trade-offs**.

It must be read together with:
- ARCHITECTURE-GUARD
- ARCHITECTURAL-POSITION

---

## Context and constraints

### Environment

- Windows 11 Pro workstations
- no Active Directory
- no Intune or other MDM solutions
- SMB or professional home-office usage

### Constraints

- limited administrative time
- no centralized enforcement mechanism
- the system must remain operable without the original administrator

Enterprise-scale patterns are therefore **intentionally out of scope**.

These constraints are considered **structural**, not temporary.

---

## Core architectural principle

> **The operating system is disposable.  
> Data and identity are valuable.**

This principle informs all other design decisions
and is not subject to later revision within this phase.

**Implications:**

- operating system issues are resolved by reinstall, not repair
- user data must survive complete OS loss
- user identity must not be bound to a specific device

---

## Account model decision

### Selected model

- one primary local administrator account
- one disabled recovery administrator account
- daily users operate as standard users with a cloud-backed identity

### Rationale

- administrative privileges are the primary attack vector
- UAC is not a security boundary
- most malware executes in user context

Separating administration from daily work provides the
**largest security benefit for the lowest operational cost**.

---

## Identity and data strategy

### Cloud-backed user identity

Cloud-backed user identities are used for end users because they provide:

- device-independent identity
- built-in multi-factor authentication
- session revocation and account recovery

Local-only user identities were rejected due to
high loss and recovery risk.

---

### Cloud-backed user data

Cloud-backed user data storage is used because it enables:

- automatic backup
- file versioning and rollback
- rapid recovery after system reinstall

Local-only data storage was rejected due to
unacceptable data loss risk.

---

## Disk encryption decision

### Requirement

- full-disk encryption enabled on all internal drives
- recovery keys stored outside the device

### Rationale

- device loss or theft is a realistic scenario
- data-at-rest protection is mandatory
- encryption imposes near-zero user experience cost

This is a **low-effort, high-impact** security control
that does not alter the operating model.

---

## Software deployment strategy

### Rejected approaches

- golden images
- image-based lifecycle management
- heavy unattended deployment pipelines

### Selected approach

- clean OS installation
- small, readable administrative scripts
- a dedicated package transport mechanism used strictly for software delivery

This avoids hidden state, image drift,
and opaque deployment behavior.

---

## Debloat philosophy

### Selected approach: SAFE-ONLY debloat

**Allowed actions:**

- removal of selected consumer applications
- disabling ads, tips, and widgets
- sane Explorer defaults

**Explicitly disallowed actions:**

- telemetry manipulation
- disabling Windows Defender or Windows Update
- removal of core system components
- disabling services or scheduled tasks

The goal is to **reduce noise, not functionality**.

---

## Security baseline philosophy

Security in this model prioritizes:

- defaults over tweaks
- verification over enforcement
- recoverability over lockdown

The following are intentionally avoided in the baseline:

- registry hardening hacks
- custom firewall rules
- service disabling

These choices define the **baseline security posture** of the system.

More restrictive security measures belong to **overlays**
or require a **new architectural phase**.

---

## Recovery-first operating model

All incidents are treated as expected operational events:

- hardware failure
- malware or ransomware
- data corruption
- device loss or theft

**Standard response:**

1. wipe the system
2. reinstall Windows
3. reapply the baseline
4. sign the user in
5. restore data automatically

Repair is optional.  
Recovery is guaranteed.

---

## Networking responsibility boundary

Networking concerns (LAN, Wi-Fi, VLANs, firewalls)
are **not managed at the workstation level**.

**Rationale:**

- without a domain, enforcement is not reliable
- network security belongs to infrastructure, not endpoints

The workstation is treated as a **network consumer**, not an authority.

---

## Documentation as architecture

The system is incomplete without its documentation.

The following documents are considered **architectural components**:

- Architecture Guard
- Architectural Position
- Operating Manual
- Annual Maintenance Checklist
- Design Rationale (this document)

Undocumented systems are
**person-dependent and operationally fragile**.

---

## Conscious omissions

This design intentionally does not attempt to address:

- centralized compliance enforcement
- forensic investigation workflows
- advanced network monitoring

These concerns are outside the defined scope
and require different architectural foundations.

---

## When this design no longer fits

This operating model should be replaced when:

- the number of managed devices grows significantly
- multiple technicians manage the environment
- centralized enforcement becomes a requirement

In such cases, this design is **not evolved**.

It is replaced by a **new architectural phase**
with a **new design rationale**.

---

## Final statement

> **The goal was not to build the most secure Windows system possible.  
> The goal was to build a Windows system that can be safely operated for years.**

This design optimizes for:

- clarity
- resilience
- recoverability

At the cost of:

- reduced central control
- fewer enforcement mechanisms

This trade-off is intentional
and appropriate for the target environment.
