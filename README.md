# boring-admin-windows

Source-available reference core for a technically capable individual
who wants an explicit way to review and maintain their own Windows device.

This repository is intentionally small.
It keeps the public surface focused on code, tests, one anonymous example profile,
and the minimum documentation needed to work safely.

## Who this is for

- a technically capable individual managing their own workstation
- a person maintaining a small number of personally controlled Windows devices
- a reader willing to inspect configuration and plan output before changing state

## What this is not

This project is not:

- MDM
- Active Directory
- a compliance baseline
- a hardening benchmark
- a one-click debloater
- a managed service

It does not promise centrally enforced policy,
turnkey deployment,
or vendor-style operational support.

## Operating philosophy

The core model is simple:

- start with read-only inspection
- decide explicitly before a write-capable step
- keep the change scope small and predictable
- prefer recovery or reinstall over improvised repair when confidence is low

The public command surface follows `check -> plan -> apply`.

- `check` inspects the current state without changing the workstation
- `plan` previews a specific target and shows what would change
- `apply` performs an explicit write-capable action and requires `--change-id`

If you are unsure, stop.
Do not treat missing certainty as permission to improvise.

## First safe commands

Start in a local clone that you control:

```powershell
.\boring-admin.ps1 help
.\boring-admin.ps1 check
.\boring-admin.ps1 plan <target>
```

Recommended first targets:

- `check`
- `check env`
- `check config --profile .\config\profiles\individual.example.json`
- `plan bootstrap`

Do not start with `apply`.

## Typical usage

1. Clone the repository locally.
2. Run a read-only `check`.
3. Read the relevant `plan` output for the target you care about.
4. Create your own local profile if you need host, identity, or software changes.
5. Use `apply` only after you understand the plan, the backup situation,
   and the likely reboot or recovery impact.

Optional software and UX changes are overlays.
They are not the starting point for a suspicious or inherited machine.

## Configuration

The repository includes one anonymous example profile:

- [config/profiles/individual.example.json](./config/profiles/individual.example.json)

Create your own local profile from it and keep that local file untracked.

Read:

- [docs/CONFIGURATION.md](./docs/CONFIGURATION.md)
- [docs/SOFTWARE.md](./docs/SOFTWARE.md)

## Recovery first

This project helps you inspect and apply bounded changes,
but it does not rescue data automatically and it does not replace preparation.

Before risky work, make sure you have:

- data stored outside the device
- account access that does not depend on the device being healthy
- BitLocker recovery material stored outside the device

Read:

- [docs/RECOVERY-PLAYBOOK.md](./docs/RECOVERY-PLAYBOOK.md)
- [docs/ANNUAL-MAINTENANCE.md](./docs/ANNUAL-MAINTENANCE.md)

## Documentation map

English:

- [docs/GETTING-STARTED.md](./docs/GETTING-STARTED.md)
- [docs/COMMANDS.md](./docs/COMMANDS.md)
- [docs/COMMON-SCENARIOS.md](./docs/COMMON-SCENARIOS.md)
- [docs/CONFIGURATION.md](./docs/CONFIGURATION.md)
- [docs/SOFTWARE.md](./docs/SOFTWARE.md)
- [docs/RECOVERY-PLAYBOOK.md](./docs/RECOVERY-PLAYBOOK.md)
- [docs/ANNUAL-MAINTENANCE.md](./docs/ANNUAL-MAINTENANCE.md)
- [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md)
- [docs/TESTING.md](./docs/TESTING.md)
- [docs/CONTRIBUTING.md](./docs/CONTRIBUTING.md)

Čeština:

- [docs/cs/README.md](./docs/cs/README.md)
- [docs/cs/ZACINAME.md](./docs/cs/ZACINAME.md)
- [docs/cs/BEZNE-SCENARE.md](./docs/cs/BEZNE-SCENARE.md)
- [docs/cs/BEZPECNE-POUZITI.md](./docs/cs/BEZPECNE-POUZITI.md)
- [docs/cs/OBNOVA-A-STOP.md](./docs/cs/OBNOVA-A-STOP.md)
- [docs/cs/SLOVNIK.md](./docs/cs/SLOVNIK.md)

## Testing

The public QA entrypoint is:

```powershell
.\tests\Invoke-Tests.ps1
```

The test suite checks syntax, integrity rules, smoke behavior,
unit behavior, and selected public contracts for the reference core.

## Contributing

Public changes should stay narrow and reviewable.
If you change behavior, update the relevant documentation and tests in the same change.

Read:

- [docs/CONTRIBUTING.md](./docs/CONTRIBUTING.md)
- [docs/TESTING.md](./docs/TESTING.md)

## Licensing and security boundary

License and commercial boundary:

- [LICENSE](./LICENSE)
- [LICENSE-SUMMARY.md](./LICENSE-SUMMARY.md)
- [COMMERCIAL.md](./COMMERCIAL.md)
- [TRADEMARKS.md](./TRADEMARKS.md)

Security guidance:

- [SECURITY.md](./SECURITY.md)

This repository is public technical material.
It should be used from a local clone you review yourself.
