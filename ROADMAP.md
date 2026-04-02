# ROADMAP.md
boring-admin-windows

This roadmap defines the **intentional evolution**
of the `boring-admin-windows` reference implementation.

It describes:
- what is **already completed**
- what is **considered stable**
- what is **intentionally planned**
- what is **explicitly not implemented**

This document is **planning-only**.

If issues, milestones, or implementation diverge from this roadmap,
normative repository documentation takes precedence.

---

## Project status overview

The project is currently in the following state:

> **Architecture is stable.  
> Core lifecycle is implemented.  
> Further evolution is controlled and additive only.**

The operating model is fully defined and documented.
The existing implementation serves as a **reference**, not as an exhaustive toolkit.

It expresses **direction and intent**, not commitment.
It is **not part of any release contract**.

Architectural truth is defined exclusively
by frozen architectural documents and tagged releases.

---

## PHASE 0 — ARCHITECTURE & CONTRACTS (COMPLETED)

**Status:** ✅ CLOSED
**Release:** v0.0.1  
**Nature:** normative, frozen

### Goal

Define and lock the operating model and architectural boundaries
*before* expanding implementation scope.

Phase 0 exists to answer:

- What this system **is**
- What it **is not**
- What must **never change silently**

### Completed outputs (frozen)

The following documents define the **architectural contract**
of the project and are considered stable:

- `README.md` — repository contract and scope
- `docs/STRUCTURE.md` — lifecycle architecture and responsibility boundaries
- `docs/ARCHITECTURAL-POSITION.md` — system identity and promise
- `docs/DESIGN-RATIONALE.md` — architectural decisions and trade-offs
- `docs/ARCHITECTURE-GUARD.md` — non-negotiable architectural rules
- `DISCLAIMER.md` — scope and liability boundaries

### Notes

- Phase 0 documents must not be modified.
- Any change to their meaning requires a **new architectural phase**
  and a new tagged release.
- Implementation completeness is explicitly **out of scope** for Phase 0.

---

## PHASE 1 — CORE LIFECYCLE IMPLEMENTATION (COMPLETED)

**Status:** ✅ COMPLETED  
**Nature:** minimal, readable, reference-level

### Implemented lifecycle domains

#### 00–09 — Environment & Safety
- `00-env-preflight.ps1`

Environment validation, privilege checks, fail-fast behavior.
No system state modification.

---

#### 10–19 — OS Bootstrap
- `10-bootstrap-orchestrator.ps1`
- `11-bootstrap-system-features.safe.ps1`
- `15-bootstrap-consumer-noise.safe.ps1`

Minimal OS preparation.
Noise reduction without irreversible changes.

---

#### 20–29 — Security & System Policy
- `20-security-orchestrator.manual.ps1`
- `21-security-baseline.manual.ps1`

Intentional administrative configuration.
Not a hardening framework.

---

#### 40–49 — Identity & Access
- `40-identity-local-orchestrator.manual.ps1`
- `41-identity-local-admin-model.manual.ps1`
- `45-identity-local-temporary-access.manual.ps1`

Explicit, manual identity operations.
Security-critical actions remain human-driven.

---

#### 50–59 — Host Identity
- `50-host-identity-orchestrator.manual.ps1`
- `51-host-identity-core.manual.ps1`

Hostname, locale, timezone, and basic device identity.

---

#### 60–69 — Recovery & Continuation
- `60-recovery-visibility.verify.ps1`

Limited read-only recovery visibility.
No automated restoration, no hidden recovery orchestration.

---

#### 90–99 — Audit & Reporting
- `90-system-state.verify.ps1`

Read-only audit.
No remediation, no enforcement.

---

### State
The implementation matches documented intent.
The system is **usable within the defined scope**.

---

## PHASE 2 — SOFTWARE DELIVERY (PLANNED / NON-CORE)

**Status:** 🔒 CLOSED (planned, optional)  
**Lifecycle domain:** 30–39

### Goal
Introduce **predictable and auditable software delivery**
as an **optional mechanism**, without redefining or extending
core operating system behavior.

### Architectural rules
- Software delivery is **NOT part of the mandatory core lifecycle**
- Package managers are used strictly as **transport mechanisms**
- Application installation ≠ application configuration
- No hidden state, background services, or auto-updaters
- No role inference or dynamic behavior
- Core system behavior must remain independent of software delivery

### Implemented (optional) scripts
- `30-software-orchestrator.manual.ps1`
- `31-software-packager-choco.manual.ps1`
- `31-software-packager-winget.manual.ps1`
- `32-software-baseline-choco.manual.ps1`
- `32-software-baseline-winget.manual.ps1`
- `34-software-ux-choco.manual.ps1`
- `34-software-ux-winget.manual.ps1`

### Notes
Software delivery exists as a **documented and reversible extension**.
It is intentionally **excluded from Phase-1 core lifecycle guarantees**.

Presence of these scripts does not imply requirement,
automatic execution, or baseline dependency.


---

## PHASE 3 — TESTING & VALIDATION (PARTIALLY IMPLEMENTED)

**Status:** 🟡 ACTIVE (bounded `v002` baseline implemented)  
**Nature:** contract validation, not compliance

### Goal
Prevent regression and contract violations.

### Scope
- public integrity validation
- PowerShell linting
- unit tests for `core/lib/*`
- smoke validation for supported read-only entry surfaces
- contract validation for current script rules

### Explicitly out of scope
- OS state validation
- Automated remediation
- Continuous compliance enforcement

### Current `v002` baseline

The repository already includes:

- `tests/integrity/`
- `tests/lint/`
- `tests/unit/`
- `tests/smoke/`
- `tests/contract/`
- `tests/Invoke-Tests.ps1`

This is intentionally a **bounded QA baseline**,
not a claim of full integration or compliance testing.

---

## PHASE 4 — MAKEFILE & ORCHESTRATION (PLANNED)

**Status:** 🟡 PLANNED  
**Nature:** human-first orchestration

### Goal
Provide a **clear, documented entry point**
for administrators.

### Characteristics
- Explicit execution order
- No implicit branching
- No automation magic

### Example targets
- `make bootstrap`
- `make baseline`
- `make software`
- `make audit`
- `make test`

The Makefile is **not a pipeline**.
It is a documented operational memory.

---

## PHASE 5 — CI AS CONTRACT GUARD (PARTIALLY IMPLEMENTED)

**Status:** 🟡 ACTIVE (public QA workflow implemented)  
**Nature:** validation only

### Goal
Protect architectural and script contracts.

### CI responsibilities
- Script linting
- public test execution
- public integrity execution

### CI non-responsibilities
- Running SAFE scripts
- Executing MANUAL scripts
- Managing system state

CI exists to **reject invalid changes**, not to operate systems.

### Current `v002` baseline

The repository already includes:

- `.github/workflows/qa.yml`
- Windows GitHub Actions execution
- lint, integrity, smoke, unit, and contract suites

CI remains intentionally limited to public validation surfaces.

---

## RESERVED LIFECYCLE DOMAINS (INTENTIONALLY UNIMPLEMENTED)

The following domains are defined but intentionally not implemented:

- 70–79 — Maintenance
- 80–89 — Incident Handling

Active state modeling is intentionally excluded from `v002`
and reserved for future `v003` work.

Their absence is a **deliberate architectural decision**, not technical debt.

---

## Final statement

This roadmap does not aim to:
- maximize features
- optimize Windows
- guarantee security

Its purpose is to ensure the system remains:

> **understandable, predictable, and transferable  
> even years later without the original author.**

If the roadmap remains boring,
the project is successful.
