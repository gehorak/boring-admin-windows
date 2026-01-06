# ANNUAL-MAINTENANCE.md

Annual Maintenance Checklist  
Windows Workstation — No Domain Environment

---

## Purpose

This document defines the **minimum annual maintenance**
required to keep a Windows workstation:

- secure
- predictable
- recoverable

It is intentionally designed to:

- require **30–45 minutes once per year**
- be executed by a technician or informed administrator
- detect silent configuration drift before it becomes operational risk

> If this checklist causes stress,
> the system design is already failing.

---

## When to perform maintenance

Perform this checklist:

- once per year (recommended baseline)
- after a major Windows feature update
- when taking over responsibility for an existing workstation

No other periodic maintenance is required.

---

## Preparation

Before starting:

- sign in as a **local administrator**
- ensure the system has an active internet connection
- ensure no critical user activity is in progress

Maintenance is performed on a live system.
No downtime is expected beyond standard reboots.

---

## Maintenance checklist

### 1. System audit (read-only)

☐ Execute the audit command:

```text
make audit
````

☐ Review all reported warnings
☐ Confirm no unexpected administrator accounts exist
☐ Confirm no temporary host account remains active

**Expected result:**

* No unresolved warnings
* System state matches documented design intent

Audit output is informational.
Do not modify system state during this step.

---

### 2. Windows Update health

☐ Open *Settings → Windows Update*
☐ Confirm the system is fully up to date
☐ Confirm no recurring update failures are present

**If issues are detected:**

* allow updates to complete
* reboot as required
* recheck status after reboot

---

### 3. BitLocker verification

☐ Verify BitLocker is enabled on all internal drives
☐ Confirm recovery keys exist and are stored outside the device

**Expected result:**

* `ProtectionStatus = Enabled` on all system drives

BitLocker is mandatory for recoverability.

---

### 4. Security baseline sanity check

☐ Confirm Microsoft Defender is enabled
☐ Confirm real-time protection is active
☐ Confirm Windows Firewall is enabled for all profiles

**If deviation is detected:**

* investigate manually
* do not apply aggressive or undocumented hardening

Security here prioritizes predictability over restriction.

---

### 5. Account model review

☐ Confirm the primary local administrator account exists and is enabled
☐ Confirm the recovery administrator account exists and is disabled
☐ Confirm regular users are not members of the Administrators group

**Expected result:**

* No privilege creep
* Clear separation of roles

Account structure is a primary security control.

---

### 6. Temporary host account check

☐ Verify no temporary host account exists

**If present:**

* confirm it is still required
* otherwise remove it immediately

Temporary access must remain temporary.

---

### 7. OneDrive and data health

☐ Confirm the user is signed in to OneDrive
☐ Confirm synchronization status is healthy
☐ Confirm key user folders are actively synced

**Expected result:**

* User data is protected independently of the device

Data recoverability is assumed, not optional.

---

### 8. Software inventory sanity

☐ Review installed applications
☐ Remove unused or suspicious software
☐ Confirm no system optimizers or rogue security tools are present

**Rule:**

* if software origin or purpose is unclear, remove it

This environment favors clarity over accumulation.

---

### 9. Hardware and storage health

☐ Check available disk space on the system drive
☐ Confirm no SMART or storage-related warnings
☐ Verify backups are not impacted by disk issues

Hardware issues are handled operationally, not scriptically.

---

## What not to do during maintenance

Do not:

* install third-party debloat scripts
* disable Windows services
* apply registry hardening guides
* replace Microsoft Defender with third-party antivirus
* attempt in-place system repair unless strictly necessary

Maintenance is not a tuning exercise.

---

## Maintenance outcome

After completing this checklist, the system should:

* require no immediate corrective action
* remain boring and predictable
* be ready for another year of operation

If significant issues are discovered:

> **Reinstall is preferred over repair.**

Recovery is part of the operating model.

---

## Record keeping (recommended)

☐ Record maintenance date
☐ Record technician or administrator name
☐ Document any deviations or corrective actions

This information supports future handover.

---

## Final note

This checklist is intentionally minimal.

> A system that requires constant tuning
> is already failing operationally.