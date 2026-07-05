# Contributing

## Local setup

Use a local clone and start with the public docs:

- [GETTING-STARTED.md](./GETTING-STARTED.md)
- [COMMANDS.md](./COMMANDS.md)
- [TESTING.md](./TESTING.md)

## Change style

- keep changes small and reviewable
- do not bundle unrelated refactors
- update docs and tests together with behavior changes
- preserve the `check -> plan -> apply` safety model

## Required verification

Run the public QA entrypoint:

```powershell
.\tests\Invoke-Tests.ps1
```

Any change to the public documentation surface must pass the integrity boundary test.

## Proposing changes

When proposing a change:

- describe the behavior change clearly
- say which target or document surface it affects
- keep the public surface minimal

New public documentation should justify its existence.
If a reader can safely operate without it,
it probably does not belong here.
