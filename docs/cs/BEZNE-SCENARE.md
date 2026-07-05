# Běžné scénáře

## Převzetí existujícího počítače

Když přebíráš vlastní starší počítač
nebo stroj,
u kterého si nejsi jistý minulostí,
začni čistě čtením:

```powershell
.\boring-admin.ps1 check
```

Nejdřív potřebuješ pochopit stav,
ne ukazovat akci.

## Nový nebo přeinstalovaný počítač

U čistého stroje dává smysl:

```powershell
.\boring-admin.ps1 plan bootstrap
```

To ti ukáže,
jak projekt přemýšlí o základním startu,
aniž by hned něco zapisoval.

## Vědomá instalace vlastního volitelného softwaru

Nejdřív si připrav lokální profil
a teprve potom plánuj software:

```powershell
.\boring-admin.ps1 check config --profile .\config\profiles\individual.local.json
.\boring-admin.ps1 plan software --profile .\config\profiles\individual.local.json
```

Smyslem je vědět,
co chceš a odkud to chceš,
ne jen „něco doinstalovat“.

## Roční kontrola

Jednou za čas je zdravé vrátit se k obyčejnému:

```powershell
.\boring-admin.ps1 check
```

Projdi warningy,
podívej se na software,
ověř obnovu
a zkontroluj,
jestli nemáš nevyřešené restarty nebo drift.

## Nejkratší bezpečný start

Když chceš opravdu stručný začátek:

```powershell
.\boring-admin.ps1 help
.\boring-admin.ps1 check
.\boring-admin.ps1 plan bootstrap
```

Pokud ti po tom pořád není jasné,
co se má stát,
nepokračuj do `apply`.
