# SCRIPT CONTRACT
## boring-admin-windows

This document defines **mandatory behavioral rules**
for all PowerShell scripts in this repository.

These rules are enforced by convention, code review,
and CI validation.

This project optimizes for:
- predictability
- safety
- auditability
- reinstall-over-repair workflows

This contract is normative.

---

## 1. RELATION TO STRUCTURE

This contract applies **within the lifecycle model**
defined in `docs/STRUCTURE.md`.

- Script names define lifecycle stage and responsibility
- This contract defines allowed behavior *within that scope*
- A script violating its declared lifecycle is a contract violation

---

## 2. SCRIPT MODES

Script intent is declared by filename.

### 2.1 SAFE SCRIPTS

Pattern:
```

NN-*.safe.ps1

```

Purpose:
- apply controlled system configuration
- modify system state in a predictable way

Requirements:
- MUST be idempotent
- MUST support `-WhatIf`
- MUST NOT reboot automatically
- MUST NOT require user interaction

---

### 2.2 VERIFY SCRIPTS

Pattern:
```

90-*.verify.ps1

```

Purpose:
- audit and report system state
- verify lifecycle assumptions

Requirements:
- MUST be read-only
- MUST NOT modify system state
- MUST NOT perform remediation
- MUST return ExitCode 0 unless a fatal error occurs

---

### 2.3 MANUAL SCRIPTS

Pattern:
```

NN-*.manual.ps1

```

Purpose:
- perform high-risk, identity or access-related actions
- require explicit human decision and interaction

Requirements:
- MUST require explicit user confirmation or input
- MUST NOT be executed automatically or in CI
- MUST NOT attempt silent or implicit changes

---

### 2.4 LIBRARY FILES

Pattern:
```

lib/*.ps1

````

Purpose:
- helper functions
- formatting and output helpers
- detection logic

Requirements:
- MUST have no side effects
- MUST NOT execute on import
- MUST NOT modify global state

---

## 3. EXIT CODES

All scripts MUST terminate with a meaningful exit code.

| Code | Meaning |
|-----:|--------|
| 0 | Success / compliant |
| 1 | Error / failure |
| 2 | Skipped / not applicable |

Scripts MUST NOT rely on text output to signal failure.

---

## 4. OUTPUT RULES

Allowed output channels:

| Channel | Usage |
|------|------|
| INFO | normal progress |
| WARN | non-fatal deviation |
| ERROR | fatal condition |

ERROR output MUST:
- be accompanied by ExitCode 1
- stop further execution

---

## 5. PRIVILEGES

Scripts MUST explicitly declare privilege expectations.

- Administrative rights MUST be checked explicitly
- No implicit elevation assumptions are allowed

Example:
```powershell
Assert-Administrator
````

---

## 6. IDEMPOTENCE

Idempotence is mandatory for SAFE scripts.

Running the same SAFE script:

* once → applies changes
* multiple times → no additional changes, no errors

This requirement does NOT apply to `.manual` scripts.

---

## 7. CI ENFORCEMENT

The following are enforced via CI:

* ScriptAnalyzer lint
* Header presence and lifecycle declaration
* Unit tests for `lib/*`
* Runtime dry-run execution for SAFE scripts
* Execution of VERIFY scripts only

MANUAL scripts MUST NOT be executed in CI.

Any violation is considered a regression.

---

## 8. NON-GOALS

This project intentionally does NOT provide:

* enterprise hardening baselines
* domain, Intune, or MDM policy engines
* security guarantees beyond documented behavior

---

## 9. CHANGE POLICY

Breaking this contract requires:

* explicit documentation update
* architectural commit
* justification in commit message

Silent contract changes are not allowed.
---