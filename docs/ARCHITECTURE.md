# Architecture

## Public shape

The repository is built around one public CLI entrypoint:

- [../boring-admin.ps1](../boring-admin.ps1)

That entrypoint exposes the intended top-level flow:

- `check`
- `plan`
- `apply`

## Configuration

Configuration lives under `config/`.
The public example profile is anonymous
and real machine-specific values belong in an untracked local profile.

## Read-only checks

Read-only inspection lives behind `check`
and the verify scripts under `scripts/verify/`.

## Plans

`plan` previews bounded changes without modifying workstation state.
It is the decision point before any write-capable action.

## Explicit apply

`apply` is the only public write-capable top-level verb.
It requires an explicit target
and a `--change-id`.

## Scripts

The repository is split into:

- `core/` for shared PowerShell helpers
- `scripts/verify/` for read-only inspection
- `scripts/migrate/`, `scripts/apply/`, and `scripts/overlay/` for explicit change execution

## Tests

`tests/` contains the public QA surface used by local runs and CI.

## Local runtime records

The tool may write local runtime records under `%ProgramData%\BoringAdmin\records`.
Those records are technical runtime output only.
They are not a public service workflow
or a formal evidence process.
