# RECOVERY-MATERIAL-CHECKLIST.md

Recovery Material Checklist  
boring-admin-windows

---

## Purpose

This document provides a compact **recovery material checklist**
for a workstation governed by `boring-admin-windows`.

It exists to answer:

> Do we actually have the external material required to recover this workstation?

This document is **operational guidance**.
It is intentionally human-readable and checklist-oriented.
It is not a proof mechanism and it is not an automation surface.

---

## How to use this checklist

Use this checklist:

- during annual maintenance
- during workstation takeover
- after a recovery incident
- before accepting a workstation as supportable

This checklist should be completed **outside the device itself**
or stored in an external location that survives workstation loss.

---

## Recovery material checklist

### Administrative access

☐ Primary administrator secret exists in the intended external secret store  
☐ Recovery / break-glass administrator secret exists in the intended external secret store  
☐ The person responsible for the workstation knows where both secrets are stored  
☐ Retrieval rights for both secrets are clear and current  
☐ The recovery administrator is still treated as insurance, not convenience  

### BitLocker recovery

☐ BitLocker recovery keys are escrowed outside the workstation  
☐ The expected escrow path is documented  
☐ The responsible operator knows how to retrieve the recovery key  
☐ The escrow path has been reviewed recently enough to remain credible  

### Reinstall and continuation

☐ A documented reinstall path exists  
☐ The reinstall path is still acceptable to the responsible operator  
☐ Required Windows media or retrieval path is known  
☐ The operator understands when reinstall is preferred over repair  

### Data recovery

☐ The primary user data recovery path is documented  
☐ OneDrive or equivalent external data path is understood  
☐ The operator knows what data is expected to survive OS loss  
☐ The operator knows what data would be lost if the workstation were wiped today  

### Ownership and contact

☐ Primary workstation owner / operator is documented  
☐ Backup or recovery contact is documented if applicable  
☐ Last review date is recorded  
☐ Reviewer or technician name is recorded  

---

## Minimum required answers

For a workstation to be treated as operationally recoverable,
the operator should be able to answer these immediately:

- Where is the primary admin secret?
- Where is the recovery admin secret?
- Where is the BitLocker recovery key escrowed?
- How is user data recovered after reinstall?
- Who owns the workstation today?

If any answer is missing or unclear,
the recovery path is incomplete.

---

## Suggested record block

Use a simple external note or record like this:

```text
Workstation:
Primary owner:
Backup / recovery contact:
Primary admin secret location:
Recovery admin secret location:
BitLocker escrow location:
User data recovery path:
Reinstall path note:
Last reviewed:
Reviewed by:
```

This repository does not require a specific storage tool.
It does require that the record be external, reviewable, and understandable.

---

## What this checklist does not prove

This checklist does not prove:

- that the recovery key retrieval definitely succeeds right now
- that the external secret store is reachable at this moment
- that user data restore has been recently tested
- that the workstation is healthy

It only confirms whether the necessary recovery material
appears to be present and documented.

---

## Related read-only commands

This checklist is supported by current read-only visibility,
for example:

```text
.\boring-admin.ps1 verify recovery
.\boring-admin.ps1 audit all
```

These commands help reconstruct reality,
but they do not replace this external checklist.

---

## References

- [SECRETS-MANAGEMENT.md](./SECRETS-MANAGEMENT.md)
- [ADMIN-ACCESS-GOVERNANCE.md](./ADMIN-ACCESS-GOVERNANCE.md)
- [RECOVERY-PLAYBOOK.md](./RECOVERY-PLAYBOOK.md)
- [ANNUAL-MAINTENANCE.md](./ANNUAL-MAINTENANCE.md)
