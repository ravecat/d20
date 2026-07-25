## Why

Workspace transport ownership is currently split between `D20.Sessions`, `D20.Game.Server`, and `D20Web.WorkspaceChannel`: the Sessions context owns actor PubSub details while the channel owns snapshot construction. Extracting one web boundary makes the notification and refresh flow explicit without changing runtime, channel, or client behavior.

## What Changes

- Add `D20Web.Workspace` as the web boundary for actor-scoped workspace subscription, session-discovery invalidation, and workspace snapshot construction.
- Keep authoritative runtime lookup and membership filtering in `D20.Sessions.list_runtime/1`.
- Keep socket callbacks, process monitors, replies, and client pushes in `D20Web.WorkspaceChannel`.
- Publish workspace discovery changes from `D20.Game.Server` through `D20Web.Workspace` after the existing direct SessionChannel publication.
- Remove workspace PubSub topics, subscriptions, and invalidation comparison from `D20.Sessions`.
- Preserve the `workspace` channel topic, join and snapshot payloads, `close` behavior, SessionChannel projection delivery, game commands, and all client contracts.

## Capabilities

### New Capabilities

- `workspace-web-boundary`: Defines ownership and behavior for workspace PubSub invalidation and actor-specific snapshot construction in the Phoenix web layer.

### Modified Capabilities

None. This is a behavior-preserving refactor of the existing workspace and session lifecycle contracts.

## Impact

- Affects `D20.Game.Server`, `D20.Sessions`, `D20Web.WorkspaceChannel`, a new `D20Web.Workspace` module, and focused backend tests.
- Does not change database schemas, runtime supervision, Session or game state, Phoenix channel events, payloads, AsyncAPI contracts, iframe bootstrap data, or client code.
- Rollback is the checkpoint commit `7811eb5`, which contains the complete pre-refactor backend implementation.
