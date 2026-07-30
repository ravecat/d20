## Why

Phoenix runtime and environment configuration is evaluated when the BEAM starts, so the development code reloader cannot apply changes to `envs/.env` or the active Elixir configuration. Developers currently have to stop and restart `just serve` manually, and a child-only restart would still inherit stale environment values from its parent process.

## What Changes

- Provide `direnv` and `watchexec` in the reproducible Nix development shell.
- Keep `mix setup` as the initial `serve` step, then run the interactive IEx/Phoenix process under a file watcher.
- Restart the development BEAM when `envs/.env`, shared configuration, runtime configuration, or the active `MIX_ENV` configuration changes.
- Re-evaluate `.envrc` for every watched restart so the replacement BEAM receives current environment values.
- Preserve direct IEx terminal input, Erlang argument boundaries, and the existing `serve` options while making `up` inherit the same behavior.
- Document the one-time direnv authorization and automatic restart behavior.

## Capabilities

### New Capabilities

- `development-runtime-restart`: Defines watched development configuration inputs, environment refresh, restart behavior, interactive IEx compatibility, and retained workflow ordering.

### Modified Capabilities

None.

## Impact

- Affected files: `flake.nix`, `justfile`, and `README.md`.
- Adds `direnv` and `watchexec` as development-shell tools without changing production release dependencies.
- Development restarts disconnect clients and discard non-persistent BEAM process state; no session, persistence, route, public API, iframe module, or database schema contract changes are introduced.
- Rollback restores the direct `iex ... -S mix serve` command, removes the two development-shell tools, and removes the matching documentation.
