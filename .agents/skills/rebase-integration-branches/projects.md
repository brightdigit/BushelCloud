# BushelCloud config

| Key | Value |
|-----|-------|
| Container root | Parent of worktree dirs (contains `.git`, `BushelCloud.git/`) |
| Bare store | `BushelCloud.git` |
| `RELEASE_BRANCH` | `v1.0.0-alpha.3` |
| `MAIN_BRANCH` | `main` |
| `MISTKIT_REF` | `v1.0.0-beta.4` |
| `KIT_PACKAGE` | `BushelKit` |
| `KIT_PATH` | `../BushelKit` |
| Primary workflow | `.github/workflows/BushelCloud.yml` |
| Build binary workflow | `.github/workflows/bushel-cloud-build.yml` |
| CloudKit sync action | `.github/actions/cloudkit-sync/action.yml` |
| MistKit path (if used) | `../..` (monorepo: `Examples/BushelCloud`) |

## Expected commit counts

- `v1.0.0-alpha.3` is typically 1 commit ahead of `main`
- `mistkit` / `subrepo` should be 1 commit ahead of release, 2 ahead of `main`

## Backup branches

`backup/mistkit-pre-squash`, `backup/subrepo-pre-squash`

## CelestraCloud variant

Copy this skill folder to CelestraCloud and adjust:

| BushelCloud | CelestraCloud |
|-------------|---------------|
| `BushelKit` | `CelestraKit` |
| `BushelCloud.yml` | `CelestraCloud.yml` |
| `bushel-cloud-build.yml` | check for `update-feeds.yml` |
| `v1.0.0-alpha.3` | discover release branch (e.g. `v1.0.0-dev.1-mistkit`) |
