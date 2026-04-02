# COMMANDS.md

Command Reference  
boring-admin-windows

---

## Purpose

This document provides a compact reference for the main
human-facing commands exposed by the repository.

It is intended for:

- first-time operators
- annual maintenance use
- workstation takeover
- quick recall during incident review

This document is **supporting guidance**.
Normative meaning remains defined by higher-authority documents.

---

## Windows-native entrypoint

### Discovery

```text
.\boring-admin.ps1 help
.\boring-admin.ps1 info
.\boring-admin.ps1 setup
.\boring-admin.ps1 check-env
```

### Read-only audit and verify

```text
.\boring-admin.ps1 audit help
.\boring-admin.ps1 audit all
.\boring-admin.ps1 audit export
.\boring-admin.ps1 audit save
.\boring-admin.ps1 audit summary
.\boring-admin.ps1 audit recovery
.\boring-admin.ps1 verify all
.\boring-admin.ps1 verify security
.\boring-admin.ps1 verify software
.\boring-admin.ps1 verify identity
.\boring-admin.ps1 verify host
.\boring-admin.ps1 verify system
.\boring-admin.ps1 verify recovery
```

### Write-capable entrypoints

```text
.\boring-admin.ps1 operational help
.\boring-admin.ps1 apply security
.\boring-admin.ps1 apply identity
.\boring-admin.ps1 apply host
.\boring-admin.ps1 overlay software
.\boring-admin.ps1 overlay ux
```

---

## Make-based entrypoints

### Discovery

```text
make help
make -f Makefile.audit help
make -f Makefile.operational help
```

### Read-only audit and verify

```text
make -f Makefile.audit audit
make -f Makefile.audit audit-export
make -f Makefile.audit audit-save
make -f Makefile.audit audit-summary
make -f Makefile.audit verify-all
make -f Makefile.audit verify-security
make -f Makefile.audit verify-software
make -f Makefile.audit verify-identity
make -f Makefile.audit verify-host
make -f Makefile.audit verify-system
make -f Makefile.audit verify-recovery
make -f Makefile.audit recovery
```

### Write-capable entrypoints

```text
make -f Makefile.operational apply-security
make -f Makefile.operational apply-identity
make -f Makefile.operational apply-host
make -f Makefile.operational overlay-software
make -f Makefile.operational overlay-ux
```

---

## Recommended operator paths

### First workstation setup

```text
.\boring-admin.ps1 setup
```

Reference:
- [FIRST-WORKSTATION-SETUP.md](./FIRST-WORKSTATION-SETUP.md)

### Annual maintenance

```text
.\boring-admin.ps1 audit all
.\boring-admin.ps1 verify software
.\boring-admin.ps1 verify recovery
```

Reference:
- [ANNUAL-MAINTENANCE.md](./ANNUAL-MAINTENANCE.md)

### Machine-readable export

```text
.\boring-admin.ps1 audit export
```

### Human-readable archive

```text
.\boring-admin.ps1 audit save
```

### Fast operator summary

```text
.\boring-admin.ps1 audit summary
```

---

## Notes

- `verify all` is an alias for the same read-only aggregate as `audit all`
- most verify and audit commands require an elevated shell
- `audit export` is intended for machine-readable JSON output
- `audit save` writes a human-readable audit file outside the repository
- `audit summary` is intentionally short and does not replace the full audit

---

## See also

- [AUTHORITY.md](./AUTHORITY.md)
- [BOUNDARIES.md](./BOUNDARIES.md)
- [FIRST-WORKSTATION-SETUP.md](./FIRST-WORKSTATION-SETUP.md)
- [PUBLIC-EXPORT.md](./PUBLIC-EXPORT.md)
