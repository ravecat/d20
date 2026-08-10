## Context

Before commit `0e5b9e0`, `just serve` ran `mix setup` as one operating-system process and then started a watcher whose interactive child ran the `serve` Mix alias. That alias delegated directly to `phx.server`, so Phoenix enabled endpoint serving before D20 started.

Commit `0e5b9e0` moved setup into the `serve` alias so watched replacements could apply pending migrations. The setup alias runs seeds through `mix run`, which starts D20 and its Endpoint before `phx.server` enables endpoint serving. Because both tasks now share one Erlang VM, the later server flag does not add a Bandit listener to the already started Endpoint.

The workflow must restore a usable local server, retain interactive IEx and config-driven replacement, and preserve the user's unrelated README edit. GitHub issue #208 tracks the regression.

## Goals / Non-Goals

**Goals:**

- Complete full setup once before the development watcher starts.
- Start every watcher child in a fresh Erlang VM through the existing `serve` alias.
- Keep the watcher limited to `envs/` and `config/` changes.
- Keep direct `mix serve` and compatibility `mix start` usable as server-only commands.
- Ensure the initial `just serve` launch exposes HTTP on the configured port.

**Non-Goals:**

- Automatically install dependencies changed after the watcher has started.
- Automatically execute migrations when configuration changes restart Phoenix.
- Watch migration, dependency manifest, application source, or asset source paths in the outer watcher.
- Change production startup, database migrations, public protocols, or application behavior.

## Decisions

### Restore the operating-system process boundary around setup

`just serve` runs `mix setup` before it starts `watchexec`. The setup process may start D20 while running seeds, but that application terminates when the setup process exits. The watcher then launches `iex -S mix serve` in a new Erlang VM where `phx.server` enables endpoint serving before D20 starts.

Running `setup` through `mix cmd` inside the server alias was rejected because it obscures the process boundary inside Mix and makes the server alias responsible for environment preparation. Enabling the Endpoint server unconditionally in development was rejected because ordinary `mix run` and setup commands would unexpectedly bind the HTTP port.

### Keep the server Mix aliases narrow

The `serve` alias delegates directly to `phx.server`, and `start` continues to delegate to `serve`. This preserves one server implementation without coupling direct server startup to dependency installation, migrations, seeds, or production asset builds.

### Repeat only Phoenix startup on watched configuration changes

The watcher continues to observe only `envs/` and `config/`. A supported change replaces the interactive Phoenix child through `mix serve` but does not rerun setup. Developers deliberately rerun `just serve`, `mix setup`, or the focused task when dependencies, migrations, seeds, or built assets need preparation.

Automatic dependency-manifest watching was rejected because the requested workflow considers configuration changes sufficient and favors the previous predictable restart boundary.

## Risks / Trade-offs

- [A dependency changes while the watcher is running] -> The developer restarts `just serve`, whose initial setup fetches Elixir and frontend dependencies before starting a new watcher.
- [A migration becomes pending while the watcher is running] -> Configuration restarts do not apply it; the developer runs `mix ecto.migrate` or restarts `just serve` deliberately.
- [Initial setup takes longer than a server-only launch] -> Accept the existing full setup cost once per `just serve` invocation rather than on every watched replacement.
- [Setup fails] -> Sequential Just recipe execution prevents the watcher and Phoenix child from starting.

## Migration Plan

1. Restore the server-only `serve` Mix alias.
2. Restore the separate `mix setup` command before the watcher in `just serve`.
3. Update development startup documentation and the runtime restart specification.
4. Verify alias rendering, watcher command composition, a real HTTP response, and config-triggered replacement.

Rollback reapplies setup inside the `serve` alias and removes the separate Just step, but that also restores the no-listener regression unless Phoenix startup semantics are changed independently.

## Open Questions

None.
