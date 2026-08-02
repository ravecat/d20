## Why

Workspace currently discovers a Session solely because the actor remains in `session.members`. Explicit Close stops the actor's channels and makes the member offline, but ordinary discovery still returns that Session, so a later snapshot restores a window the actor intentionally closed.

Deleting the member would lose identity and game data required by projections. Workspace attachment therefore needs its own process-lifetime relationship, independent from both retained Session membership and transient Presence status.

## What Changes

- Add `D20.Sessions.Registry`, a duplicate-key process Registry that indexes active Workspace attachments as `actor_id -> {session_pid, session_id}`.
- Keep the existing unique `D20.Registry` unchanged for `session_id -> Session process` naming through `:via`.
- Add serialized `D20.Sessions.attach/1` and `detach/2` lifecycle operations implemented by every game server so the Session process owns its actor attachment registrations.
- Attach after an authenticated SessionChannel join succeeds; ordinary disconnect and `offline` Presence SHALL retain the attachment.
- Make explicit Workspace Close detach the actor from the selected Session before stopping every matching actor SessionChannel; retain the member as `offline`, preserve profile and game state, and keep the shared runtime alive.
- Reattach after a later successful direct SessionChannel join and invalidate every active Workspace for that actor so the Session returns everywhere.
- Replace the current all-runtime scan in `D20.Sessions.list/1` with actor-indexed lookup through `D20.Sessions.Registry`.
- Keep the public member status enum as `online | offline` and preserve existing Workspace and Session message shapes.

## Capabilities

### New Capabilities

- `session-actor-registry`: Process-owned actor-to-Session attachment indexing, lifecycle, cleanup, and lookup.

### Modified Capabilities

- `session-workspace-lifecycle`: Separate durable member data and Presence status from explicit Workspace attachment.
- `workspace-web-boundary`: Build snapshots from actor attachment lookup and coordinate attach and detach invalidation.
- `multi-session-game-workspace`: Persist Close by removing only the selected actor-to-Session attachment and restore it through direct re-entry.
- `finished-session-workspace-access`: Apply the same attachment lifecycle to finished Session results.
- `game-server-runtime`: Serialize attach and detach inside default and custom Session processes without issuing game commands.

## Impact

- Tracking issue: GitHub issue #184, `Closed Session Cannot Be Reopened in the Same Workspace Lifetime`.
- Backend: the application supervision tree, new `D20.Sessions.Registry`, `D20.Sessions`, `D20.Game.Server`, Workspace discovery and invalidation, SessionChannel and WorkspaceChannel coordination, and focused tests.
- Frontend: existing authoritative snapshot reconciliation remains; no browser-local closed-id set or persistence is added.
- Public protocols: payload shapes and `online | offline` member statuses remain compatible; Workspace AsyncAPI descriptions and behavior tests require updated Close and re-entry semantics.
- Persistence and dependencies: no database migration or dependency change; both Session runtime and attachment index remain local and volatile.
- Runtime compatibility: registrations are created by future successful SessionChannel joins; live processes present during a hot code upgrade would require reattachment through their next successful join.
- Failure behavior: the new Registry is supervised before dynamic Sessions; Session registrations are process-owned and disappear automatically when the Session process terminates.
- Rollback: remove the attachment Registry and lifecycle calls and restore membership-based discovery; no stored-data rollback is required.
