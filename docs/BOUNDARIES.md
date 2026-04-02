# BOUNDARIES.md

Boundary Summary  
boring-admin-windows

---

## Purpose

This document provides a compact summary of the **main operational boundaries**
used by the `boring-admin-windows` operating model.

It exists to make the repository easier to understand quickly.

This document is **supporting guidance**.
Normative meaning remains defined by higher-authority documents.

---

## Baseline vs overlay

### Baseline

Baseline is the minimum system surface
the repository treats as required for correct operation.

In `v002`, baseline is centered on:

- `20` security responsibility
- `40` identity role clarity
- `50` host identity
- `60` recovery / continuation visibility

Baseline is:

- explicit
- limited
- closed by design

### Overlay

Overlay is anything optional that increases:

- convenience
- hardening
- friction
- specialization
- resilience beyond baseline

In `v002`, overlays include:

- software delivery
- UX enhancement

Overlay is:

- optional
- removable
- consciously enabled

---

## Verify vs apply

### Verify

`verify` scripts:

- observe current state
- report findings
- do not remediate
- do not enforce

They are read-only by contract.

### Apply

`apply` scripts:

- change baseline state
- require explicit operator intent
- must not run implicitly

They are the point where human decision becomes action.

---

## Audit vs enforcement

Audit exists to:

- reconstruct reality
- surface uncertainty
- support human decisions

Audit does **not**:

- enforce
- remediate
- auto-continue

If a read-only surface starts acting,
it has stopped being audit.

---

## Recovery vs repair

This repository prefers:

- explicit recovery path
- reinstall-first thinking
- bounded continuation

It does not treat the current OS instance
as something that must always be preserved.

Recovery in `v002` means:

- visibility of minimum recovery signals
- clarity about when to stop

It does not mean automated restoration.

---

## State vs process

`v002` is process-driven.

It documents:

- how to inspect
- how to decide
- how to act explicitly

It does **not** contain an active desired-state model.

State-driven behavior is reserved for future `v003` work.

---

## Human vs automation

Humans remain the authority.

Automation is accepted only when it remains:

- explicit
- bounded
- reviewable

Hidden workflow, silent correction, and autonomous drift repair
are outside the intended model.

---

## Quick mental model

If you are unsure where something belongs:

- required and minimal -> baseline
- optional and removable -> overlay
- observe only -> verify / audit
- change state -> apply
- decide whether to continue -> recovery boundary

---

## See also

- [AUTHORITY.md](./AUTHORITY.md)
- [STRUCTURE.md](./STRUCTURE.md)
- [ARCHITECTURE-v002.md](./ARCHITECTURE-v002.md)
- [SCRIPT-CONTRACT.md](./SCRIPT-CONTRACT.md)
- [RECOVERY-PLAYBOOK.md](./RECOVERY-PLAYBOOK.md)
- [INCIDENT-CLASSIFICATION.md](./INCIDENT-CLASSIFICATION.md)
