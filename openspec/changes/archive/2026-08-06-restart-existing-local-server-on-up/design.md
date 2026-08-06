## Context

`just up` starts Docker Compose routing and delegates to `just serve`. The watched server uses the fixed short node name `d20`, so starting another watcher competes for the same Erlang distribution name. The existing watcher already knows how to terminate and replace its BEAM child when a configured startup input changes.

The desired workflow is therefore reuse-or-start: when EPMD reports the exact local `d20` node, emit a watched configuration event and let the existing watcher replace its child; otherwise start a new foreground `serve` workflow. This avoids OS process matching and leaves restart timing under `watchexec` ownership.

The watcher currently observes the `envs/` and `config/` directories but filters events through an explicit list of known startup files. Configuration changes are infrequent, while each new runtime input would require maintaining that list. The directory boundaries are already narrow enough that occasional extra development restarts are preferable to missing a future input.

## Goals / Non-Goals

**Goals:**

- Reuse an existing watcher for the default `d20` development node.
- Start `serve` normally when no `d20` node is registered.
- Match the exact node name without confusing it with names such as `d20_test`.
- Keep the conditional logic out of the public `up` recipe body and command listing.
- Treat every path below `envs/` and `config/` as a development restart input without future filter maintenance.
- Preserve Linux and macOS compatibility without new process-control packages.

**Non-Goals:**

- Transfer the existing watcher's IEx prompt or logs to the new terminal.
- Take over an arbitrary `d20` node that was not started by this watcher workflow.
- Repair multiple watcher instances that already compete for the same node.
- Add a process manager, PID-file protocol, public restart recipe, or production behavior.

## Decisions

### Use a private reuse-or-start helper recipe

The public `up` workflow keeps its two meaningful actions: start Docker Compose routing, then delegate local server ownership to a private `restart-or-serve` helper. The helper checks current Erlang registration and performs exactly one branch. Marking it private keeps the public recipe list unchanged.

A Just alias was rejected because aliases only expose another recipe under an additional name and cannot contain conditional shell logic. Inlining the condition in `up` was rejected because the requested helper makes the workflow easier to read without adding a public single-action recipe.

### Detect the exact default node through EPMD

The helper runs `epmd -names` and uses a portable whitespace-delimited `grep` expression for the exact `d20` token. EPMD is the registry responsible for the node-name conflict, so this checks the relevant condition without scanning operating-system process command lines. Names such as `d20_test` do not satisfy the expression.

Starting a separate Elixir VM to call `net_adm:names/1` was rejected because it adds substantially more command machinery for a local conditional. Matching `watchexec` or `beam.smp` with `pgrep` was rejected because it couples the workflow to process command-line rendering and requires additional Linux Nix tooling.

### Trigger the existing watched configuration input

When `d20` is registered, the helper updates the modification time of `config/${MIX_ENV:-dev}.exs`. That file is inside the watched `config/` directory, including the existing `dev` default. `watchexec` then performs its normal restart sequence and owns child termination before replacement.

Adding a synthetic marker file was rejected because it would expand the watcher configuration and create another runtime artifact. Sending `SIGHUP` to `watchexec` was rejected after validation showed that the installed version forwards the signal to the child without starting another run.

### Watch configuration directories without file filters

The watcher retains `--watch envs --watch config` and `--ignore-nothing`, but removes the positive `--filter` arguments. Any created, modified, replaced, renamed, or removed path within either directory can therefore replace the development process. This automatically covers future runtime and environment inputs without changing the command.

Keeping the explicit allowlist was rejected because configuration edits are rare and an occasional unnecessary development restart has low cost. `--ignore-nothing` remains necessary for the Git-ignored `envs/.env`; its broader consequence that ignored or temporary files can also trigger replacement is accepted.

### Start `serve` only when no node is registered

If EPMD does not list the exact `d20` name, the helper invokes `just serve` in the current terminal. A subsequent `just up` sees the registered node and emits only the restart event, preventing normal repeated use from accumulating watcher instances.

## Risks / Trade-offs

- [The registered `d20` node is not owned by the expected watcher] -> Document the local workflow ownership assumption; the helper emits a harmless configuration event but cannot force an arbitrary node to restart.
- [Several legacy watchers already exist] -> Require one-time manual cleanup before relying on reuse-or-start behavior; future invocations do not create another watcher while `d20` remains registered.
- [The new invocation does not own the existing terminal] -> Treat restart as a request to the already-running development workflow; use the original terminal for IEx and logs.
- [The human-readable EPMD listing changes] -> Match only the exact whitespace-delimited node token rather than the full line; keep the dependency limited to EPMD's documented names output.
- [A call occurs during the brief unregister/register interval] -> A second watcher could still start in that narrow interval; a process manager would be required for strict cross-invocation serialization.
- [An unrelated or temporary file changes below a watched directory] -> Accept the extra development restart in exchange for eliminating filter maintenance and automatically covering future configuration inputs.

## Migration Plan

1. Replace process termination in `up` with the private reuse-or-start helper.
2. Remove the now-unneeded conditional `procps` development dependency.
3. Remove the per-file watcher filters while retaining the two directory watch roots.
4. Validate private recipe visibility, exact-name matching, command rendering, directory-wide restart scope, and supported flake evaluation.

Rollback restores the previous `up` delegation and removes the private helper. No migration, deployment coordination, or data rollback is required.

## Open Questions

None.
