# SECRETS-MANAGEMENT.md

Secrets and Recovery Key Management  
boring-admin-windows

---

## Purpose

This document defines the minimum **secret-storage and recovery-key coordination model**
for `boring-admin-windows`.

It exists to answer three practical questions:

- where administrator credentials must be stored
- where BitLocker recovery keys must be escrowed
- how these two responsibilities are coordinated without hidden automation

This document is **operational guidance with domain-specific constraints**.
It does not redefine architecture, but it does narrow acceptable operating practice.

---

## Core rule

Critical access material must exist **outside the device itself**.

At minimum, this includes:

- administrator credentials
- BitLocker recovery keys

If either exists only on the workstation,
the recovery model is incomplete.

---

## Classification

### 1. Administrator secrets

Administrator secrets include:

- primary local administrator password
- recovery / break-glass administrator password
- any equivalent high-privilege secret required to regain control of the workstation

These secrets must be stored in a controlled external system.

They must not be treated as:

- user memory only
- ad-hoc notes
- workstation-local documentation
- browser-saved credentials

### 2. Recovery material

Recovery material includes:

- BitLocker recovery keys
- the documented recovery path
- the current responsible operator / owner reference

Recovery material must be externally retrievable
without relying on the running workstation instance.

---

## Recommended storage model by environment

### Enterprise / managed professional environment

If the organization already uses **1Password Business**,
store administrator secrets there.

Recommended usage:

- one vault or equivalent controlled location for workstation admin secrets
- access restricted to the responsible administrator(s)
- no casual sharing of high-privilege secrets
- recovery admin secret stored with the same discipline as the primary admin secret

This repository does not mandate 1Password Business as a universal product.
It is the preferred recommendation when that environment already exists.

### SMB / small standalone environment

For small environments using Microsoft account / Entra-backed Windows devices,
the preferred default escrow target for BitLocker recovery is:

- **Azure Entra ID escrow**

Recommended usage:

- confirm the device actually writes BitLocker recovery material to Entra ID
- confirm the responsible operator knows how to retrieve it
- treat Entra escrow as the default external BitLocker recovery location

If Entra escrow is unavailable,
an equivalent external escrow path must be documented explicitly.

---

## Coordination model

The system is considered operationally recoverable only when
all of the following are true:

1. a primary local administrator secret exists externally
2. a recovery / break-glass administrator secret exists externally
3. BitLocker recovery keys are escrowed externally
4. the responsible operator knows where each item is stored
5. the storage locations are documented outside the device

This repository intentionally does not automate secret lifecycle management in `v002`.

Coordination is therefore:

- explicit
- human-managed
- documented
- reviewed during maintenance

---

## Minimum documented answers

For each managed workstation,
the operator should be able to answer these questions immediately:

- Where is the primary admin password stored?
- Where is the recovery / break-glass admin password stored?
- Where is the BitLocker recovery key escrowed?
- Who can retrieve each of those items?
- What is the recovery path if the workstation is unavailable?

If any answer is missing,
the workstation is not fully operationally recoverable.

---

## What v002 does not do

`v002` does not introduce:

- secret rotation automation
- password vault automation
- BitLocker escrow enforcement automation
- desired-state secret management
- secret distribution workflows

Those concerns may be expanded in later versions,
but they are outside current `v002` scope.

---

## Maintenance expectations

At minimum, annual maintenance should confirm:

- administrator secrets still exist in the intended external store
- BitLocker recovery keys remain escrowed externally
- the documented owner / operator reference is current
- recovery instructions are still understandable by a non-original operator

This is a documentation and recoverability check,
not a license to expose the secrets during routine maintenance.

---

## Quick default policy

If no stronger organization-specific rule exists,
use this default:

- admin secrets -> 1Password Business when available in enterprise use
- BitLocker recovery -> Azure Entra ID escrow by default in SMB / Microsoft-backed environments
- all locations documented externally and reviewed during maintenance

---

## See also

- [ADMIN-ACCESS-GOVERNANCE.md](./ADMIN-ACCESS-GOVERNANCE.md)
- [IDENTITY.md](./IDENTITY.md)
- [OPERATING-MANUAL.md](./OPERATING-MANUAL.md)
- [ANNUAL-MAINTENANCE.md](./ANNUAL-MAINTENANCE.md)
- [BOUNDARIES.md](./BOUNDARIES.md)
