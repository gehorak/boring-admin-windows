# smoke

Smoke Tests

This directory is reserved for bounded runtime verification
of the safest supported entry surfaces.

Current targets:

- `boring-admin.ps1 help`
- `boring-admin.ps1 info`
- `boring-admin.ps1 audit help`
- `boring-admin.ps1 check-env`

Smoke tests must remain:

- explicit
- bounded
- read-only by default

MANUAL scripts must not be executed automatically in this suite.

Run via:

```text
.\tests\Invoke-Tests.ps1 -Suite smoke
```

Bootstrap requirement:

```text
.\tests\Pester-Bootstrap.ps1
```

Shared helpers used by this suite live in:

```text
tests\smoke\Smoke-Helpers.ps1
```
