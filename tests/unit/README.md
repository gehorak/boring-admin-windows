# unit

Unit Tests

This directory is reserved for **Pester-based unit tests**
covering bounded helper behavior.

Initial target files:

- `core/lib/common.ps1`
- `core/lib/ux.ps1`

Typical coverage:

- output helper behavior
- fatal and warning helper behavior
- path helper behavior
- confirmation helper behavior

Run via:

```text
.\tests\Invoke-Tests.ps1 -Suite unit
```

Bootstrap requirement:

```text
.\tests\Pester-Bootstrap.ps1
```
