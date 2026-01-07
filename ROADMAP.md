# ROADMAP.md
boring-admin-windows

This roadmap defines the **intentional evolution**
of the `boring-admin-windows` reference implementation.

It describes:
- what is **already completed**
- what is **considered stable**
- what is **intentionally planned**
- what is **explicitly not implemented**

This document is **normative**.

If issues, milestones, or implementation diverge from this roadmap,
the roadmap takes precedence.

---

## Project status overview

The project is currently in the following state:

> **Architecture is stable.  
> Core lifecycle is implemented.  
> Further evolution is controlled and additive only.**

The operating model is fully defined and documented.
The existing implementation serves as a **reference**, not as an exhaustive toolkit.

---

## PHASE 0 — ARCHITECTURE & CONTRACTS (COMPLETED)

**Status:** ✅ CLOSED  
**Nature:** normative, stable

### Goal
Define and lock the operating model **before**
expanding implementation scope.

### Completed outputs

- `README.md` — repository contract and scope
- `STRUCTURE.md` — lifecycle domains and responsibilities
- `DESIGN-RATIONALE.md` — architectural decisions and trade-offs
- `ARCHITECTURE-GUARD.md` — non-negotiable rules
- `OPERATING-MANUAL.md` — user-facing operational rules
- `ANNUAL-MAINTENANCE.md` — minimal long-term maintenance model
- `SCRIPT-CONTRACT.md` — PowerShell script behavior contract
- `DISCLAIMER.md` — scope and liability boundaries

### State
The architecture is considered **complete and stable**.
Any future change requires **explicit documentation revision**.

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
- `15-bootstrap-consumer-noise.safe.ps1`

Minimal OS preparation.
Noise reduction without irreversible changes.

---

#### 20–29 — Security & System Policy
- `20-security-baseline.ps1`
- `25-system-explorer-ux.ps1`

Intentional administrative configuration.
Not a hardening framework.

---

#### 40–49 — Identity & Access
- `40-identity-local-accounts.manual.ps1`
- `45-identity-local-guest.manual.ps1`

Explicit, manual identity operations.
Security-critical actions remain human-driven.

---

#### 50–59 — Host Identity
- `50-host-identity.ps1`

Hostname, locale, timezone, and basic device identity.

---

#### 90–99 — Audit & Reporting
- `90-audit-system-state.verify.ps1`

Read-only audit.
No remediation, no enforcement.

---

### State
The implementation matches documented intent.
The system is **usable within the defined scope**.

---

## PHASE 2 — SOFTWARE DELIVERY (PLANNED)

**Status:** 🟡 PLANNED  
**Lifecycle domain:** 30–39

### Goal
Introduce **predictable and auditable software delivery**
without redefining operating system behavior.

### Architectural rules
- Chocolatey is used strictly as a **package transport**
- Application installation ≠ application configuration
- No hidden state or auto-updaters
- No role inference or dynamic behavior

### Planned scripts
- `30-choco-install.ps1`
- `33-choco-core.ps1`
- `34-choco-baseline.ps1`
- `35-choco-optional.ps1`

### Notes
Software delivery must remain **explicit, reversible, and boring**.
Baseline must not depend on optional overlays.

---

## PHASE 3 — TESTING & VALIDATION (PLANNED)

**Status:** 🟡 PLANNED  
**Nature:** contract validation, not compliance

### Goal
Prevent regression and contract violations.

### Scope
- Unit tests for `lib/*`
- Dry-run validation for SAFE scripts
- Output and exit-code validation for VERIFY scripts

### Explicitly out of scope
- OS state validation
- Automated remediation
- Continuous compliance enforcement

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

## PHASE 5 — CI AS CONTRACT GUARD (PLANNED)

**Status:** 🟡 PLANNED  
**Nature:** validation only

### Goal
Protect architectural and script contracts.

### CI responsibilities
- Script linting
- Test execution
- VERIFY script execution

### CI non-responsibilities
- Running SAFE scripts
- Executing MANUAL scripts
- Managing system state

CI exists to **reject invalid changes**, not to operate systems.

---

## RESERVED LIFECYCLE DOMAINS (INTENTIONALLY UNIMPLEMENTED)

The following domains are defined but intentionally not implemented:

- 60–69 — Data & State
- 70–79 — Maintenance
- 80–89 — Incident & Recovery

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
