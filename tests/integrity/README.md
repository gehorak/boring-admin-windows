# integrity

Repository Integrity Tests

This directory is reserved for repository-level static checks such as:

- reference integrity
- parse checks
- naming consistency
- script class placement checks
- required-file presence checks

Current minimum integrity execution is routed through:

```text
.\tests\Invoke-Tests.ps1 -Suite integrity
```

Primary public integrity entrypoint:

```text
.\tests\integrity\validate-repo.ps1
```

This suite validates the tracked public repository surface directly.
It does not depend on `.ai/validation/`.
