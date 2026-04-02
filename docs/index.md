# Documentation

This directory contains the **repository documentation set**
for `boring-admin-windows`.

It includes:
- normative architecture and behavior documents
- operational guidance
- status and authority mapping
- domain-specific supplements

Implementation details follow this documentation
and must not contradict higher-authority documents.

---

## Authority and status

Read these first:

- **AUTHORITY.md**  
  Defines document precedence and conflict resolution.

- **REPOSITORY-STATUS.md**  
  Defines what is active product surface, what is internal,
  and what is out of scope for `v002`.

- **PUBLIC-EXPORT.md**  
  Defines how the private governing repository is turned into
  a public-clean release surface.

Current public-facing QA surface includes:
- `PSScriptAnalyzerSettings.psd1`
- `tests/`
- `.github/workflows/qa.yml`

These documents do not replace repository contract or architecture.
They make repository interpretation explicit during normalization.

---

## Current documentation set

The following documents make up the current repository documentation set.
Not every document below has the same authority level.

Primary entry surfaces for the repository are:
- `boring-admin.ps1` for Windows-native PowerShell usage
- `Makefile` for safe discovery
- `Makefile.audit` for read-only verification and recovery visibility
- `Makefile.operational` for explicit apply and overlay actions

Machine-readable aggregate audit export is available through:
- `.\boring-admin.ps1 audit export`
- `make -f Makefile.audit audit-export`

Human-readable audit archiving is available through:
- `.\boring-admin.ps1 audit save`
- `make -f Makefile.audit audit-save`

Short operator summary output is available through:
- `.\boring-admin.ps1 audit summary`
- `make -f Makefile.audit audit-summary`

### Architecture and structure

- **ARCHITECTURAL-POSITION.md**  
  Defines system identity, promise, and positioning.

- **STRUCTURE.md**  
  Defines lifecycle domains, script responsibilities,
  and structural boundaries.

- **ARCHITECTURE-v002.md**  
  Defines the v002 operational boundary contract.

- **DESIGN-RATIONALE.md**  
  Explains why architectural decisions were made,
  including constraints and trade-offs.

- **ARCHITECTURE-GUARD.md**  
  Defines non-negotiable rules protecting the architecture
  from erosion over time.

---

### Operation and usage

- **SCRIPT-CONTRACT.md**  
  Defines behavioral rules for script classes and runtime expectations.

- **IDENTITY.md**  
  Defines the local identity model and related script responsibilities.

- **SOFTWARE.md**  
  Defines the software lifecycle and overlay model.

- **SOFTWARE-APPROVAL-MODEL.md**  
  Defines lightweight request, approval, and review guidance for optional software overlays.

- **UX.md**  
  Defines the CLI UX helper layer and its scope boundaries.

- **SECRETS-MANAGEMENT.md**  
  Defines the minimum external storage and escrow model for administrator secrets
  and BitLocker recovery keys.

- **ADMIN-ACCESS-GOVERNANCE.md**  
  Defines the minimum governance model for administrative roles,
  external secret storage, and access review.

- **RECOVERY-MATERIAL-CHECKLIST.md**  
  Checklist for verifying that external recovery material really exists and is documented.

- **OPERATING-MANUAL.md**  
  User-facing rules describing how the system is intended
  to be used on a daily basis.

- **ANNUAL-MAINTENANCE.md**  
  Minimal yearly maintenance checklist ensuring long-term
  predictability and recoverability.

- **RECOVERY-PLAYBOOK.md**  
  Scenario-based operator guidance for common recovery-oriented situations.

- **BOUNDARIES.md**  
  Compact operator-facing summary of baseline, overlay,
  verify/apply, audit, and recovery boundaries.

- **COMMANDS.md**  
  Compact reference for the main Windows-native and Make-based commands.

- **TEST-STRATEGY.md**  
  Defines the intended QA layers, test tree, and Pester role.

- **AUDIT-EXPORT-FORMAT.md**  
  Documents the current `v002` machine-readable audit export shape and compatibility rules.

- **FIRST-WORKSTATION-SETUP.md**  
  Recommended first-setup sequence for a new workstation,
  from preflight through final audit.

- **INCIDENT-CLASSIFICATION.md**  
  Severity and response guidance for common findings and operator incidents.

- **GETTING-STARTED.md**  
  A compact onboarding guide for choosing the correct operator path.

- **COMMON-SCENARIOS.md**  
  Short walkthroughs for common operator tasks using the current command surface.

---

## Document authority

Document authority is **not uniform across this directory**.

Use [AUTHORITY.md](./AUTHORITY.md) as the canonical precedence map.

If documentation and implementation diverge,
higher-authority documentation is considered authoritative.

Changes to system behavior must be reflected in the relevant
normative documents before or together with implementation changes.

---

## Article series (planned)

This repository is accompanied by a series of articles
intended to explain the underlying philosophy and adoption model.

Each article introduces a single concept
and corresponds to one adoption step.

Planned topics include:

- Why boring administration scales better
- Treating the operating system as disposable
- Baseline versus overlays
- Human-driven orchestration
- Recovery-first system design

Articles will be published in this documentation tree
and rendered via GitHub Pages.

---

## How to read this documentation

Recommended reading order:

1. `README.md` (repository contract)
2. `AUTHORITY.md` (precedence and conflict rules)
3. `REPOSITORY-STATUS.md` (active scope and release posture)
4. `STRUCTURE.md` (lifecycle and responsibilities)
5. `ARCHITECTURAL-POSITION.md` (system identity)
6. `ARCHITECTURE-GUARD.md` (non-negotiable rules)
7. `ARCHITECTURE-v002.md` (v002 operational boundaries)
8. `SCRIPT-CONTRACT.md` (script behavior rules)
9. domain supplements (`IDENTITY.md`, `SOFTWARE.md`, `UX.md`)
10. `SECRETS-MANAGEMENT.md` (external secret storage and escrow rules)
11. `ADMIN-ACCESS-GOVERNANCE.md` (administrative role and access governance)
12. `RECOVERY-MATERIAL-CHECKLIST.md` (external recovery material checklist)
13. `DESIGN-RATIONALE.md` (architectural decisions)
14. `OPERATING-MANUAL.md` (usage rules)
15. `ANNUAL-MAINTENANCE.md` (long-term operation)
16. `RECOVERY-PLAYBOOK.md` (scenario-based recovery guidance)
17. `INCIDENT-CLASSIFICATION.md` (severity and response guidance)
18. `GETTING-STARTED.md` (operator onboarding and entry-path selection)
19. `AUDIT-EXPORT-FORMAT.md` (current machine-readable export shape)
20. `SOFTWARE-APPROVAL-MODEL.md` (overlay approval and review guidance)
21. `COMMON-SCENARIOS.md` (quick walkthroughs for common operator tasks)

Suggested first command on Windows:

```text
.\boring-admin.ps1 help
```

Suggested QA entrypoint:

```text
.\tests\Invoke-Tests.ps1
```

This order reflects the intended mental model.

---

## Status

The documentation set is **active and aligned with the normalized `v002` repository surface**.

Current expectations:
- authority remains explicit
- naming remains canonical
- QA claims match the current test surface
- stability claims must match repository reality

---

## Final note

This documentation exists to make the system
understandable, transferable, and sustainable.

If these documents can be read and understood
without access to the original author,
they have fulfilled their purpose.
