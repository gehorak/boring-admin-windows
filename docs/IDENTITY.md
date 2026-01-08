# IDENTITY.md
## Local Identity Architecture (Phase-1)

This document defines the **identity philosophy, scope, and mandatory models**
for the *boring-admin-windows* project.

Identity is treated as a **high-risk, high-impact domain**.
As such, it is intentionally **boring, explicit, and human-driven**.

This document is **normative** for Phase-1.


---

## 1. Identity Philosophy (Phase-1 Lock)

### 1.1 Identity is STATE, not OPERATIONS

This project does **not** provide generic user-management utilities.

Identity scripts do **not** exist to:
- create users ad-hoc
- delete users opportunistically
- “fix” identity automatically

Instead, identity scripts exist to:

> **establish, observe, and maintain a clearly defined identity STATE.**

Operations (create / enable / disable / remove) are only **means** to reach
an explicitly declared target state.

---

### 1.2 Identity is MANUAL by design

All identity-affecting scripts in Phase-1 are:

- **MANUAL**
- require explicit human confirmation
- must not be executed unattended
- must not run in CI

Rationale:
- identity mistakes are catastrophic
- automation without context is dangerous
- explicit intent beats convenience

This is a deliberate rejection of:
- “self-healing identity”
- scheduled identity enforcement
- unattended remediation

---

### 1.3 Identity favors visibility over enforcement

Phase-1 identity prioritizes:

- knowing **who exists**
- knowing **who has privileges**
- knowing **which accounts are dormant**

over:
- aggressively correcting drift
- automatically removing access
- enforcing timing or lifecycle policies

> **Visibility enables correct decisions.
> Automation without visibility creates false safety.**

---

### 1.4 What Identity Explicitly Does NOT Do (Phase-1)

The following are **out of scope by design**:

- password rotation automation
- account expiration enforcement
- identity drift remediation
- lockout or authentication policy management
- cloud / Microsoft account management
- AD / MDM emulation

These may be *considered* in later phases, but **not before Phase-1 is complete**.

---

## 2. Phase-1 Identity Models (MUST HAVE)

Phase-1 defines exactly **four mandatory identity models**.
Each model answers a specific operational question.

No model is optional.
No model may be merged with another.

---

### 2.1 Administrator Ownership Model

**Question answered:**
> Who owns this system?

**Definition:**
- exactly **one primary local administrator**
- account is **enabled**
- account is used **only for administration**
- no daily work under administrative identity

**Purpose:**
- clear ownership
- clear accountability
- no shared responsibility

This model prevents:
- “everyone is admin”
- ambiguous system ownership

---

### 2.2 Break-Glass / Recovery Model

**Question answered:**
> How is the system recovered if the primary admin fails?

**Definition:**
- exactly **one recovery administrator**
- account **exists**
- account is **disabled by default**
- activation is a conscious, manual act

**Purpose:**
- guaranteed recovery path
- minimal attack surface
- predictable emergency behavior

Recovery accounts are **not convenience accounts**.
They are insurance.

---

### 2.3 Temporary Access Model

**Question answered:**
> How is short-term access granted without long-term risk?

**Definition:**
- temporary access is treated as a **state**
- implemented via a local **standard user**
- no administrative privileges
- existence is **explicit and visible**
- removal restores the system to a known-safe state

**Purpose:**
- visitor access
- short-term troubleshooting
- workstation sharing

Temporary access must never become permanent by accident.

---

### 2.4 Visibility / Audit Model

**Question answered:**
> How do we know the current identity state?

**Definition:**
- read-only visibility
- no enforcement
- no modification
- safe to run at any time

Provides answers to:
- which local users exist
- which accounts are administrators
- which managed accounts are present and enabled

**Purpose:**
- prevent privilege creep
- enable informed manual action
- support audits and reviews

---

## 3. Mapping to Phase-1 Scripts

Each identity model is implemented by **exactly one script role**.

| Script | Role |
|------|------|
| `40-identity-local-orchestrator.manual` | Human entry point, model overview |
| `41-identity-local-admin-model.manual` | Administrator Ownership + Recovery |
| `45-identity-local-temporary-access.manual` | Temporary Access |
| `46-identity-local-visibility.verify` | Visibility / Audit |

Scripts must **not** overlap responsibilities.

---

## 4. Reserved Models (NOT Phase-1)

The following models are **intentionally reserved** for future phases:

- Identity Drift Awareness (detect only)
- Ownership Transfer / Decommission
- Credential Lifecycle Management

They are acknowledged but **explicitly excluded** from Phase-1.

---

## 5. Article / Knowledge-Sharing Notes (Non-Normative)

This identity design can be summarized externally as:

> “Boring identity management favors explicit human intent,
> minimal automation, and predictable recovery over clever scripts.”

Key talking points for an article or presentation:

- Why CRUD identity scripts are an anti-pattern
- Why MANUAL is safer than ‘smart automation’
- Identity as a state machine, not a task list
- Recovery accounts as insurance, not convenience
- Visibility as the foundation of security

This section is **informational only** and does not affect repository behavior.

---

## 6. Phase-1 Lock Statement

This document **locks the identity architecture for Phase-1**.

Any change that:
- adds new identity models
- introduces automated enforcement
- changes MANUAL assumptions

**requires a new phase and explicit review.**

Phase-1 identity is considered **complete and stable** once all referenced scripts
conform to this document.
