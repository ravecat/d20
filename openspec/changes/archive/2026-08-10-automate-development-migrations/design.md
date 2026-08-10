## Context

`mix serve` provides the required self-contained setup plus server behavior, and `mix start` delegates to it for compatibility. The earlier `just serve` draft split that contract by running `mix setup` before `watchexec` and launching direct `phx.server` children. That prevents migrations from running on replacement but also means watched launches no longer use the established complete server command.

The intended safety boundary is narrower: migration files must not be watcher inputs. Initial and replacement children should continue to invoke `mix serve`, so environment and configuration changes deliberately rerun dependency, database, seed, and asset preparation. If a migration is pending when another watched input changes, setup may apply it.

## Goals / Non-Goals

**Goals:**

- Complete full project setup before Phoenix starts after direct or watched `serve` launches.
- Keep migration files outside automatic watcher inputs so editing a migration alone cannot execute it.
- Make `mix serve` the single startup implementation and preserve `mix start` as its compatibility alias.
- Preserve refreshed direnv values, IEx terminal input, argument boundaries, and watcher failure recovery.

**Non-Goals:**

- Guarantee that pending migrations remain unapplied across unrelated environment or configuration restarts.
- Automatically roll back, reset, drop, or reconstruct the development database.
- Make setup a Phoenix Endpoint watcher or change production release startup policy.
- Add state that distinguishes the watcher's initial child from replacement children.

## Decisions

### Compose full setup into the existing server Mix alias

The `serve` Mix alias runs `setup` before `phx.server`. Direct `mix serve` and compatibility `mix start` callers therefore receive the complete preparation contract from one alias boundary.

Duplicating the setup step list in `start` was rejected because delegation preserves one source of truth. A Phoenix Endpoint `watchers:` entry was rejected because Endpoint watchers start with the application and cannot provide setup-before-Endpoint ordering.

### Run the existing server alias inside the watcher

`just serve` starts `watchexec`, and every initial or replacement interactive child runs `mix serve`. The Just recipe does not duplicate `mix setup` or bypass the alias with direct `phx.server`, so changes to the complete startup contract remain centralized in `mix.exs`.

This intentionally means an environment or configuration event reruns setup and can apply an already pending migration. Splitting initial and replacement commands was rejected because the desired workflow is for every server launch to use the same complete alias.

### Preserve `start` as a compatibility alias

The existing `start: ["serve"]` alias remains unchanged. This retains the established command surface while ensuring callers of either alias receive the same setup-before-server behavior without duplicating the step list.

### Exclude migrations from watcher inputs

`watchexec` observes only `envs/` and `config/`. Creating, changing, renaming, or removing a path under `priv/repo/migrations/` does not by itself trigger setup or server replacement. A developer can apply the migration immediately through `mix ecto.migrate` or trigger the complete workflow through `just serve`, `mix serve`, or `mix start`.

### Let setup failure gate each Phoenix child

Initial and replacement children run the ordered `serve` alias, so a setup failure prevents `phx.server` from starting for that launch. The watcher remains responsible for launching another child after a later supported event.

## Risks / Trade-offs

- [Configuration restart finds a pending migration] -> Accept that full `mix serve` applies it; the protected boundary is that the migration edit alone is not a watcher trigger.
- [Every watched replacement repeats dependency, seed, and asset work] -> Accept the startup cost because all server launches are required to use the complete existing alias.
- [Future seeds may not tolerate repeated setup] -> Treat repeatability as part of the established setup contract; a seed failure gates that Phoenix child.
- [Migration edit does not restart a server that now needs the schema] -> Require `mix ecto.migrate` or another deliberate server workflow invocation.
- [Setup can apply forward migrations and seed changes to local data] -> Never invoke rollback, reset, or drop commands automatically.

## Migration Plan

1. Compose `setup` before `phx.server` in the existing `serve` Mix alias and retain `start` delegation.
2. Make the `just serve` watched child invoke `mix serve` without a separate pre-watcher setup.
3. Restrict watcher roots to `envs/` and `config/`.
4. Document migration-file exclusion and the fact that other watched events rerun full setup.
5. Validate command rendering, alias order, setup, and OpenSpec consistency.

Rollback restores the direct `phx.server` alias and previous watcher command. Any migration or seed change already applied through setup remains governed by its own rollback behavior and is not reversed by workflow rollback.

## Open Questions

None.
