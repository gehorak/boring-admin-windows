# Testing

## Public test command

Run:

```powershell
.\tests\Invoke-Tests.ps1
```

## What the tests cover

The public test surface checks:

- PowerShell parsing
- integrity rules for the public repository boundary
- smoke behavior of the public entrypoint
- unit behavior of core helpers
- selected public contracts

## Reporting failures

When a test fails,
keep the failing command output together with the changed files.
Do not claim success based only on partial suites.

## Limits

These tests reduce risk.
They do not prove the repository is bug-free
and they do not create operational support obligations.
