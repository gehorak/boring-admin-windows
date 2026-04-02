# ADMIN-ACCESS-GOVERNANCE.md

Administrative Access Governance  
boring-admin-windows

---

## Purpose

This document defines the minimum **administrative access governance model**
for `boring-admin-windows`.

It exists to answer:

- who is allowed to hold administrative access
- how that access is separated by role
- where administrative secrets must live
- when administrative access must be reviewed

This document is **operational governance guidance**.
It does not redefine identity architecture.
It consolidates current `v002` operating expectations into one place.

---

## Core rule

Administrative access is a **governed role**,
not a convenience feature.

In `v002`, this means:

- admin access is explicit
- admin access is limited
- admin access is externally recoverable
- admin access is not used for daily work

If administrative access cannot be clearly explained,
it is not governed well enough.

---

## Role model

### 1. Primary administrator

The primary administrator is the normal maintenance owner of the workstation.

Expected properties:

- exactly one primary local administrator
- used only for administration
- not used for daily personal work
- clearly assigned to a responsible operator

Purpose:

- ownership clarity
- accountability
- predictable support responsibility

### 2. Recovery / break-glass administrator

The recovery administrator exists only to preserve recoverability.

Expected properties:

- exactly one recovery administrator
- disabled by default
- enabled only by conscious operator action
- treated as insurance, not convenience

Purpose:

- preserve a deliberate recovery path
- reduce ambiguity when the primary admin path fails

### 3. Non-admin users

Daily user activity must not rely on administrative access.

Expected properties:

- normal work happens under non-admin identity
- admin credentials are not reused for convenience
- temporary access does not become implicit admin access

---

## Allowed administrative access holders

Administrative access should be limited to:

- the designated primary operator
- an explicitly recognized backup or recovery operator, where applicable

It should not be normalized for:

- casual helpers
- shared household use
- “everyone who might need it later”
- dormant convenience accounts

If multiple people need access,
that should be documented as an explicit governance choice,
not absorbed silently into the environment.

---

## Secret storage rule

Administrative secrets must exist outside the workstation itself.

At minimum, this includes:

- the primary admin secret
- the recovery / break-glass admin secret

Recommended current `v002` pattern:

- 1Password Business when already available in enterprise use
- another explicitly documented external secret store when approved

Administrative secrets must not be treated as:

- memory only
- workstation-local notes
- ad-hoc text files
- browser-saved credentials

Reference:
- [SECRETS-MANAGEMENT.md](./SECRETS-MANAGEMENT.md)

---

## Daily-use boundary

Administrative accounts must not be used for:

- daily browsing
- email
- general productivity work
- casual software experimentation

The expected pattern is:

- daily work -> user account
- maintenance and explicit changes -> admin role

This protects both:

- role clarity
- incident interpretation

---

## Retrieval governance

For every governed workstation, the operator should be able to answer:

- Where is the primary admin secret stored?
- Where is the recovery admin secret stored?
- Who may retrieve each secret?
- Under what circumstances should the recovery admin be used?
- Who is responsible for the workstation today?

If those answers are unclear,
administrative access governance is incomplete.

---

## Review expectations

Administrative access should be reviewed at least:

- during annual maintenance
- during workstation takeover
- after operator responsibility changes
- after any recovery incident involving admin credentials

The review should confirm:

- the primary admin still exists and is the intended owner role
- the recovery admin still exists and is disabled by default
- no unexpected admin members exist
- admin secrets still exist in the intended external store
- the responsible operator information is still current

Reference:
- [ANNUAL-MAINTENANCE.md](./ANNUAL-MAINTENANCE.md)

---

## Warning signs

Administrative governance should be treated as degraded when:

- more than the intended admin accounts exist
- the recovery admin is enabled without clear reason
- admin secrets are not externally retrievable
- ownership is unclear
- a workstation takeover reveals undocumented admin paths

When this happens, the correct response is:

- stop assuming the workstation is well-governed
- review identity and recovery material explicitly

Reference:
- [INCIDENT-CLASSIFICATION.md](./INCIDENT-CLASSIFICATION.md)
- [RECOVERY-PLAYBOOK.md](./RECOVERY-PLAYBOOK.md)

---

## What this model does not do

`v002` administrative access governance does **not** introduce:

- MFA enforcement for local admin access
- secret rotation automation
- directory-backed access governance
- continuous compliance monitoring
- unattended account remediation

Those concerns may exist elsewhere,
but they are outside current `v002` scope.

---

## Practical summary

In `v002`, good admin governance means:

- one clear primary admin
- one clear recovery admin
- no daily work under admin identity
- secrets stored externally
- ownership documented
- access reviewed on a deliberate schedule

If any of these are missing,
the workstation may still function,
but it is not governed to the intended operating standard.

---

## See also

- [IDENTITY.md](./IDENTITY.md)
- [SECRETS-MANAGEMENT.md](./SECRETS-MANAGEMENT.md)
- [RECOVERY-PLAYBOOK.md](./RECOVERY-PLAYBOOK.md)
- [ANNUAL-MAINTENANCE.md](./ANNUAL-MAINTENANCE.md)
- [INCIDENT-CLASSIFICATION.md](./INCIDENT-CLASSIFICATION.md)
