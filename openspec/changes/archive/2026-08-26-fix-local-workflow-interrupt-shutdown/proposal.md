## Why

Interrupting the Concurrently-based `just up` workflow can stop Phoenix and Storybook while leaving the foreground supervisor alive indefinitely. Restoring the earlier sequential workflow provides a simpler process tree from which shutdown and future parallel orchestration can be evaluated. The public server command must still reuse the existing Watchexec owner when its Erlang node is already registered, because starting a duplicate node fails and leaves the original workflow unchanged.

## What Changes

- Make `just serve` a restart-or-start entry point: inspect EPMD for the exact requested short node name, touch the active environment configuration when it exists, and otherwise delegate to the private `start` setup and Watchexec helper.
- Keep dependency installation and database migrations explicit instead of expanding watched restarts beyond runtime environment and configuration changes.
- Restore `just up` as the sequential composition of detached Docker Compose services followed by `serve`.
- Remove Concurrently, Storybook, and the custom Bash signal boundary from `just up`.
- Remove the now-unused Concurrently package from the Nix development shell.
- Add a dedicated `just storybook` entry point that starts the isolated catalog and forwards optional CLI arguments.
- Document that Phoenix and Storybook now run through separate foreground commands while a maintained parallel supervisor is evaluated.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `project-command-interface`: Restore sequential application startup, retain repeated-start watcher reuse, and add Storybook as an explicit atomic root-command exception.
- `storybook-component-catalog`: Start the catalog through `just storybook` instead of coupling it to `just up`.

## Impact

- Development command composition in `justfile`, the Nix development shell, and contributor documentation.
- Local process ownership for Docker Compose, Watchexec, IEx/Phoenix, and Storybook.
- No production runtime, database migration, public API, session behavior, persistence contract, or iframe module contract changes.
- Phoenix and Storybook require separate foreground commands until a parallel supervisor is selected.
- Tracks [GitHub issue #212](https://github.com/ravecat/d20/issues/212).
