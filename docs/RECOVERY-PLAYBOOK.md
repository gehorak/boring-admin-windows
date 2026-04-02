# RECOVERY-PLAYBOOK.md

Recovery Playbook  
boring-admin-windows

---

## Purpose

This document provides a compact **operator playbook**
for common recovery-oriented situations in `boring-admin-windows`.

It exists to answer a practical question:

> What should the operator do when recovery visibility or workstation trust breaks down?

This document is **operational guidance**.
It does not redefine architecture.
It does not introduce automated recovery behavior.

---

## Recovery philosophy

`v002` recovery remains intentionally limited.

The repository provides:

- recovery visibility
- recovery path clarity
- explicit stop conditions

It does not provide:

- automated restoration
- hidden repair logic
- unattended incident response

The default bias remains:

> **When uncertainty grows, stop first.  
> Reinstall is preferred over fragile repair.**

---

## How to use this playbook

Use this document when:

- `.\boring-admin.ps1 verify recovery` reports warnings
- annual maintenance reveals recovery gaps
- the workstation cannot be trusted to continue normally
- a technician is taking over an unknown or degraded machine

Start with a read-only view:

```text
.\boring-admin.ps1 verify recovery
```

Optional full audit:

```text
.\boring-admin.ps1 audit all
```

Then choose the closest scenario below.

---

## Scenario 1: BitLocker recovery required

### Typical signals

- Windows requests a BitLocker recovery key at boot
- `verify recovery` reports no visible recovery protector
- operator is unsure where the recovery key is escrowed

### Immediate goal

- determine whether the key exists externally
- avoid repeated guesswork or ad-hoc changes

### Operator steps

1. Stop normal troubleshooting on the workstation itself.
2. Confirm the expected external escrow path.
3. Check the documented recovery location:
   - Azure Entra ID escrow in Microsoft-backed SMB environments
   - other explicitly documented escrow path if used instead
4. Confirm the responsible operator has retrieval access.
5. If the key is found, use it only to regain access and then reassess system trust.
6. If the key is not found quickly, treat this as a recovery-path failure, not a normal inconvenience.

### When to stop and reinstall

Reinstall is preferred when:

- the recovery key cannot be found
- the escrow path is unclear
- the device has multiple trust signals failing at once
- storage health or OS integrity is already questionable

### What not to do

- do not disable BitLocker in panic
- do not improvise undocumented escrow workarounds
- do not assume continued use is safe just because the OS becomes accessible again

---

## Scenario 2: Lost administrator secret

### Typical signals

- the primary admin password is unavailable
- the recovery / break-glass admin secret is unavailable
- no responsible operator can retrieve the documented admin secret store

### Immediate goal

- determine whether external secret storage still works as designed

### Operator steps

1. Confirm whether the primary admin secret exists in the documented external store.
2. Confirm whether the recovery / break-glass admin secret exists in the documented external store.
3. Check the current secret-storage record:
   - 1Password Business where used
   - other explicitly documented external secret store if approved
4. If one valid admin secret is recoverable, regain access and review the overall recovery posture.
5. If no valid secret is recoverable, stop treating the workstation as operationally recoverable.

### When to stop and rebuild

Reinstall or replacement should be preferred when:

- no trusted admin secret can be retrieved
- the only remaining path would require improvised local bypass techniques
- the operator cannot establish a trustworthy chain of control

### What not to do

- do not add emergency undocumented passwords
- do not store recovered admin secrets locally “for convenience”
- do not normalize ad-hoc password reset procedures as routine practice

Reference:
- [SECRETS-MANAGEMENT.md](./SECRETS-MANAGEMENT.md)

---

## Scenario 3: OneDrive sync broken

### Typical signals

- OneDrive is signed out
- sync is stalled or repeatedly failing
- expected user data is no longer confidently protected outside the device

### Immediate goal

- decide whether this is a local sync issue or a recovery-path issue

### Operator steps

1. Confirm whether the user is signed in to OneDrive.
2. Confirm whether the expected known folders are still synchronized.
3. Confirm whether sync health returns after a normal client restart or re-authentication.
4. If sync health is restored, document the interruption and continue with caution.
5. If sync health is not restored, treat the workstation as having degraded recoverability.

### When it becomes a recovery issue

Escalate from routine maintenance to recovery concern when:

