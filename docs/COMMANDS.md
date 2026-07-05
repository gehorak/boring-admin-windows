# Commands

This document describes the public command surface only.

## Preferred public contract

```powershell
.\boring-admin.ps1 help
.\boring-admin.ps1 version
.\boring-admin.ps1 check [target]
.\boring-admin.ps1 plan <target>
.\boring-admin.ps1 apply <target> --change-id <id>
```

## Read-only versus write-capable

Read-only:

- `help`
- `version`
- `check`
- `plan`
- `apply --dry-run`

Write-capable:

- `apply`

## `help`

Shows the supported public surface and common usage notes.

## `version`

Prints the current public architecture surface identifier.

```powershell
.\boring-admin.ps1 version
.\boring-admin.ps1 version --json
```

## `check`

Read-only inspection of inputs, environment, or workstation state.

Targets:

- `all`
- `security`
- `software`
- `identity`
- `host`
- `system`
- `recovery`
- `env`
- `config`

Examples:

```powershell
.\boring-admin.ps1 check
.\boring-admin.ps1 check env
.\boring-admin.ps1 check config --profile .\config\profiles\individual.example.json
.\boring-admin.ps1 check --json
.\boring-admin.ps1 check --summary
.\boring-admin.ps1 check --save
```

`check --save` stays read-only with respect to workstation configuration.
It only writes local runtime records under `%ProgramData%\BoringAdmin\records\checks`.

## `plan`

Read-only preview of a specific target.

Targets:

- `bootstrap`
- `identity`
- `host`
- `software`
- `ux`
- `consumer-noise`
- `security`

Examples:

```powershell
.\boring-admin.ps1 plan bootstrap
.\boring-admin.ps1 plan host --profile .\config\profiles\individual.local.json
.\boring-admin.ps1 plan software --profile .\config\profiles\individual.local.json --json
```

`plan security` is still read-only.

## `apply`

Explicit write-capable action for one target.

Targets:

- `bootstrap`
- `identity`
- `host`
- `software`
- `ux`
- `consumer-noise`
- `security`

Examples:

```powershell
.\boring-admin.ps1 apply bootstrap --change-id CHG-001
.\boring-admin.ps1 apply host --profile .\config\profiles\individual.local.json --change-id CHG-001
.\boring-admin.ps1 apply software --profile .\config\profiles\individual.local.json --change-id CHG-001
.\boring-admin.ps1 apply consumer-noise --change-id CHG-001 --dry-run
```

Notes:

- `--change-id` is required for write-capable use
- `--profile` is required for host, identity, and software targets
- `apply security` is intentionally unsupported as a write-capable target
- `--dry-run` routes through the corresponding plan path

## Common options

- `--json` for supported machine-readable output
- `--quiet` to reduce non-essential output
- `--verbose` to show more boundary metadata
- `--profile <path>` to select a profile
- `--change-id <id>` for explicit write-capable execution

## Stable exit codes

The public boundary uses these exit codes:

- `0` success
- `2` invalid input
- `3` configuration problem
- `4` environment or precondition problem
- `5` permission problem
- `6` runtime failure
- `8` read-only check found actionable issues
- `10` plan or dry-run found pending changes
- `11` partial result or manual verification still needed
- `12` unsupported operation

## Compatibility note

Additional compatibility entrypoints may still exist in dispatch.
They are not the normal public operator path and are not documented here as preferred usage.
