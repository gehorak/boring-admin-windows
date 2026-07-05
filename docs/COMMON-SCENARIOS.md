# Common Scenarios

This document keeps the public usage path practical and short.

## 1. First control of an existing personal machine

Start read-only.

```powershell
.\boring-admin.ps1 check
.\boring-admin.ps1 check env
```

Then review only the areas you actually intend to touch.
Do not jump straight to overlays or write-capable steps.

## 2. New or freshly reinstalled machine

Start with:

```powershell
.\boring-admin.ps1 check
.\boring-admin.ps1 plan bootstrap
```

Create a local profile only when you are ready to manage host,
identity, or software intentionally.

## 3. Intentional installation of optional personal software

Prepare a local profile and review the plan first:

```powershell
.\boring-admin.ps1 check config --profile .\config\profiles\individual.local.json
.\boring-admin.ps1 plan software --profile .\config\profiles\individual.local.json
```

Choose package sources consciously.
Do not paste random package definitions into your local profile.

## 4. Yearly read-only review

Use the project as a visibility tool first:

```powershell
.\boring-admin.ps1 check
```

Then review recovery readiness,
software drift,
and any warnings you have left unresolved.

## 5. Shortest safe start

If you need the shortest safe path, do this:

```powershell
.\boring-admin.ps1 help
.\boring-admin.ps1 check
.\boring-admin.ps1 plan bootstrap
```

If you still do not understand what should happen next,
stop there and read the related documents before using `apply`.