- critical user data is only local
- sync has been broken long enough that data protection is uncertain
- the workstation may soon need reinstall or replacement

### Preferred bias

- restore confidence in external data protection first
- do not assume the device is the source of truth for important user data

---

## Scenario 4: Hardware failure or disk corruption

### Typical signals

- SMART warnings
- repeated storage errors
- boot instability
- filesystem corruption
- BitLocker or OS access combined with disk-health uncertainty

### Immediate goal

- stop treating the current OS instance as durable

### Operator steps

1. Confirm whether the device is still stable enough for controlled data access.
2. Confirm whether user data is already synchronized externally.
3. Confirm whether BitLocker recovery information is available if needed.
4. Decide quickly whether the device should be preserved only long enough to recover remaining data.
5. Prefer replacement and reinstall over extended repair attempts.

### Preferred outcome

- replace failing hardware
- reinstall Windows
- reapply baseline
- restore user data through the documented recovery path

### What not to do

- do not treat a failing disk as something to “nurse along”
- do not build operational dependence on a suspect workstation

---

## Scenario 5: Malware or workstation trust collapse

### Typical signals

- file encryption or ransomware indicators
- suspicious processes or persistence
- unexpected privilege changes
- widespread unexplained warnings across multiple audit domains

### Immediate goal

- preserve decision clarity and prevent continuation by habit

### Operator steps

1. Isolate the workstation from the network if active compromise is suspected.
2. Stop normal use immediately.
3. Run only bounded read-only checks if safe and useful:
   - `.\boring-admin.ps1 audit all`
   - `.\boring-admin.ps1 verify recovery`
4. Decide whether the remaining information changes the recovery decision.
5. Prefer reinstall once workstation trust is materially degraded.

### Reinstall bias

For malware scenarios, the preferred bias is:

- isolate
- decide
- reinstall

Not:

- continue operating while “investigating later”

### What not to do

- do not trust the workstation because a scan returns clean once
- do not keep operating a system whose trust boundary has collapsed
- do not introduce emergency hardening changes outside documented design

---

## Scenario 6: Operator takeover of an unknown workstation

### Typical signals

- new admin inherits an existing machine
- documentation is partial
- recovery path is not obvious
- workstation may still appear “fine” in daily use

### Immediate goal

- determine whether the workstation is actually recoverable and governable

### Operator steps

1. Run:

```text
.\boring-admin.ps1 audit all
.\boring-admin.ps1 verify recovery
```

2. Review:
   - admin account model
   - recovery admin visibility
   - BitLocker recovery visibility
   - external secret and escrow documentation
3. Compare findings with:
   - [ANNUAL-MAINTENANCE.md](./ANNUAL-MAINTENANCE.md)
   - [SECRETS-MANAGEMENT.md](./SECRETS-MANAGEMENT.md)
4. If the recovery path is incomplete, document that explicitly before accepting the workstation as supportable.

### When to reject continuation

Do not accept the workstation as healthy-by-default when:

- recovery material is unclear
- admin ownership is unclear
- data protection is unclear
- hardware trust is questionable

---

## Recovery decision checklist

Before continuing normal operation, the operator should be able to answer:

- Is the recovery path externally documented?
- Are admin secrets externally retrievable?
- Are BitLocker recovery keys externally escrowed?
- Is user data externally recoverable?
- Is the current workstation still trustworthy enough to continue?

If the answer to any of these is “no” or “unclear,”
continuation should be treated as a conscious risk decision,
not a default.

---

## What this playbook does not authorize

This playbook does not authorize:

- silent remediation
- hidden automation
- scheduled response actions
- automatic continuation
- architectural reinterpretation of `v002`

It is guidance for humans,
not a recovery engine.

---

## See also

- [ARCHITECTURE-v002.md](./ARCHITECTURE-v002.md)
- [BOUNDARIES.md](./BOUNDARIES.md)
- [SECRETS-MANAGEMENT.md](./SECRETS-MANAGEMENT.md)
- [ADMIN-ACCESS-GOVERNANCE.md](./ADMIN-ACCESS-GOVERNANCE.md)
- [RECOVERY-MATERIAL-CHECKLIST.md](./RECOVERY-MATERIAL-CHECKLIST.md)
- [ANNUAL-MAINTENANCE.md](./ANNUAL-MAINTENANCE.md)
- [OPERATING-MANUAL.md](./OPERATING-MANUAL.md)
