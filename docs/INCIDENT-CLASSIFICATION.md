# INCIDENT-CLASSIFICATION.md

Incident Classification  
boring-admin-windows

---

## Purpose

This document defines a compact **severity and response model**
for findings and incidents in `boring-admin-windows`.

It exists to help operators answer:

> How urgent is this, and what kind of response is appropriate?

This document is **operational guidance**.
It supports decisions.
It does not introduce automated enforcement or response logic.

---

## Core rule

Classification exists to improve operator judgment,
not to replace it.

Severity labels are used to:

- support triage
- reduce hesitation
- prevent continuation by habit
- clarify when normal operation should stop

They must not be used to justify hidden automation.

---

## Severity levels

### CRITICAL

Use `CRITICAL` when:

- workstation trust may be materially broken
- recovery path may be incomplete
- sensitive access may be lost or compromised
- continuation without explicit decision would be unsafe

Expected operator posture:

- stop normal continuation
- assess recovery path immediately
- isolate first if compromise is suspected
- prefer reinstall over prolonged repair

Target response window:

- immediate to same day

### WARNING

Use `WARNING` when:

- the system is still operable
- but recoverability, clarity, or role boundaries are degraded
- or drift may become operational risk if ignored

Expected operator posture:

- review deliberately
- schedule explicit corrective action
- confirm the issue does not belong in `CRITICAL`

Target response window:

- same day to a few days, depending on context

### INFORMATIONAL

Use `INFORMATIONAL` when:

- no immediate action is required
- the finding helps reconstruct reality
- the operator should remain aware of the condition

Expected operator posture:

- record it
- review it during normal audit or maintenance

Target response window:

- next normal audit or maintenance cycle

---

## Classification matrix

| Finding or condition | Severity | Default response posture | Primary reference |
|---|---|---|---|
| BitLocker recovery path unclear | CRITICAL | Stop and verify external escrow immediately | `RECOVERY-PLAYBOOK.md` |
| No trusted admin secret retrievable | CRITICAL | Stop, confirm external secret store, prepare rebuild if unresolved | `RECOVERY-PLAYBOOK.md`, `SECRETS-MANAGEMENT.md` |
| Malware or workstation trust collapse suspected | CRITICAL | Isolate, decide, reinstall bias | `RECOVERY-PLAYBOOK.md` |
| Hardware failure or serious disk corruption | CRITICAL | Preserve data only if safe, then replace / reinstall | `RECOVERY-PLAYBOOK.md` |
| Unexpected administrator account present | CRITICAL | Stop and investigate role boundary immediately | `IDENTITY.md`, `ANNUAL-MAINTENANCE.md` |
| Recovery administrator enabled unexpectedly | WARNING | Review intent and disable unless explicitly required | `RECOVERY-PLAYBOOK.md`, `IDENTITY.md` |
| BitLocker recovery protector not visible in verify output | WARNING | Confirm external escrow and operator access | `RECOVERY-PLAYBOOK.md` |
| OneDrive sync broken | WARNING | Restore confidence in external data protection | `RECOVERY-PLAYBOOK.md`, `OPERATING-MANUAL.md` |
| Temporary access account still present | WARNING | Confirm need or remove during explicit maintenance | `IDENTITY.md`, `ANNUAL-MAINTENANCE.md` |
| Software inventory contains unclear or suspicious items | WARNING | Review and remove through explicit operator action | `ANNUAL-MAINTENANCE.md` |
| Routine audit completed with no unresolved warnings | INFORMATIONAL | Record and continue normal operation | `ANNUAL-MAINTENANCE.md` |
| Operator summary contains advisory notes only | INFORMATIONAL | Review at next maintenance or handover | `COMMANDS.md` |

---

## Response model

### For CRITICAL

1. Stop normal continuation.
2. If compromise is suspected, isolate first.
3. Confirm whether the recovery path is intact.
4. Use read-only visibility surfaces where useful:
   - `.\boring-admin.ps1 audit all`
   - `.\boring-admin.ps1 verify recovery`
5. Prefer reinstall when trust or recoverability remains unclear.

### For WARNING

1. Review deliberately.
2. Decide whether the finding is really still below `CRITICAL`.
3. Schedule explicit operator action.
4. Re-run the relevant verify or audit surface after action.

### For INFORMATIONAL

1. Record the condition.
2. Keep it available for handover or annual review.
3. Avoid turning informational findings into ad-hoc changes.

---

## What severity does not mean

Severity does not create authority to:

- bypass review
- automate remediation
- keep operating a system that is no longer trusted
- reinterpret baseline boundaries

Severity supports decision-making.
It does not replace architecture.

---

## Practical rule of thumb

If you are unsure between `WARNING` and `CRITICAL`,
ask this question:

> Can the workstation still be trusted to continue normal operation
> without first clarifying recovery, identity, or host integrity?

If the honest answer is “no” or “unclear,”
treat the condition as `CRITICAL`.

---

## See also

- [RECOVERY-PLAYBOOK.md](./RECOVERY-PLAYBOOK.md)
- [ANNUAL-MAINTENANCE.md](./ANNUAL-MAINTENANCE.md)
- [BOUNDARIES.md](./BOUNDARIES.md)
- [SECRETS-MANAGEMENT.md](./SECRETS-MANAGEMENT.md)
- [IDENTITY.md](./IDENTITY.md)
