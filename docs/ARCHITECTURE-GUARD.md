# ARCHITECTURE-GUARD.md

Architecture Guard  
boring-admin-windows

---

## Purpose

This document defines **non-negotiable architectural rules**
for the boring-admin-windows project.

Its purpose is to:

- protect the operating model from erosion over time
- prevent accidental overengineering
- provide a clear rejection basis for inappropriate changes
- ensure long-term consistency and predictability

These rules take precedence over convenience.

---

## Guarded principles

The following principles are considered **architectural invariants**.

They must not be violated without an explicit redesign
and documentation update.

---

## 1. Documentation-first architecture

- Documentation defines the system.
- Implementation follows documentation.
- Scripts must not redefine behavior that is not documented.

If documentation and implementation diverge,
**documentation is authoritative**.

---

## 2. Explicit execution model

- No script executes automatically.
- No implicit execution order is allowed.
- All actions must be invoked explicitly by a human operator.

Automation that hides intent is forbidden.

---

## 3. Single-responsibility scripts

- Each script has exactly one declared responsibility.
- Scripts must not cross lifecycle domains.
- Side effects outside declared scope are violations.

If a script grows beyond its scope,
it must be split.

---

## 4. Baseline vs overlay separation

- Baseline defines the minimum required system state.
- Overlays are optional and role-specific.
- Baseline must never depend on overlays.

Overlays may be removed without breaking the baseline.

---

## 5. Read-only audit invariant

- Audit operations must not modify system state.
- Audit scripts must be safe to run repeatedly.
- Any corrective action must be explicit and separate.

Audit is observation, not enforcement.

---

## 6. Recovery-first bias

- Reinstall is preferred over repair.
- Scripts must support idempotent reapplication.
- No design decision may assume a system will never be reinstalled.

Fragile, state-dependent fixes are not acceptable.

---

## 7. No hidden hardening

- No undocumented registry changes.
- No service disabling without explicit documentation.
- No security tweaks that depend on obscurity.

Security must be understandable and reviewable.

---

## 8. OS as a consumable component

- The operating system is treated as disposable.
- Data and identity must survive OS loss.
- No design may bind critical state exclusively to the OS.

Loss of the OS must be recoverable by design.

---

## 9. Human-first operation

- The system is operated by humans, not pipelines.
- Readability is preferred over cleverness.
- Debuggability is preferred over compactness.

If a technician cannot understand a script,
it is incorrect.

---

## 10. Scope boundary enforcement

The following are explicitly out of scope:

- centralized enforcement mechanisms
- domain or MDM behavior emulation
- continuous compliance monitoring
- background agents or daemons

Attempts to introduce these are architectural violations.

---

## Violation handling

If a proposed change violates any rule in this document:

- the change must be rejected, or
- the architecture must be explicitly revised and documented

Silent exceptions are not permitted.

---

## Final statement

> **Boring systems remain operable because they resist cleverness.**

This guard exists to keep the system boring,
predictable, and recoverable over time.
