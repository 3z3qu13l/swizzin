# swizzin (fork 3z3qu13l)

## Review

Dans ce dépôt, l'agent de review est **`swizzin-critic`** (`.claude/agents/swizzin-critic.md`). Il remplace tout autre agent de review désigné par les consignes globales (review demandée, avant toute PR).

## Pull requests

Titre **et description** de PR **en anglais**, comme les messages de commit. Le titre suit le format des commits (`fix(app): …`, `feat: …`).

## Ajout ou retrait d'une application

Toute application ajoutée, retirée ou renommée (`scripts/install/<app>.sh`) a aussi une entrée dans le catalogue du dashboard : `catalog/apps.json` du dépôt `3z3qu13l/swizzin-dashboard`. Sans elle, l'appli n'a pas de bouton Installer dans le dashboard.

- Le proposer dès le départ, dans le même plan que la PR swizzin, sans attendre qu'on le demande.
- Suite : PR dashboard, release (voir son CHANGELOG), puis `swizdash_version` et `swizdash_sha256` dans `sources/functions/swizdash`.
