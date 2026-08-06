## Why

The fixed `d20` Erlang node name prevents a second `just up` invocation from starting when the watched local server is already running. The routed workflow should reuse the existing watcher and ask it to restart its BEAM child instead of creating a competing watcher or requiring manual process termination.

Tracked by [GitHub issue #195](https://github.com/ravecat/d20/issues/195).

## What Changes

- Add a private Just helper that chooses between restarting the existing watched `d20` node and starting `serve` when no such node is registered.
- Detect the exact local `d20` Erlang node through the EPMD name listing.
- Trigger the existing `watchexec --restart` workflow by updating the active environment configuration file it already watches.
- Watch the complete `envs/` and `config/` directories without maintaining a per-file allowlist, so future configuration inputs automatically trigger replacement.
- Keep the existing Docker Compose startup first and avoid adding OS-specific process-control dependencies.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `development-runtime-restart`: Reuse an existing watcher for the default `d20` Erlang node and broaden replacement inputs from selected files to the complete configuration directories.
- `project-command-interface`: Preserve `up` as a composite workflow while delegating its server action to the private reuse-or-start helper instead of unconditionally invoking `serve`.

## Impact

- Affects only the root `justfile` development workflow and its specification.
- Uses Erlang's existing `epmd` tool plus portable shell, `grep`, and `touch` commands already available in supported Linux and macOS development environments.
- Does not affect production startup, persistence, public APIs, routes, session protocols, or iframe module contracts.
- Rollback restores the previous `up` recipe; no data or migration rollback is required.
