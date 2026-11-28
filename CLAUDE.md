# swizzin (fork 3z3qu13l)

## Review

In this repository the review agent is **`swizzin-critic`** (`.claude/agents/swizzin-critic.md`). It replaces any other review agent named by the global instructions (review requested, before any PR).

## Pull requests

PR title **and description** in **English**, like commit messages. The title follows the commit format (`fix(app): …`, `feat: …`).

## Adding or removing an application

Any application added, removed or renamed (`scripts/install/<app>.sh`) also has an entry in the dashboard catalog: `catalog/apps.json` in the `3z3qu13l/swizzin-dashboard` repository. Without it, the app has no Install button in the dashboard.

- Propose it from the start, in the same plan as the swizzin PR, without waiting to be asked.
- Then: dashboard PR, release (see its CHANGELOG), then `swizdash_version` and `swizdash_sha256` in `sources/functions/swizdash`.

## Clean code

The goal is code that stays clean, maintainable and documented. On every change:

- Remove the dead code the change leaves behind (functions, files, branches for unsupported OS, migrations no server can still need), and point out any other dead code found on the way.
- Before writing a block that already exists elsewhere, reuse or extract the shared helper (`sources/functions/<file>`) rather than copy it.
- Give each helper file a header line, and each shared function one line on its arguments and effect. Keep CONTRIBUTING ("Adding an application"), README and `box help` in line with the code.
