## Why

Repeated `just serve` and `just up` invocations must transfer the requested local server to the latest terminal. The EPMD and `erl_call` implementation works, but it is too much process-management logic for a disposable development runtime.

Owning issue: [#244 - Developers Can Reclaim Repeated Local Server Starts](https://github.com/ravecat/d20/issues/244)

## What Changes

- Keep `mix setup` before takeover so setup failures preserve the running server.
- Provide `pkill` through procps on Linux and use the system utility on macOS.
- Force-stop only the BEAM command carrying the exact requested `-sname`, then start a fresh Watchexec and IEx/Phoenix tree in the invoking terminal.
- Keep `--exit-on-error` so the previous Watchexec retires after its child is force-stopped.
- Watch `mix.exs` and `mix.lock` alongside `envs/` and `config/` without repeating setup on watched restarts.
- Keep the implementation in `justfile` without a custom script, PID state, EPMD parsing, or Erlang RPC logic.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `development-runtime-restart`: repeated startup force-stops the exact short-name BEAM and transfers foreground ownership to the latest invocation.
- `project-command-interface`: `serve` and `up` retain their public surface while using the shorter takeover command.

## Impact

- Affected files: `flake.nix`, `justfile`, `README.md`, the matching authoritative specifications, and this change.
- Runtime behavior: repeated startup replaces the exact default or explicit short-name BEAM; configuration and dependency manifest changes restart the watched child.
- Local takeover uses `SIGKILL`, so it deliberately skips graceful OTP shutdown.
- Production releases, persistence, public protocols, game modules, and Storybook remain unchanged.
