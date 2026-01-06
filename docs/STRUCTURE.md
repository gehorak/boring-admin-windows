# STRUCTURE.md

Windows Administration Lifecycle — Script Structure Contract

---

## Purpose

This document defines the **structural and lifecycle contract**
for the `boring-admin-windows` project.

It names and bounds the **core responsibility domains**
involved in administering Windows workstations.

> Not every domain must be implemented immediately.
> **Every domain must have an explicit place in the architecture.**

---

## Core principles

- Numeric prefixes represent **system lifecycle stages**
- Each script has **a single, well-defined responsibility**
- Scripts **must not exceed their declared scope**
- The project addresses **responsibilities**, not tweaks

This structure is **normative**.
Deviations must be intentional and explicit.

---

## Lifecycle domains

---

### 00–09 — ENVIRONMENT & SAFETY

*Is it safe to proceed at all?*

```text
00-env-check.ps1
````

**Responsibilities:**

* execution privileges
* runtime environment validation
* platform compatibility
* fail-fast behavior

This stage must not modify system state.

---

### 10–19 — OS BOOTSTRAP

*Minimal preparation of the operating system*

```text
10-bootstrap.ps1
15-mini-debloat.safe.ps1
```

**Responsibilities:**

* establish a clean baseline OS state
* remove obvious consumer noise
* avoid irreversible changes

This stage prepares the system for administration,
not optimization.

---

### 20–29 — SECURITY & SYSTEM POLICY

*Intentional assumption of system control*

```text
20-security-baseline.ps1
25-system-configuration.ps1
```

**Responsibilities:**

* security baseline definition
* system policy configuration
* operational behavior of the OS

This is **not hardening**.
This is **explicit administrative configuration**.

---

#### Sub-layer: USER EXPERIENCE BASELINE (Human Factors)

*(Explicitly defined within 20–29)*

**Purpose:**

* reduce the likelihood of human error
* establish safe and readable defaults
* improve behavioral predictability

**Conceptual examples:**

* file extension visibility
* hidden file handling
* system dialog behavior
* Explorer defaults

This is **not aesthetics**.
It is **operational safety through user behavior**.

---

### 30–39 — SOFTWARE DELIVERY

*How software enters the system*

```text
30-choco-install.ps1
33-choco-core.ps1
34-choco-baseline.ps1
```

**Responsibilities:**

* define a single source of truth for installations
* ensure repeatability
* avoid interference with OS policy

This stage installs software without redefining system behavior.

---

### 40–49 — IDENTITY & ACCESS

*Who can sign in to the system*

```text
40-users.ps1
```

**Responsibilities:**

* local account management
* role separation (admin vs user)
* access boundaries

Identity decisions here are foundational
and security-critical.

---

### 50–59 — HOST & DEVICE IDENTITY

*What this machine is*

```text
50-host.ps1
```

**Responsibilities:**

* hostname
* locale
* timezone
* basic network identity

This stage defines how the system presents itself.

---

### 60–69 — DATA & STATE *(reserved)*

```text
# 60-data-layout.ps1
# 65-backup-baseline.ps1
```

**Responsibilities:**

* separation of OS and data
* backup strategy
* recovery state definition

This domain is reserved for future expansion.

---

### 70–79 — MAINTENANCE & LIFECYCLE

*Long-term system operation*

```text
# 70-maintenance.ps1
```

**Responsibilities:**

* periodic maintenance actions
* controlled change over time
* operational discipline

Maintenance is intentional and bounded.

---

#### Sub-layer: OBSERVABILITY & DIAGNOSTICS

*(Explicitly defined within maintenance)*

**Purpose:**

* observe system behavior over time
* surface issues before audit
* support incident analysis

**Conceptual examples:**

* event log retention
* crash dump policy
* baseline diagnostics

This is **not telemetry**.
It is **diagnostics for administrators**.

---

### 80–89 — INCIDENT & RECOVERY *(reserved)*

```text
# 80-incident-mode.ps1
```

**Responsibilities:**

* incident response
* damage containment
* information collection

This domain is intentionally separated
from normal maintenance.

---

### 90–99 — AUDIT & REPORTING

*Verification of system state*

```text
90-audit.ps1
```

**Responsibilities:**

* state verification
* readable reporting
* system handover readiness

Audit is **read-only**.
It must not modify system state.

---

## Structural violations

The following are considered violations of this contract:

* a script exceeding its declared responsibility
* UX configuration implemented in software delivery
* system changes performed during audit
* undocumented registry or policy changes

---

## Summary

> **Windows administration is not only about security and software.**
> It also includes system behavior, user behavior,
> and the ability to observe the system over time.

This structure explicitly acknowledges
and separates these responsibilities.

---