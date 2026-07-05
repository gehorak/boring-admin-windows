# Bezpečné použití

Základní pravidlo je pořád stejné:

nejdřív `check`,
potom `plan`,
až nakonec `apply`.

## Proč na tom záleží

`check` ti dává přehled.
`plan` ti dává možnost zastavit se nad důsledky.
`apply` už je závazný krok,
který může změnit stav počítače
nebo vyžadovat restart.

## Jak číst `plan`

U plánu se ptej:

- chápu, proč se tahle změna navrhuje?
- odpovídá to mému záměru?
- mám zálohu a obnovu,
  kdyby se to nepovedlo?

Když je odpověď nejasná,
nepokračuj.

## Kdy `apply` nespouštět

`apply` nespouštěj,
když:

- si nejsi jistý cílem
- nevíš,
  odkud se berou hodnoty v profilu
- nemáš ověřenou zálohu nebo recovery
- je počítač už teď v podezřelém stavu

## Další bezpečnostní hranice

- neobcházej Execution Policy jen proto,
  aby „to nějak běželo“
- neprováděj riskantní zásah bez ověření zálohy nebo recovery
- nespoléhej na to,
  že projekt za tebe zachrání data

Když si nejsi jistý,
zastav se.
