# STRUCTURE.md

Windows Administration Lifecycle — Architectural Structure

---

## Purpose

This document defines the **architectural lifecycle structure**
of the boring-admin-windows project.

It names and bounds the **core responsibility domains**
involved in administering Windows workstations.

It does **not** describe implementation details.
It defines **where responsibilities belong and where they do not**.

> Not every domain must be implemented immediately.
> **Every domain must have an explicit place in the architecture.**

This document is part of the **Phase 0 architectural contract**
and is intended to remain stable over time.

---

## Core principles

- Lifecycle domains represent **responsibility boundaries**, not scripts
- Each domain has a **single, explicit purpose**
- Responsibilities must not leak between domains
- Architecture defines *what belongs where*, not *how it is done*

This structure is **normative**.
Violations require architectural revision.

---

## Lifecycle domains

---

### ENVIRONMENT & SAFETY

**Intent:**  
Determine whether it is safe to proceed at all.

**Responsibilities:**
- execution preconditions
- environment validation
- platform compatibility
- fail-fast behavior

**Constraints:**
- must not modify system state

---

### OS BOOTSTRAP

**Intent:**  
Prepare a clean and administrable operating system baseline.

**Responsibilities:**
- establish a usable baseline OS state
- remove non-essential consumer noise
- avoid irreversible or fragile changes

**Constraints:**
- prepares for administration, not optimization
- must remain compatible with reinstall-first operation

---

### SECURITY & SYSTEM POLICY

**Intent:**  
Explicit assumption of administrative control over the system.

**Responsibilities:**
- baseline security posture
- system policy configuration
- definition of operational OS behavior

**Constraints:**
- this is not hardening
- enforcement and lockdown are out of scope

---

#### Sub-domain: USER EXPERIENCE BASELINE (Human Factors)

**Intent:**
- reduce likelihood of human error
- establish safe, readable defaults
- improve behavioral predictability

**Notes:**
- this is not aesthetics
- this is operational safety through user behavior

---

### SOFTWARE DELIVERY

**Intent:**  
Define how software enters the system.

**Responsibilities:**
- controlled software introduction
- repeatability
- separation from OS policy decisions

**Constraints:**
- must not redefine system behavior
- must not bypass security decisions

---

### IDENTITY & ACCESS

**Intent:**  
Define who can sign in and with what authority.

**Responsibilities:**
- local identity management
- role separation
- access boundaries

**Notes:**
- identity decisions are foundational
- mistakes here are security-critical

---

### HOST & DEVICE IDENTITY

**Intent:**  
Define what the machine is.

**Responsibilities:**
- system identity
- locale and regional settings
- basic network identity

---

### DATA & STATE

**Intent:**  
Ensure separation of operating system and data.

**Responsibilities:**
- data location strategy
- recovery state definition
- backup responsibility boundaries

**Notes:**
- this domain may be implemented later
- its absence does not invalidate the architecture

---

### MAINTENANCE & LIFECYCLE

**Intent:**  
Enable controlled, long-term operation.

**Responsibilities:**
- intentional maintenance actions
- bounded change over time
- operational discipline

---

#### Sub-domain: OBSERVABILITY & DIAGNOSTICS

**Intent:**
- observe system behavior over time
- support audits and incident analysis

**Constraints:**
- observability is not telemetry
- diagnostics must not enforce state

---

### INCIDENT & RECOVERY

**Intent:**  
Respond to abnormal or destructive events.

**Responsibilities:**
- incident containment
- recovery coordination
- information collection

**Constraints:**
- separated from normal maintenance
- prioritized for speed and clarity

---

### AUDIT & REPORTING

**Intent:**  
Verify system state and readiness.

**Responsibilities:**
- state verification
- readable reporting
- handover support

**Constraints:**
- audit is strictly read-only
- must not modify system state

---

## Structural violations

The following are considered architectural violations:

- responsibility leakage between domains
- state modification during audit
- enforcement logic hidden outside security domains
- undocumented system changes

---

## Summary

> **Windows administration is a lifecycle problem,
> not a collection of tweaks.**

This structure exists to ensure responsibilities
remain explicit, bounded, and understandable over time.
