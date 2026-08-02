## Why

`D20.Game.Server` owns the generic Session runtime rather than game rules, so its current namespace places the runtime seam under the wrong owner. Its recently added public `attach/2` and `detach/2` callbacks also duplicate `D20.Sessions` even though the context sends those calls directly to the registered Session process.

## What Changes

- Move the default `:gen_statem` runtime implementation from `D20.Game.Server` in `lib/d20/game/server.ex` to `D20.Sessions.Server` in `lib/d20/sessions/server.ex`.
- Make `D20.Game` select `D20.Sessions.Server` by default and update repository custom Session servers to `use D20.Sessions.Server`.
- Keep attachment and detachment as shared internal `handle_event/4` behavior executed by the Session process.
- Remove `attach/2` and `detach/2` from the server behaviour, generated custom-server delegates, public server wrappers, and overridable interface; keep `D20.Sessions.attach/1` and `detach/2` as the only caller-facing attachment interface.
- Update architecture guidance, durable runtime specifications, and focused contract tests without adding a compatibility alias for `D20.Game.Server`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `game-server-runtime`: Rename the default and shared Session runtime contract and narrow its interface while preserving all runtime behavior.
- `workspace-web-boundary`: Attribute Session projection publication and Workspace invalidation to `D20.Sessions.Server`.
- `session-workspace-lifecycle`: Attribute shared attachment and publication handling to the renamed Session runtime module.

## Impact

- Tracking issue: GitHub issue #186, `Move Default Session Runtime Server Under Sessions`.
- Backend: `D20.Game`, the moved default server module, custom server modules, server contract tests, and every repository-local reference to `D20.Game.Server`.
- Public runtime seam: callers continue to use `D20.Sessions`; repository custom servers must replace `use D20.Game.Server` with `use D20.Sessions.Server`.
- Runtime behavior: process registration, attachment ownership, Presence, dispatch, publication, timers, restart semantics, and error shapes remain unchanged.
- Public protocols, iframe contracts, persistence, dependencies, and migrations: unchanged.
- Runtime compatibility: this is a compile-time module rename; a release rebuild and normal application restart load the new module, with no stored-data migration.
- Rollback: restore the old module name and server interface references; no data rollback is required.
