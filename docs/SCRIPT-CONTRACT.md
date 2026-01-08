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

9N-*.verify.ps1

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
- MUST be strictly read-only
- MUST NOT modify system state
- MUST NOT perform remediation
- MUST NOT rely on silent failures
- MUST produce a deterministic summary

Exit behavior:
- Exit 0 → verification successful, no deviations
- Exit 2 → verification completed with warnings
- Exit 1 → fatal error (cannot complete verification)

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
- MUST have no side effects on import
- MUST NOT execute code on load
- MUST NOT modify global or script state
- MUST NOT make policy decisions
- MUST be safe for dot-sourcing

Library helpers may:
- emit formatted output only when explicitly called
- terminate execution only via documented helpers (e.g. Exit-Fatal)


---

## 3. EXIT CODES

All scripts MUST terminate with a meaningful exit code.

| Code | Meaning |
|-----:|--------|
| 0 | Success / compliant |
| 1 | Error / failure |
| 2 | Completed with warnings |

Scripts MUST NOT rely on text output alone to signal failure.
WARN conditions MUST be reflected in exit code where applicable.
VERIFY scripts MUST use Exit 2 for non-fatal deviations.

---

## 4. OUTPUT RULES

Scripts MUST use the unified runtime output vocabulary.

Allowed output prefixes:

 | Prefix | Meaning |
 | [INFO] | normal progress |
 | [OK]   | successful completion |
 | [WARN] | non-fatal deviation |
 | [FAIL] | fatal condition |
 | [SKIP] | intentional non-action |

Fatal conditions MUST:
- emit [FAIL]
- terminate execution (Exit 1)

Scripts MUST NOT:
- use Write-Error
- use Write-Warning
- invent custom prefixes

All output formatting MUST go through helpers in lib/common.ps1.

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

## 7. ERROR HANDLING

Silent failure is forbidden.

Rules:
- -ErrorAction SilentlyContinue MUST NOT be used without explicit handling
- All catch blocks MUST emit output or explicitly document ignored errors
- Guarded queries MUST return $null instead of blocking

Fatal errors MUST:
- be explicit
- stop execution
- be visible in output and exit code

---

## 8. CI ENFORCEMENT

CI enforcement (current or future) MAY include:

* ScriptAnalyzer lint
* Header presence and lifecycle declaration
* Unit tests for `lib/*`
* Runtime dry-run execution for SAFE scripts
* Execution of VERIFY scripts only

MANUAL scripts MUST NOT be executed in CI.

CI is advisory, not authoritative.

---

## 9. NON-GOALS

This project intentionally does NOT provide:

* enterprise hardening baselines
* domain, Intune, or MDM policy engines
* security guarantees beyond documented behavior

---

## 10. CHANGE POLICY

Breaking this contract requires:

* explicit documentation update
* architectural commit
* justification in commit message

Silent contract changes are not allowed.
---


If a script feels easier to write by violating this contract,
the contract is intentionally correct and the script is wrong.
