## Why

The development `serve` alias currently starts D20 during setup before `phx.server` enables endpoint serving, leaving the interactive development process without an HTTP listener. Restoring the previous process boundary makes startup reliable while retaining the intentionally narrow environment and configuration restart scope.

## What Changes

- Restore `mix serve` as a direct `phx.server` alias, with `mix start` continuing to delegate to it.
- Run full setup once as a separate process before `just serve` starts the watcher.
- Keep replacement children limited to interactive Phoenix startup when files under `envs/` or `config/` change.
- Document that dependencies, database migrations, seeds, and the asset build run on initial `just serve`, while watched replacements do not repeat setup.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `development-runtime-restart`: Restore setup outside the watcher and require initial and replacement watcher children to start Phoenix without rerunning setup.

## Impact

- Changes the development command composition in `mix.exs` and `justfile`.
- Updates startup documentation in `README.md`.
- Does not change production startup, public APIs, persistence contracts, routes, session protocols, or iframe module contracts.
- Does not add, remove, or roll back database migrations; it changes only when existing setup and migration tasks run.
- Tracks GitHub issue #208 and corrects the regression introduced by #204.
