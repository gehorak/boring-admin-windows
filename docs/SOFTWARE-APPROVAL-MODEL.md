# SOFTWARE-APPROVAL-MODEL.md

Software Approval Model  
boring-admin-windows

---

## Purpose

This document defines a lightweight **approval and review model**
for optional software work in `boring-admin-windows`.

It exists to answer:

- how optional software requests should be reviewed
- how approval should be recorded
- how approved software can be correlated with visible installed software later

This document is **operational governance guidance**.
It does not redefine software as baseline.
It does not introduce an enforcement engine.

---

## Core rule

Software in `v002` remains an **overlay concern**.

That means:

- software is optional
- software decisions are explicit
- software may be reviewed and approved
- approval does not turn overlay into baseline

The approval model exists to improve operator clarity,
not to create hidden compliance automation.

---

## What this model covers

This model covers:

- optional software requests
- explicit administrator review
- lightweight approval records
- annual review support
- correlation with software inventory visibility

This model does **not** cover:

- automatic installation approval
- background software enforcement
- mandatory package allowlists enforced by code
- baseline expansion
- role-driven software policy engines

---

## Relationship to the software lifecycle

Current software surface in `v002` is split into:

- transport
- software baseline packages
- UX software packages
- read-only inventory visibility

Those surfaces remain unchanged.

This approval model sits **around** the software overlay process.
It does not replace:

- `.\boring-admin.ps1 overlay software`
- `39-software-inventory.verify.ps1`
- the existing software orchestrator

Reference:
- [SOFTWARE.md](./SOFTWARE.md)
- [BOUNDARIES.md](./BOUNDARIES.md)

---

## Minimal workflow

### 1. Request

A user or operator identifies desired software.

The request should capture:

- software name
- intended use
- why the software is needed
- whether it is expected to be broadly useful or purely situational

This can be recorded in any explicit human-managed channel,
for example:

- ticket
- email
- maintenance log
- shared admin notes

`v002` does not require a single tool.

### 2. Review

The administrator reviews:

- whether the software is really needed
- whether it belongs in overlay rather than baseline
- whether it introduces obvious operational risk
- whether the package source is understandable

If the software is unclear,
the default answer should be:

- defer
- reject
- or request more context

### 3. Approval

If approved, record a lightweight approval entry.

The record should include at minimum:

- approval identifier
- requested software name
- requestor
- approver
- approval date
- short reason

### 4. Installation

Installation remains an explicit operator action through the existing overlay surface.

Examples:

```text
.\boring-admin.ps1 overlay software
```

The approval record may be referenced manually during the install decision,
but the repository does not automate that linkage in `v002`.

### 5. Review and correlation

During annual maintenance or workstation takeover:

- review software inventory visibility
- compare visible installed software with known approval records
- investigate software with unclear origin or unclear purpose

Useful visibility command:

```text
.\boring-admin.ps1 verify software
```

---

## Lightweight approval record

The recommended approval record is intentionally simple.

Example:

```json
{
  "id": "SW-2026-0401-001",
  "software": "VLC media player",
  "requestedBy": "user@example.com",
  "approvedBy": "admin@example.com",
  "approvedAt": "2026-04-01",
  "reason": "Playback of training and support materials",
  "notes": "Install through existing software overlay surface"
}
```

This is a record format example,
not a mandatory repository-managed database schema.

---

## Overlay reality rules

### Baseline software is not governed by the same intent

The software lifecycle already contains a minimal baseline package layer.

This approval model is primarily for:

- optional software
- situational software
- user-requested software
- UX-oriented additions

It should not be used to reinterpret the baseline package layer
as a ticket-driven policy surface.

### Approval is not enforcement

An approval record means:

- a human decided the software was acceptable at that time

It does not mean:

- the system will enforce that decision automatically
- the repository will continuously block everything else
- software drift has been solved as a state problem

---

## Annual review support

During annual maintenance, the operator should be able to answer:

- What optional software is visible on this workstation?
- Which of it has a clear purpose?
- Which of it has a clear approval path?
- Which of it should be removed?

This is enough to support a lightweight governance model in `v002`.

Reference:
- [ANNUAL-MAINTENANCE.md](./ANNUAL-MAINTENANCE.md)

---

## Recommended operator questions

Before approving optional software, ask:

- Is this software genuinely needed?
- Is the package source understandable and supportable?
- Does it belong in overlay rather than baseline?
- Would removing it later be straightforward?
- Would the workstation still be fine without it?

If the answer to the last question is “no,”
reconsider whether the request is actually trying to expand baseline.

---

## What this model does not authorize

This model does not authorize:

- automatic package approval
- scheduled software reconciliation
- hidden software drift remediation
- background package installation
- reinterpretation of overlay software as required baseline state

---

## See also

- [SOFTWARE.md](./SOFTWARE.md)
- [BOUNDARIES.md](./BOUNDARIES.md)
- [COMMANDS.md](./COMMANDS.md)
- [ANNUAL-MAINTENANCE.md](./ANNUAL-MAINTENANCE.md)
