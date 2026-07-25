## Why

Workspace discovery currently treats Phoenix Presence as session participation and directly couples `D20.Game.Server`, `D20Web.Presence`, and `D20Web.WorkspaceChannel`. A transport disconnect can therefore remove a participant, break reload recovery, and require a Presence handoff protocol between Lobby and Workspace.

## What Changes

- Make `session.members` the durable runtime participation set, with each member carrying an `online` or `offline` transport status.
- Let SessionChannel resolve trusted profile data into server-owned Presence metadata without directly mutating Session membership.
- Let Presence online add or refresh a Session member, while final Presence leave marks that durable member offline without removing membership or changing the game roster.
- Keep game `join` and `left` commands independent from Session membership so game engines own player state.
- Make Workspace `close` the explicit actor-scoped operation that removes membership and updates every actor WorkspaceChannel.
- Publish Session state directly from the runtime process to the existing SessionChannel topic, publish actor discovery changes through `D20.Sessions`, and keep Presence subscription and publication inside `D20Web.Presence`.
- Remove `handoff_ready`, the temporary Lobby Presence lease, and Presence-driven Workspace invalidation.
- Restore live in-progress Workspace windows from durable runtime membership after a full document reload.
- Keep Session processes under `D20.Sessions.Supervisor`; do not introduce an actor Workspace process or make Workspace own shared sessions.
- **BREAKING**: session projection member objects gain a required `status` field, and Workspace descriptors remove `handoff_ready`.

## Capabilities

### New Capabilities

- `session-workspace-lifecycle`: Durable session participation, transport Presence status, explicit Workspace close, reload recovery, and one-directional runtime-to-web publication.

### Modified Capabilities

None. There are no synchronized main specifications under `openspec/specs/`. This change supersedes the Presence-membership and Lobby handoff decisions in the unarchived `add-multi-session-game-workspace` change.

## Impact

- Backend changes affect `D20.Sessions`, `D20.Sessions.Session`, the shared game server, Presence normalization, SessionChannel, WorkspaceChannel, and their focused tests.
- Frontend changes affect the Lobby lifecycle, workspace store and channel types, session member rendering, and focused Svelte and TypeScript tests.
- Public AsyncAPI session projections add member status, while Workspace descriptors remove `handoff_ready`.
- Existing game command names and game aggregate schemas remain compatible. Game `join` and `left` commands affect only game state. Workspace close uses a separate explicit member-removal operation.
- No database migration or new OTP supervisor is required. Runtime sessions remain volatile and continue to expire under the existing session timeout.
