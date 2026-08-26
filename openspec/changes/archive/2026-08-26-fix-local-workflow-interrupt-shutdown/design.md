## Context

`just up` currently places Concurrently, Watchexec, IEx/Phoenix, Storybook, and nested filesystem watchers in one foreground workflow. A terminal interrupt reaches several process trees as `SIGINT`. IEx opens the Erlang BREAK handler while Concurrently walks its child trees, and Phoenix LiveReloader can leave an asynchronous `inotifywait` child holding a supervised pipe open.

An attempted fix added a Bash process-group boundary, signal traps, and explicit supervisor waiting. Those parts make the root `justfile` responsible for process supervision details before the project has selected a maintained supervisor. Its exact-name EPMD routing solves a separate repeated-start problem and remains useful without the custom signal supervisor.

The requested baseline is the earlier sequential application workflow: `just up` starts detached Docker Compose services and then invokes the interactive `serve` workflow. Storybook remains independently useful and receives a dedicated root entry point, but it is no longer coupled to application startup.

## Goals / Non-Goals

**Goals:**

- Restore the smallest established process tree for routed application development.
- Keep Docker Compose startup before the interactive Watchexec and IEx/Phoenix workflow.
- Start Storybook through a separate, discoverable root command with argument forwarding.
- Preserve repeated `serve` behavior by routing an exact registered node name to its existing Watchexec owner.

**Non-Goals:**

- Select or configure the final maintained parallel process supervisor.
- Guarantee that one Ctrl+C bypasses the standalone IEx BREAK handler.
- Force-stop or unregister an arbitrary Erlang node through EPMD.
- Stop detached Docker Compose services when the foreground application command exits.
- Automatically install dependencies or run database migrations during watched restarts.
- Change production startup, persistence, public protocols, or game-module behavior.

## Decisions

### Restore sequential `up`

The `up` recipe runs `docker compose up -d` and then `just serve`, matching the workflow that preceded combined Storybook startup. It does not invoke Concurrently, create background jobs, install signal traps, or interpret process exit codes itself.

When the requested node is absent, this makes Watchexec and IEx/Phoenix the only foreground application tree owned by `up`. When the exact node is already registered, `serve` triggers its existing watcher and `up` returns without acquiring that process tree. Docker Compose remains detached and retains its established explicit `docker compose down` shutdown boundary.

Remove Concurrently from the Nix development shell because no retained command invokes it. The pinned Nixpkgs input remains unchanged.

Keeping the Bash signal wrapper was rejected because it is a custom supervisor. Keeping the direct Concurrently invocation was rejected because it reproduces the terminal-retention failure. Selecting another parallel supervisor is deferred until the simplified tree is characterized.

### Make public `serve` restart or start

The public `serve` recipe inspects `epmd -names` for the exact requested short node name. When that name is registered, it touches the active `config/${MIX_ENV:-dev}.exs` file. The existing Watchexec process observes that file and restarts its IEx/Phoenix child. The public command then exits instead of attempting to own or signal the existing process tree.

When the requested name is absent, `serve` delegates to the private `start` helper. The helper runs `mix setup` once and then replaces its shell with the retained Watchexec command and interactive IEx/Phoenix child. Both recipes preserve the existing `--sname` and `--erl` arguments and the complete `envs/` and `config/` watch roots.

Dependency declarations, the dependency lockfile, and migration files remain outside the watch roots. Developers install changed dependencies through `mix deps.get`, run pending migrations through `mix ecto.migrate`, and invoke `just serve` when the existing watcher should restart afterward. This keeps full `mix setup` on the initial-start path instead of running dependency, database, seed, and asset setup as a side effect of every configuration restart.

EPMD is used only for discovery. `serve` does not call `epmd -stop`, kill a registered node, or claim ownership of a process it did not start. Exact field matching avoids treating a partial node-name match as the requested workflow.

### Expose Storybook independently

Add a public `storybook` recipe that delegates to the existing atomic frontend Storybook command and preserves optional argument boundaries. It starts neither Docker Compose nor Phoenix, so contributors can run it in a separate terminal only when isolated component work requires it.

This recipe is an intentional exception to the root convention that named recipes compose multiple actions. Storybook is a supported contributor entry point with its own argument contract, comparable to the generic asset dispatcher but more discoverable for the catalog workflow. Adding artificial setup work merely to satisfy the composition rule was rejected.

## Risks / Trade-offs

- [Phoenix and Storybook no longer start together] -> Document the two foreground commands and keep Storybook optional for isolated component work.
- [A different process owns the requested registered node name] -> Only trigger the watched configuration path and never force-stop the node; document that reuse assumes the node belongs to this repository's Watchexec workflow.
- [EPMD output changes incompatibly] -> Keep the parser limited to the documented `name <name> at port <port>` records and cover exact, partial, custom, and missing-name routing with command probes.
- [Dependency or schema changes need an explicit preparation command] -> Document the corresponding Mix command and reuse `just serve` only as the runtime restart boundary.
- [Standalone IEx still handles Ctrl+C interactively] -> Characterize and document that behavior separately instead of masking it with root-level signal code.
- [The Storybook recipe weakens the composite-recipe convention] -> Record it as a narrow supported-tool exception and keep its implementation delegated to the existing asset command.

## Migration Plan

1. Restore sequential `up` composition and make public `serve` route between existing-watcher restart and private initial startup.
2. Remove the unused Concurrently package and add the independent `storybook` recipe with argument forwarding.
3. Update contributor documentation and validate command discovery and dry-run order.
4. Characterize the real sequential process tree before proposing another supervisor. No data, deployment, or runtime migration is required.

## Open Questions

None.
