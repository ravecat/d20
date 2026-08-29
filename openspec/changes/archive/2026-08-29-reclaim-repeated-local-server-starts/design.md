## Context

The old workflow retained the first terminal. The first replacement design used EPMD port discovery and authenticated `erl_call`, but local takeover only needs to stop the one BEAM process whose command line carries the requested short node name.

Both supported host families provide `pkill -f`: the Nix shell supplies procps on Linux, while macOS supplies the system utility. Watchexec already uses `--exit-on-error`, so force-stopping its child also retires the previous watcher.

## Goals / Non-Goals

**Goals:**

- Transfer the exact default or explicit short-name development runtime to the latest terminal.
- Preserve setup-before-takeover, foreground IEx, existing argument boundaries, and watched restarts.
- Use one established process command instead of custom discovery and RPC logic.

**Non-Goals:**

- Graceful OTP shutdown during local takeover.
- Production process management.
- PID files, a repository process script, or automatic dependency installation and migrations.

## Decisions

### Match the exact short-name BEAM with pkill

The recipe uses one full-command regular expression containing `beam.smp`, `-sname`, the requested name, and a trailing space. The trailing space prevents a request for `d20` from matching `d20_test`. The `[b]eam.smp` spelling prevents the command from matching its own shell text.

`pkill -9` force-stops the matching development BEAM without requiring its Erlang cookie or distribution port. No match is a normal first-start condition, so that status is ignored.

### Retire the previous watcher

Watchexec keeps `--exit-on-error`. The forced child exit makes the previous watcher terminate, while the latest invocation starts a fresh foreground watcher and IEx/Phoenix child.

A watcher started by the older touch-based recipe still requires one manual shutdown because it lacks `--exit-on-error`.

### Keep setup and watched restarts unchanged

`mix setup` remains before takeover. Watchexec continues to observe `envs/`, `config/`, `mix.exs`, and `mix.lock`; watched restarts run `mix serve` without full setup, dependency installation, or migrations.

## Risks / Trade-offs

- `SIGKILL` skips OTP shutdown callbacks. This is accepted only for the disposable local development server.
- Takeover depends on the stable BEAM argument shape produced by `iex --sname`.
- `--exit-on-error` also exits after genuine nonzero server failures; rerun `just serve` after correcting them.
- A manifest restart can fail before a new dependency is fetched; run `mix deps.get` and then `just serve`.

## Migration Plan

1. Stop a watcher started by the older touch-based recipe once.
2. Use `just serve` or `just up` normally.
3. Roll back by reverting the Just, Nix, README, and specification changes.

## Open Questions

None.
