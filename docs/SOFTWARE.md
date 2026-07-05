# Software

The software layer in this repository is an optional overlay.

## Public model

- software choices are local
- the user is responsible for package selection
- the repository does not ship a public approved-catalog workflow
- package-manager transport is not a trust substitute

## Safe habits

- use `check` or `plan` before changing software state
- prefer explicit package sources you understand
- avoid random third-party definitions copied from the internet
- keep optional overlays separate from your baseline reasoning

## Profiles

Software definitions live in your profile.
The repository only ships one anonymous example:

- [../config/profiles/individual.example.json](../config/profiles/individual.example.json)

Create your own local profile for real use.

## What not to store

Do not put these into tracked or shared profiles:

- passwords
- recovery keys
- license secrets
- personal identifiers you do not need

## Suggested flow

```powershell
.\boring-admin.ps1 check config --profile .\config\profiles\individual.local.json
.\boring-admin.ps1 plan software --profile .\config\profiles\individual.local.json
.\boring-admin.ps1 apply software --profile .\config\profiles\individual.local.json --change-id CHG-001
```
