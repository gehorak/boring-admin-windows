# Začínáme

Tenhle projekt je pro člověka, který:

- se nebojí číst výstup příkazů
- chce si vlastní počítač spravovat vědomě
- raději vidí plán před změnou,
  než aby spouštěl nejasný automat

Tenhle projekt není pro:

- člověka, který chce jedno tlačítko a žádné čtení
- firemní správu flotily
- situaci, kde je potřeba centrální vynucování politik

## První kroky

Začni lokálně v klonu repozitáře:

```powershell
.\boring-admin.ps1 help
.\boring-admin.ps1 check
```

Tím si ověříš,
že rozumíš veřejnému rozhraní
a že nejdřív sbíráš přehled,
ne změny.

## Rozdíl mezi `check`, `plan` a `apply`

- `check` nic nemění a ukazuje stav
- `plan` nic nemění a ukazuje,
  co by se měnilo u konkrétního cíle
- `apply` už mění stav

Nezačínej `apply`.

## Kdy si vytvořit vlastní profil

Vlastní lokální profil potřebuješ,
jakmile chceš řešit host, identity nebo software podle vlastního záměru.

Vezmi:

```powershell
Copy-Item .\config\profiles\individual.example.json .\config\profiles\individual.local.json
```

Pak ho uprav pro svůj počítač
a před dalšími kroky spusť kontrolu konfigurace.

## Když si nejsi jistý

Zastav se u `check` nebo `plan`.
Nejistota není signál k odvážnému `apply`,
ale k tomu,
že si máš doplnit informace.
