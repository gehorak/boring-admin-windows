# Scripts execution model

- apply/   → scripts that change system state
- verify/  → scripts that only read and report state
- migrate/ → one-time or bootstrap operations
- overlay/ → optional, non-baseline actions

Mixing responsibilities is forbidden.
