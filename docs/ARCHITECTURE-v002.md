# Architecture v002 — Operational Boundary Contract

## Status

- Architecture version: v002
- State: normative working contract for v002 normalization
- Supersedes: v001 (Phase 0)
- Scope: boring-admin-windows

This document defines the **operational architectural contract** of the
boring-admin-windows project.

Architecture v002 is a **normative specification**.
It is not an implementation guide, a security baseline, or a best-practice document.

---

## Purpose

The purpose of architecture v002 is **not to maximize security**.

Its purpose is to:

- protect correct operational decision-making
- prevent continuation by habit
- make system termination a valid and explicit outcome
- ensure that responsibility remains visible at all times

This architecture is designed for environments where **the most dangerous actor
is a well-intentioned administrator continuing in uncertainty**.

---

## Relationship to Architecture v001

Architecture v002 is a formal continuation of the architectural contract
established in **v001 (Phase 0)**.

Architecture v001 remains **valid, authoritative, and unchanged**.
It defines the system’s identity, scope, non-negotiable rules,
and responsibility boundaries.

Architecture v002 does **not replace v001**.
It extends it by making **operational boundaries explicit**
where v001 intentionally remained abstract.

### Inheritance

v002 inherits from v001 without reinterpretation:

- architecture as a normative contract
- explicit system identity and scope
- non-negotiable architectural rules
- clear responsibility and liability boundaries
- rejection of implicit behavior and self-healing mechanisms

### Refinement

v002 refines v001 by explicitly defining:

- decision boundaries instead of lifecycle phases
- baseline vs overlay separation
- audit as a cross-cutting visibility capability
- recovery as a baseline stop condition
- user experience as an operational safety factor (without baseline authority)

### Continuity statement

Architecture v001 defines **what the system is**.  
Architecture v002 defines **when the system must stop**.

Both versions coexist:
- v001 as the foundational contract
- v002 as the operational boundary specification

---

## Core Architectural Principle

> **The architecture must allow mistakes in action,  
> but must never allow mistakes in decision.**

Specifically:
- errors in execution are acceptable
- ambiguity in responsibility is not
- continuation without a decision is forbidden

---

## Baseline Definition (FINAL)

The baseline is intentionally **minimal, complete, and closed**.

It defines the **smallest possible system that is still safe to operate**.

The baseline MUST NOT be expanded beyond the boundaries defined below.

### Baseline Boundaries

#### 20 — SECURITY (Responsibility Boundary)

Defines:
- who is responsible
- who carries consequences
- where liability is explicit

Security here is not prevention.
It is **ownership of outcomes**.

---

#### 40 — IDENTITY (Role Boundary)

Defines:
- who is acting
- in which role
- with which level of authority

Key rules:
- role changes must be explicit
- administrative action must never be implicit

Identity exists to protect the **meaning of “admin”**.

---

#### 50 — HOST (Reality Boundary)

Defines:
- what system is being operated on
- where the action takes place
- what is considered disposable

The operating system is treated as **expendable**.
Clarity of host identity is mandatory.

---

#### 60 — RECOVERY (Continuation Boundary)

Defines:
- when continuation is no longer safe
- when termination is the correct action
- when recovery is preferred over repair

Recovery is a **baseline concept**, not an overlay feature.

Termination is a valid and expected outcome.

Implementation note for `v002`:
- recovery is represented through explicit recovery path visibility,
  not through automated restoration logic
- `v002` may expose limited read-only recovery checks
- full state-driven recovery orchestration is outside `v002`

---

## Audit Position

Audit is a **cross-cutting capability** of all baseline boundaries.

Audit:

- MUST NOT enforce
- MUST NOT remediate
- MUST NOT react automatically
- MUST NOT extend system lifetime

Audit exists solely to:

- reconstruct reality
- confirm loss of certainty
- support the decision to stop

When audit begins to act, it ceases to be audit and becomes enforcement.

---

## Overlay Model

Anything that increases:

- prevention
- hardening
- restriction
- compliance
- availability
- resilience
- friction

is **not baseline**.

These mechanisms belong to **overlays**.

Overlay rules:

- overlays are optional
- overlays are removable
- overlays are consciously enabled
- overlays are never enabled during incidents
- overlays must not mask uncertainty
- overlays must not prevent recovery

Overlays must never be used to decide whether a system is safe.
Only baseline boundaries define correctness and stop conditions.

---

### UX as an Overlay Constraint

User experience mechanisms are treated as overlays.

UX does not define correctness, safety, or continuation conditions.
It exists solely to expose baseline boundaries, slow down risky actions,
and reduce accidental continuation.

UX mechanisms:
- have no authority
- have no independent STOP condition
- must not mask uncertainty
- must not prevent recovery

UX is a **boundary amplifier**, not a boundary itself.

---

## STOP Principle

A STOP must occur whenever:

- the next action changes system state
- responsibility is about to shift
- uncertainty increases

STOP is not a dialog.
STOP is a **role transition**.

Key separations:

- verify ≠ apply
- read ≠ write
- observe ≠ act

The system must make it difficult to continue by habit.

---

## What This Architecture Explicitly Rejects

Architecture v002 explicitly rejects:

- phase-driven lifecycle as the primary model
- the notion of a “completed” system
- implicit baseline growth
- self-healing mechanisms
- automatic security reactions
- security as maximal prevention

Any such mechanisms belong to overlays or processes,
never to the baseline.

---

## Change Policy

Architecture v002 is **frozen by definition**.

From the moment of freeze:

- baseline boundaries MUST NOT change
- meaning MUST NOT drift through implementation
- architectural changes require a new version

Any future evolution must follow the same pattern:

1. isolated architectural exploration
2. explicit contract definition
3. formal freeze

---

## Final Statement

This architecture does not aim to keep systems running at all costs.

It aims to ensure that **when uncertainty grows,
the system can be stopped without hesitation,
without guilt, and without confusion**.

That ability is treated as the highest form of operational safety.
