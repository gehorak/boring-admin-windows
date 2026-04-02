# FIRST-WORKSTATION-SETUP.md

First Workstation Setup Path  
boring-admin-windows

---

## Purpose

This document defines the recommended **first setup path**
for a new workstation entering the `boring-admin-windows` operating model.

It is intentionally:

- explicit
- human-driven
- low-surprise

This document is **operational guidance**.
It does not replace architectural authority.

---

## Recommended path

Use the following order for a new workstation:

1. environment preflight
2. OS bootstrap
3. security baseline review
4. identity setup
5. host identity setup
6. optional overlays
7. final audit

---

## Suggested command path

### 1. Review the repository surface

```text
.\boring-admin.ps1 help
.\boring-admin.ps1 info
```

### 2. Verify the execution environment

```text
.\boring-admin.ps1 check-env
.\scripts\migrate\00-env-preflight.ps1
```

### 3. Run bootstrap

```text
.\scripts\migrate\10-bootstrap-orchestrator.ps1
```

### 4. Review and apply security baseline

```text
.\boring-admin.ps1 verify security
.\boring-admin.ps1 apply security
```

### 5. Review and apply identity model

```text
.\boring-admin.ps1 verify identity
.\boring-admin.ps1 apply identity
```

### 6. Review and apply host identity

```text
.\boring-admin.ps1 verify host
.\boring-admin.ps1 apply host
```

### 7. Optional overlays only after baseline is stable

```text
.\boring-admin.ps1 overlay software
.\boring-admin.ps1 overlay ux
```

### 8. Final read-only review

```text
.\boring-admin.ps1 verify all
```

or:

```text
.\boring-admin.ps1 audit all
```

---

## Rules

- do not skip directly to overlays
- do not treat `verify` as `apply`
- do not continue through warnings by habit
- do not introduce environment-specific policy into `v002`

---

## Outcome

At the end of this path:

- baseline should be explicit
- identity should be clear
- host identity should be stable
- optional overlays should remain optional
- audit output should be readable and unsurprising

---

## See also

- [BOUNDARIES.md](./BOUNDARIES.md)
- [ANNUAL-MAINTENANCE.md](./ANNUAL-MAINTENANCE.md)
- [OPERATING-MANUAL.md](./OPERATING-MANUAL.md)
