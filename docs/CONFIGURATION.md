# Configuration

## Public example profile

The repository ships one anonymous example profile:

- [../config/profiles/individual.example.json](../config/profiles/individual.example.json)

It is an example only.
Do not use it unchanged as if it described your real machine.

## Create your own local profile

Create an untracked local copy:

```powershell
Copy-Item .\config\profiles\individual.example.json .\config\profiles\individual.local.json
```

Then edit the local file for your own device.

## Safe values

Safe profile content includes:

- workstation name intent
- time zone
- locale
- local account naming
- software package choices and sources

## What must not be in the profile

Do not put these values in your tracked or shared profile:

- passwords
- recovery keys
- license keys
- personal data you do not need
- tokens or API secrets

## Validate the profile

Use the built-in config check:

```powershell
.\boring-admin.ps1 check config --profile .\config\profiles\individual.local.json
```

Use the example profile only for read-only learning or test coverage.

## Do not commit the local profile

`config/profiles/individual.local.json` should stay local and untracked.
The repository ignore rules are there to help,
not to excuse sloppy review.
