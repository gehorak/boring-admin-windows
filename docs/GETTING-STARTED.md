# Getting Started

This guide is the safe first path for a local clone.

## Requirements

- Windows with PowerShell available
- a local clone you control
- enough access to read system state
- enough patience to inspect output before changing anything

Optional but recommended:

- PowerShell 7+
- a recent `git`
- an external backup you trust

## Start from a local clone

Do not run this project as a remote bootstrap snippet.
Clone it locally, read the docs, and start with read-only commands.

```powershell
.\boring-admin.ps1 help
.\boring-admin.ps1 check
```

## First read-only control

The normal first step is:

```powershell
.\boring-admin.ps1 check
```

Useful focused checks:

```powershell
.\boring-admin.ps1 check env
.\boring-admin.ps1 check config --profile .\config\profiles\individual.example.json
```

`check` is for visibility.
It should help you understand the machine before you think about changing it.

## When to use `plan`

Use `plan` when you want to preview one bounded target:

```powershell
.\boring-admin.ps1 plan bootstrap
.\boring-admin.ps1 plan host --profile .\config\profiles\individual.local.json
.\boring-admin.ps1 plan software --profile .\config\profiles\individual.local.json
```

`plan` is still read-only.
It is the place to stop and decide whether the change is appropriate.

## When `apply` is reasonable

`apply` is reasonable only when all of these are true:

- you understand the target
- the plan matches your intent
- you have a local profile if the target requires one
- you know the likely reboot or recovery impact
- you have an external backup and recovery path

`apply` is not the discovery step.

## Backups, recovery, and restarts

Before risky work, confirm:

- data lives outside the device or is backed up elsewhere
- account access does not depend on the device being healthy
- BitLocker recovery material is stored outside the device
- you can tolerate a reboot or a reinstall if confidence collapses

If the machine becomes uncertain,
stop and prefer recovery or reinstall over improvised repair.

## Next documents

- [COMMANDS.md](./COMMANDS.md)
- [COMMON-SCENARIOS.md](./COMMON-SCENARIOS.md)
- [RECOVERY-PLAYBOOK.md](./RECOVERY-PLAYBOOK.md)
- [CONFIGURATION.md](./CONFIGURATION.md)
