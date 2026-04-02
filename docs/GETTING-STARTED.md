# GETTING-STARTED.md

Getting Started  
boring-admin-windows

---

## Purpose

This document helps a new operator choose the correct
entry path into `boring-admin-windows`.

It is intended for:

- first-time readers of the repository
- workstation takeover
- yearly maintenance handover
- technicians who need a fast starting point

This document is **operational guidance**.
It does not redefine architecture or command behavior.

---

## Start here first

If you are new to the repository, begin with:

```text
.\boring-admin.ps1 help
.\boring-admin.ps1 info
```

If you prefer Make-based discovery:

```text
make help
make -f Makefile.audit help
make -f Makefile.operational help
```

Then choose the path below that best matches your goal.

---

## I want to audit the current workstation

Use this path when:

- you inherited a machine
- you want a read-only view first
- you are doing routine review or annual maintenance

Recommended commands:

```text
.\boring-admin.ps1 audit all
.\boring-admin.ps1 audit summary
```

If you want a machine-readable export:

```text
.\boring-admin.ps1 audit export
```

If you want a human-readable archive:

```text
.\boring-admin.ps1 audit save
```

Reference:
- [COMMANDS.md](./COMMANDS.md)
- [ANNUAL-MAINTENANCE.md](./ANNUAL-MAINTENANCE.md)

---

## I want to set up a new workstation

Use this path when:

- the workstation is new
- Windows has been freshly installed
- you are applying the `v002` baseline from the beginning

Recommended starting point:

```text
.\boring-admin.ps1 setup
```

That setup path is expanded in:

- [FIRST-WORKSTATION-SETUP.md](./FIRST-WORKSTATION-SETUP.md)

If you need a quick preflight before acting:

```text
.\boring-admin.ps1 check-env
```

---

## I want to verify the recovery path

Use this path when:

- BitLocker recovery visibility matters
- admin secret storage or escrow is being reviewed
- workstation trust is uncertain
- annual maintenance is in progress

Recommended commands:

```text
.\boring-admin.ps1 verify recovery
.\boring-admin.ps1 audit recovery
```

Then review:

- [RECOVERY-PLAYBOOK.md](./RECOVERY-PLAYBOOK.md)
- [SECRETS-MANAGEMENT.md](./SECRETS-MANAGEMENT.md)
- [INCIDENT-CLASSIFICATION.md](./INCIDENT-CLASSIFICATION.md)

---

## I want to work with optional software

Use this path when:

- baseline setup is already complete
- you want optional software overlay
- you want read-only software visibility first

Read-only first:

```text
.\boring-admin.ps1 verify software
```

Optional overlay entrypoint:

```text
.\boring-admin.ps1 overlay software
```

Reference:
- [SOFTWARE.md](./SOFTWARE.md)
- [BOUNDARIES.md](./BOUNDARIES.md)

---

## I want a quick annual maintenance pass

Use this path when:

- you are doing the yearly review
- you want the shortest practical operator path

Recommended commands:

```text
.\boring-admin.ps1 audit all
.\boring-admin.ps1 verify software
.\boring-admin.ps1 verify recovery
```

Reference:
- [ANNUAL-MAINTENANCE.md](./ANNUAL-MAINTENANCE.md)

---

## I do not know where to start

Use this order:

1. `.\boring-admin.ps1 help`
2. `.\boring-admin.ps1 info`
3. [BOUNDARIES.md](./BOUNDARIES.md)
4. [COMMANDS.md](./COMMANDS.md)
5. [FIRST-WORKSTATION-SETUP.md](./FIRST-WORKSTATION-SETUP.md) if the machine is new
6. [ANNUAL-MAINTENANCE.md](./ANNUAL-MAINTENANCE.md) if the machine already exists

If the workstation already looks suspicious or degraded:

1. `.\boring-admin.ps1 audit all`
2. `.\boring-admin.ps1 verify recovery`
3. [RECOVERY-PLAYBOOK.md](./RECOVERY-PLAYBOOK.md)

---

## Rules of use

- prefer read-only review before write-capable actions
- do not treat `verify` as `apply`
- do not jump to overlays before baseline understanding exists
- do not continue through uncertainty by habit
- if recovery or trust is unclear, stop and review the recovery path

---

## See also

- [COMMANDS.md](./COMMANDS.md)
- [BOUNDARIES.md](./BOUNDARIES.md)
- [FIRST-WORKSTATION-SETUP.md](./FIRST-WORKSTATION-SETUP.md)
- [ANNUAL-MAINTENANCE.md](./ANNUAL-MAINTENANCE.md)
- [RECOVERY-PLAYBOOK.md](./RECOVERY-PLAYBOOK.md)
