# SCRIPT CONTRACT
## boring-admin-windows

This document defines the **behavioral contract**
for the active PowerShell product surface of `boring-admin-windows`.

It exists to keep script behavior:
- predictable
- reviewable
- auditable
- compatible with reinstall-over-repair operations

This contract is **normative** within the boundaries
defined by higher-authority repository documents.

---

## 1. SCOPE

This contract applies to:
- scripts in `scripts/`
- shared libraries in `core/lib/`

This contract does **not** directly govern:
- internal `.ai/` tooling
- task-local prompts
- temporary validation helpers
- root convenience entrypoints such as `boring-admin.ps1`

Those artifacts may support the repository,
but they are not lifecycle scripts.

This contract applies **within**
the lifecycle model defined in `docs/STRUCTURE.md`
and the operational boundary model defined in `docs/ARCHITECTURE-v002.md`.

---

## 2. SCRIPT CLASSES

Script intent is declared by filename and location.

### 2.1 SAFE SCRIPTS

Pattern:

```text
NN-*.safe.ps1
```

Purpose:
- apply bounded, low-risk configuration
- modify system state in a predictable and repeatable way

Requirements:
- MUST be idempotent
- MUST support `-WhatIf` when state changes are performed
- MUST NOT reboot automatically
- MUST NOT require operator prompts

SAFE scripts are expected to be mechanically repeatable.

---

### 2.2 VERIFY SCRIPTS

Pattern:

```text
NN-*.verify.ps1
```

Purpose:
- observe and report current system state
- verify lifecycle assumptions
- support audit and incident context

Requirements:
- MUST be strictly read-only
- MUST NOT modify system state
- MUST NOT perform remediation
- MUST NOT trigger follow-on actions automatically
- MUST produce deterministic, human-readable output
- MAY expose an explicit machine-readable output mode such as `-OutputFormat Json`
  when the read-only behavior remains unchanged

VERIFY scripts may report warnings,
but warnings are observational, not enforcement.

---

### 2.3 MANUAL SCRIPTS

Pattern:

```text
NN-*.manual.ps1
```

Purpose:
- perform human-driven actions
- expose explicit orchestration
- handle higher-risk or stateful decisions

Requirements:
- MUST require explicit operator invocation
- MUST NOT be executed automatically or in CI
- MUST NOT attempt silent or implicit changes

If a MANUAL script changes system state,
it MUST require explicit confirmation or operator input.

Read-only MANUAL orchestrators may guide or summarize
without requiring confirmation,
provided they do not perform changes.

---

### 2.4 LIBRARY FILES

Pattern:

```text
core/lib/*.ps1
```

Purpose:
- helper functions
- output vocabulary
- bounded shared runtime helpers

Requirements:
- MUST have no side effects on import
- MUST NOT execute code on load
- MUST be safe for dot-sourcing
- MUST NOT silently redefine repository meaning

Library helpers may:
- emit formatted output when explicitly called
- terminate execution through documented helpers such as `Exit-Fatal`
- update caller-managed runtime flags such as `$script:HadWarnings`

Libraries must not become a hidden policy engine.

---

## 3. EXIT MODEL

`v002` uses **Variant A** exit semantics:

| Code | Meaning |
|-----:|--------|
| 0 | Completed successfully, with or without warnings |
| 1 | Fatal error / execution failure |

Warnings are informational.
They do not create a separate exit code in `v002`.

Rules:
- scripts MUST terminate with a meaningful exit code
- fatal conditions MUST be reflected in exit code
- warning conditions MUST be visible in output
- scripts MUST NOT rely on text output alone to signal fatal failure

If a future version introduces a different exit model,
that change requires an explicit contract update.

---

## 4. OUTPUT RULES

Lifecycle scripts MUST use a consistent output vocabulary.

Canonical semantic prefixes are:

| Prefix | Meaning |
|--------|---------|
| `[INFO]` | normal progress or state description |
| `[OK]` | successful outcome |
| `[WARN]` | non-fatal deviation or uncertainty |
| `[FAIL]` | fatal condition |

Rules:
- semantic status output SHOULD go through helpers in `core/lib/common.ps1`
- fatal conditions MUST emit `[FAIL]` before termination
- scripts MUST NOT invent new semantic prefixes without contract update

Raw `Write-Host` remains acceptable for:
- spacing
- menus
- static operator prompts
- non-semantic headings

PowerShell-native `Write-Error` and `Write-Warning`
must not be used in lifecycle scripts under `scripts/`
when shared contract helpers already express the same condition.

---

## 5. PRIVILEGES

Scripts MUST declare privilege expectations explicitly.

Rules:
- administrative rights MUST be checked explicitly when required
- no implicit elevation assumptions are allowed

Typical form:

```powershell
Assert-Administrator
```

If a script can operate safely without elevation,
that behavior must be intentional and obvious from context.

---

## 6. IDEMPOTENCE

Idempotence is mandatory for SAFE scripts.

Running the same SAFE script:
- once applies the intended change
- repeatedly does not create uncontrolled additional changes

Idempotence is not required for MANUAL scripts,
but repeated execution must still remain understandable and bounded.

---

## 7. ERROR HANDLING

Silent failure is forbidden.

Rules:
- `-ErrorAction SilentlyContinue` is allowed only for bounded detection
  when the result is explicitly checked or handled
- `catch` blocks MUST emit output or intentionally return a documented safe value
- guarded queries SHOULD return `$null` instead of blocking indefinitely

Fatal errors MUST:
- be explicit
- stop execution
- remain visible in output and exit behavior

---

## 8. CI AND VALIDATION

Current or future validation MAY include:
- parse validation
- reference integrity checks
- naming and contract checks
- ScriptAnalyzer lint
- unit tests for `core/lib/*`
- dry-run execution for SAFE scripts
- execution of VERIFY scripts only

MANUAL scripts MUST NOT be executed automatically in CI.

CI and validation are enforcement tools for repository consistency.
They are not a substitute for architectural authority.

---

## 9. NON-GOALS

This project intentionally does **not** provide:
- enterprise hardening baselines
- domain, Intune, or MDM policy engines
- continuous compliance enforcement
- unattended lifecycle orchestration

The script layer exists to support
explicit, human-driven system administration.

---

## 10. CHANGE POLICY

Changing this contract requires:
- explicit documentation update
- justification in commit history
- alignment with higher-authority repository documents

Silent contract drift is not allowed.

---

If a script feels easier to write by violating this contract,
the contract is intentionally guarding something important.
