## Context

`just serve` currently runs `mix setup` and then starts the named development node with `iex ... -S mix serve`. Phoenix reloads changed application modules, but Elixir configuration and operating-system environment values are established while the replacement VM starts. Restarting only the original child command without rebuilding its environment would also reuse the environment snapshot inherited by the long-running parent.

The workflow must remain interactive, retain its existing `sname` and Erlang argument options, work through both `serve` and `up`, and avoid repeating dependency, database, and asset setup after each watched change. The repository uses a Nix development shell and an authorized `.envrc` that loads the flake and optionally loads `envs/.env`.

## Goals / Non-Goals

**Goals:**

- Restart the development BEAM automatically when an input loaded during configuration or application startup changes.
- Recompute the child environment before every watched restart.
- Preserve the direct IEx prompt and exact Erlang argument boundaries.
- Run `mix setup` once per explicit `just serve` invocation rather than once per watched restart.
- Keep the workflow reproducible through the existing Nix shell and inherited by `just up`.

**Non-Goals:**

- Hot-update Elixir configuration inside a running VM.
- Change production release startup or supervision.
- Watch application source files already handled by Phoenix and Vite reloaders.
- Preserve in-memory process state or client connections across a development VM restart.
- Restart automatically for changes to dependencies, `mix.exs`, the Nix flake, or unrelated environment-specific configuration.

## Decisions

### Place the watcher after initial setup

`serve` runs `mix setup` before starting `watchexec`, and the watcher owns only `direnv exec . iex ... -S mix serve`. A matching change therefore replaces the BEAM and its Phoenix/Vite children without rerunning dependency resolution, database setup, Bun installation, or the production asset build.

Wrapping the whole `just serve` workflow was rejected because every configuration edit would repeat setup work that is unrelated to refreshing runtime configuration.

### Watch configuration directories with exact positive filters

The watcher observes `envs/` and `config/`, then admits only:

- `envs/.env`
- `config/config.exs`
- `config/runtime.exs`
- `config/${MIX_ENV:-dev}.exs`

Watching the containing directories instead of individual files detects creation, deletion, and editor-driven atomic replacement. Resolving the environment-specific path when `just serve` starts avoids restarting a dev server for `test.exs` while still supporting an explicitly selected `MIX_ENV`.

### Re-evaluate `.envrc` for every child

Every watcher launch executes the server through `direnv exec .`. This recalculates the authorized `.envrc`, uses the cached Nix environment when unchanged, and applies the current optional dotenv values to the new BEAM. Relying on the watcher process environment was rejected because a running process cannot receive later changes made to its parent shell environment.

Reading dotenv values directly in application code was rejected because it would duplicate direnv parsing, move development-shell concerns into the application, and still leave other startup configuration unchanged.

### Preserve argv and terminal ownership

Watchexec executes the child without an intermediate shell so the Erlang emulator option string remains one argument. It also runs the child without a separate process group so IEx remains in the terminal foreground group and can read stdin. The explicit restart mode sends termination to the direct child, which becomes the BEAM after `direnv exec` replaces itself.

The default shell and process-group behavior was rejected after it respectively lost the Erlang argument boundary and caused the interactive BEAM to be suspended with `SIGTTIN`.

### Override ignores only inside a narrow watch scope

The local dotenv file is intentionally ignored by Git, while watchexec normally honors discovered ignore files. The workflow disables ignore discovery but combines that with two narrow watch roots and exact positive filters, so unrelated ignored paths cannot trigger a restart.

### Provision watcher tools through Nix

`direnv` and `watchexec` are part of the existing development shell package set. This keeps the documented command reproducible instead of requiring untracked global installations. The packages remain development-only and do not affect the production image or release.

## Risks / Trade-offs

- [A watched restart disconnects clients and destroys non-persistent BEAM state] -> Limit the behavior to development, document it, and treat the restart as equivalent to a manual server restart.
- [Disabling process-group wrapping narrows forced child-tree cleanup] -> Keep the BEAM as the direct watched child and rely on Phoenix supervision and Port closure to stop development watchers during normal termination.
- [An invalid configuration prevents the replacement server from starting] -> Keep watchexec alive so the next matching edit can start another replacement process and expose the configuration error in the terminal.
- [Direnv refuses an unauthorized `.envrc`] -> Require `direnv allow` once in the documented setup flow and preserve direnv's authorization boundary.
- [Disabling ignore handling could admit noisy events] -> Restrict watches to `envs/` and `config/` and filter exact supported paths.

## Migration Plan

1. Add `direnv` and `watchexec` to the Nix development package set.
2. Wrap only the existing IEx/Phoenix command in the filtered watcher while preserving `mix setup` before it.
3. Document direnv authorization and watched restart behavior.
4. Validate Nix tool availability, Just command rendering, HTTP startup, interactive IEx input, updated dotenv loading, and replacement process identifiers for configuration changes.

Rollback restores the direct IEx/Phoenix command and removes the added Nix packages and documentation. No data migration or coordinated deployment is required.

## Open Questions

None.
