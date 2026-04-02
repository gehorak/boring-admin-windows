# contract

Contract Tests

This directory is reserved for **Pester-based contract tests**
guarding script class rules from [../../docs/SCRIPT-CONTRACT.md](../../docs/SCRIPT-CONTRACT.md).

Typical coverage:

- VERIFY scripts remain read-only
- SAFE scripts expose `-WhatIf` where applicable
- MANUAL scripts are not auto-executed
- naming patterns remain canonical
- machine-readable output modes stay explicit and read-only

Run via:

```text
.\tests\Invoke-Tests.ps1 -Suite contract
```

Bootstrap requirement:

```text
.\tests\Pester-Bootstrap.ps1
```
