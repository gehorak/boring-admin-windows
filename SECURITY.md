# Security Policy

## Scope

This repository exposes a source-available reference core.
It is meant to be reviewed and run from a local clone you control.

The public command model is intentionally narrow:

- `check` is read-only
- `plan` is read-only
- `apply` is the only public write-capable top-level verb

## Reporting a vulnerability

Do not open a public issue for a suspected security problem
in a write-capable script.

Use a non-public maintainer contact path if one is available.
If you are working from a fork with no maintainer contact,
stop redistribution, document the finding privately,
and review the affected code locally before further use.

## Supply-chain stance

- remote bootstrap by downloading PowerShell text and evaluating it immediately
  is not an accepted default pattern here
- package-manager transport does not replace trust review
- profiles are configuration, not secret storage
- local profiles must not contain passwords, recovery keys, API tokens,
  licenses, or personal data
- QA bootstrap is pinned to exact module versions

## Scope limits

This project is not:

- a compliance baseline
- a hardening benchmark
- a managed-service control plane

Using it does not create CIS, STIG, AD, MDM,
or regulatory compliance coverage.

## Sensitive changes

Changes touching these areas deserve extra review:

- `boring-admin.ps1`
- `core/lib/config.ps1`
- `scripts/apply/`
- `scripts/overlay/`
- `config/`
- `.github/workflows/qa.yml`

For those changes:

- preserve read-only behavior where promised
- keep `apply` explicit
- keep secrets out of tracked files
- update tests and docs together with behavior changes
