# COMMON-SCENARIOS.md

Common Scenarios  
boring-admin-windows

---

## Purpose

This document provides short **operator walkthroughs**
for common day-to-day situations in `boring-admin-windows`.

It is intended to answer:

> I know roughly what I need to do. What is the shortest safe path?

This document is **operational guidance**.
It does not introduce new commands or new product behavior.

---

## Scenario 1: I inherited an existing workstation

### Goal

Get a read-only picture of the workstation before changing anything.

### Recommended path

```text
.\boring-admin.ps1 help
.\boring-admin.ps1 info
.\boring-admin.ps1 audit all
.\boring-admin.ps1 audit summary
```

### What to review

- warnings across audit scopes
- unexpected administrator accounts
- recovery visibility
- software inventory visibility

### References

- [GETTING-STARTED.md](./GETTING-STARTED.md)
- [ANNUAL-MAINTENANCE.md](./ANNUAL-MAINTENANCE.md)

---

## Scenario 2: I need a human-readable audit record

### Goal

Save a readable audit snapshot for handover, maintenance, or incident notes.

### Recommended path

```text
.\boring-admin.ps1 audit save
```

### Result

- a text audit snapshot is written outside the repository
- the repository itself is not used as the audit archive location

### Related command

If you only need a short screen summary:

```text
.\boring-admin.ps1 audit summary
```

### References

- [COMMANDS.md](./COMMANDS.md)
- [AUDIT-EXPORT-FORMAT.md](./AUDIT-EXPORT-FORMAT.md)

---

## Scenario 3: I need machine-readable audit output

### Goal

Get the current aggregate audit in JSON form.

### Recommended path

```text
.\boring-admin.ps1 audit export
```

### Use this when

- you want a machine-readable snapshot
- you want to parse or post-process audit output
- you need a structured export for external review

### Important note

The export describes current `v002` visibility.
It is not a compliance proof or escrow proof.

### References

- [AUDIT-EXPORT-FORMAT.md](./AUDIT-EXPORT-FORMAT.md)
- [COMMANDS.md](./COMMANDS.md)

---

## Scenario 4: I want to review recovery readiness

### Goal

Confirm that the workstation still has a visible recovery path.

### Recommended path

```text
.\boring-admin.ps1 verify recovery
```

Optional wider context:

```text
.\boring-admin.ps1 audit recovery
```

### Then review

- external secret storage
- BitLocker escrow path
- reinstall acceptability
- data recovery path

### References

- [RECOVERY-PLAYBOOK.md](./RECOVERY-PLAYBOOK.md)
- [SECRETS-MANAGEMENT.md](./SECRETS-MANAGEMENT.md)
- [INCIDENT-CLASSIFICATION.md](./INCIDENT-CLASSIFICATION.md)

---

## Scenario 5: I want to do annual maintenance

### Goal

Perform the shortest supported yearly review path.

### Recommended path

```text
.\boring-admin.ps1 audit all
.\boring-admin.ps1 verify software
.\boring-admin.ps1 verify recovery
```

### Review focus

- unresolved warnings
- software drift and clarity
- recovery path visibility
- account and role clarity

### Reference

- [ANNUAL-MAINTENANCE.md](./ANNUAL-MAINTENANCE.md)

---

## Scenario 6: I want to install optional software

### Goal

Review optional software visibility first,
then use the existing overlay surface explicitly.

### Recommended path

Read-only first:

```text
.\boring-admin.ps1 verify software
```

If proceeding with overlay work:

```text
.\boring-admin.ps1 overlay software
```

### Review questions

- is the software really optional overlay, not baseline?
- is there a clear approval path if one is expected?
- would removing it later be straightforward?

### References

- [SOFTWARE.md](./SOFTWARE.md)
- [SOFTWARE-APPROVAL-MODEL.md](./SOFTWARE-APPROVAL-MODEL.md)

---

## Scenario 7: I am setting up a new workstation

### Goal

Follow the established first-setup path without inventing shortcuts.

### Recommended start

```text
.\boring-admin.ps1 setup
```

### Expand with

- [FIRST-WORKSTATION-SETUP.md](./FIRST-WORKSTATION-SETUP.md)

### Rule

- do not jump directly to overlays
- do not skip verify steps
- do not normalize “it probably works” as completion

---

## Scenario 8: I only need the shortest safe starting point

### Goal

Avoid guessing.

### Recommended path

```text
.\boring-admin.ps1 help
.\boring-admin.ps1 info
```

Then choose:

- [GETTING-STARTED.md](./GETTING-STARTED.md) for operator path selection
- [COMMANDS.md](./COMMANDS.md) for command reference
- [BOUNDARIES.md](./BOUNDARIES.md) for the mental model

---

## What this document deliberately does not do

This document does not describe:

- `apply all`
- `bootstrap` as a top-level public entry command
- `recovery status`
- `apply identity add-user`
- `apply software request`

If a command is not part of the current documented entry surface,
it is intentionally absent here.

---

## See also

- [GETTING-STARTED.md](./GETTING-STARTED.md)
- [COMMANDS.md](./COMMANDS.md)
- [FIRST-WORKSTATION-SETUP.md](./FIRST-WORKSTATION-SETUP.md)
- [RECOVERY-PLAYBOOK.md](./RECOVERY-PLAYBOOK.md)
- [SOFTWARE-APPROVAL-MODEL.md](./SOFTWARE-APPROVAL-MODEL.md)
