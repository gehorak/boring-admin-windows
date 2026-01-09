# ARCHITECTURAL-POSITION.md

Architectural Position  
boring-admin-windows

---

## Purpose

This document defines the **architectural position** of the
boring-admin-windows project.

It exists to:

- preserve architectural intent over time
- provide context for future maintainers, architects, and AI systems
- prevent misinterpretation of design decisions
- explain *why* the system is the way it is, not *how* it is implemented

This document is **normative in intent**, not instructional.

If this document is understood,
the architecture does not need to be rediscovered.

---

## Project identity

boring-admin-windows is a **reference operating model**
for administering Windows workstations in environments:

- without Active Directory
- without Intune or other MDM
- managed by a single administrator or a very small team
- where long-term operability matters more than central enforcement

The project addresses **responsibility and lifecycle**,
not configuration completeness.

It is intentionally conservative.

---

## Core architectural promise

> **This system can be operated safely for years  
> without centralized control,  
> without continuous enforcement,  
> and without the original author present.**

Everything in this project serves this promise.

Any proposal that changes this promise
is not an evolution — it is a different system.

---

## Baseline as a contract

The baseline in this project is:

- minimal
- stable
- intentionally non-optimizing
- independent of roles, scenarios, or environments

The baseline is a **contract**, not a recommendation.

It represents the minimum system state
the architect is willing to guarantee
without context, supervision, or explanation.

The baseline does not improve over time.
It is replaced only by a new architectural phase.

---

## Overlays as controlled divergence

All meaningful growth happens through **overlays**.

An overlay is:

- explicit
- optional
- removable
- risk-bearing

Overlays exist to address:
- specific threats
- specific environments
- specific roles
- specific trade-offs

Overlays never redefine the baseline.
If an overlay becomes unavoidable,
the architecture itself must change.

---

## Security position

Security in this project is defined as:

> **The ability to operate, recover, and understand the system over time.**

Security is **not** defined as:
- maximal restriction
- compliance alignment
- continuous enforcement
- prevention at all costs

The project favors:
- defaults over tweaks
- verification over enforcement
- recoverability over lockdown

This is a deliberate trade-off,
not a technical limitation.

---

## Reinstall-first operating model

The operating system is treated as **disposable**.

Expected events include:
- system corruption
- malware incidents
- hardware failure
- device loss

The standard response is:
1. reinstall the OS
2. reapply the baseline
3. restore identity
4. recover data

Any design that assumes the OS must be preserved
is considered architecturally flawed.

---

## Human-centered operation

This system is **human-operated by design**.

- No background automation
- No hidden remediation
- No implicit execution
- No autonomous correction

Humans are the decision-makers,
not pipelines or agents.

Automation is acceptable only
when it does not obscure intent.

---

## Architectural evolution

Architectural evolution is **additive only**.

Evolution may:
- add overlays
- add lifecycle stages
- add documentation
- add verification tools

Evolution must not:
- change the meaning of the baseline
- change the role of humans
- change the risk posture
- change architectural invariants

When such change is required,
a new architectural phase is created.

---

## Role of this document

This document:

- is not a checklist
- is not a guide
- is not a policy

It is an **interpretive anchor**.

When a future maintainer, contributor, or AI system
needs to decide whether something belongs here,
this document should make the answer obvious.

If a proposal feels technically correct
but conceptually uncomfortable,
this document explains why.

---

## Intended longevity

This architectural position is written to remain valid
even as:

- Windows versions change
- tooling evolves
- best practices shift
- security trends fluctuate

If this document no longer feels appropriate,
the project has entered a new phase.

---

## Final statement

> **This project is not about making Windows better.  
> It is about making Windows survivable.**

If the system remains boring,
predictable, and recoverable years later,
the architecture has succeeded.
