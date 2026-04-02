# UX Core Library (v002)

This document describes the **UX core library** used in boring-admin v002.

The UX core exists to provide **consistent, readable CLI output**
without introducing logic, authority, or hidden behavior.

---

## Purpose

The UX core library (`core/lib/ux.ps1`) provides:

- a unified visual vocabulary for CLI output
- structured, human-readable console formatting
- a stable foundation for future UX improvements

It is designed to be **boring, explicit, and predictable**.

---

## What the UX Core IS

- CLI-facing visual layer
- text-in / text-out only
- explicit function calls
- duplication-friendly by design
- safe to dot-source

The UX core is the **only place where new UX behavior is added in v002**.

---

## What the UX Core IS NOT

The UX core MUST NOT:

- inspect system or environment state
- make decisions or validations
- control execution flow
- terminate the process
- store or mutate state
- import or depend on other libraries (including `common.ps1`)

Any such behavior is considered a **contract violation**.

---

## Relationship to `common.ps1`

- `common.ps1` remains the shared runtime helper layer for legacy and transitional script output
- UX functionality is intentionally **duplicated**, not shared
- Duplication is preferred over coupling to avoid shared authority

The UX core does not depend on `common.ps1`, and vice versa.

---

## Scope

- Intended for **interactive CLI output only**
- Not suitable for:
  - background jobs
  - logging pipelines
  - non-interactive automation

---

## Design Principles

- visual only
- no logic
- no hidden state
- explicit over clever
- readability over convenience

If the UX core ever becomes "helpful", it is likely broken.

---

## Summary

The UX core library exists to improve **clarity**, not **control**.

It supports the boring-admin philosophy:
> tools expose capability, humans retain authority.
