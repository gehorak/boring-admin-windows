# Recovery Playbook

This project does not automate recovery
and it does not guarantee data rescue.

Its role is to keep you honest about when to stop changing the machine.

## Data outside the device

Important data should exist outside the device before risky work begins.
If your only trusted copy lives on the machine you are changing,
your risk is already too high.

## Account and access outside the device

Do not depend on the device itself for your only administrator or account recovery path.
You should be able to sign in elsewhere,
reach the account portal,
or retrieve documentation without relying on the unhealthy machine.

## BitLocker recovery key outside the device

If the device uses BitLocker,
store the recovery key outside the device in a place you can actually reach.

## When to stop improvising

Stop when:

- the plan does not match your intent
- the machine behaves in a way you cannot explain
- you no longer trust the current state
- recovery material is missing or uncertain

## When reinstall is better than repair

Reinstall is often the safer choice when:

- the machine is heavily drifted
- you cannot explain prior changes
- trust in the current state is gone
- recovery is faster and more reliable than continued guessing

## Hard boundary

This repository helps you inspect and apply bounded changes.
It does not provide automatic rollback,
automatic recovery,
or any promise that lost data can be recovered.
