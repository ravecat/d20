## Why

The shell needs a persistent workspace for every live game session in which the current actor participates. Inertia page props are request-time data, so they cannot be the realtime authority for workspace membership. Passing a page-owned session controller into the workspace also couples Lobby lifecycle to global window lifecycle and can create duplicate SessionChannel connections beside the module iframe.

An actor-authenticated WorkspaceChannel makes current runtime state the only source of workspace membership. The module iframe remains the sole owner of each in-progress game's SessionChannel.

## What Changes

- Add one actor-scoped WorkspaceChannel to the authenticated user socket.
- Return a complete workspace snapshot on join and push complete replacements after relevant phase, membership, Presence, or runtime changes.
- Include only live `in_progress` sessions whose current `members` contains the actor. Waiting and finished sessions are excluded.
- Include configured module bootstrap data and a `handoff_ready` flag in every descriptor.
- Keep `waiting_for_players` presentation and its session store on the query-selected game page.
- Reset the page to Play after start while retaining the Lobby channel only until the module iframe Presence overlaps it.
- Let each module iframe own its existing SessionChannel, projections, commands, and Presence. The shell does not create a second per-game session controller.
- Make WorkspaceChannel the only source of workspace membership and the endpoint for the shell-level `close` action used by the window close control.
- Remove the Inertia shared sessions prop, dedicated Workspace plug, separate HTTP bootstrap endpoint, controller transfer, and browser storage.
- Keep existing windows mounted with a stale loading state while WorkspaceChannel reconnects, then apply its new authoritative snapshot.
- Monitor reported runtime processes and remove terminated sessions immediately.
- Keep Theater, Compact, focus, and ordering as browser-tab-local presentation.
- Publish a separate AsyncAPI contract for WorkspaceChannel. Game-specific SessionChannel contracts remain unchanged.

## Capabilities

### New Capabilities

- `multi-session-game-workspace`: Actor-scoped realtime discovery, persistent multi-session presentation, Presence-safe Lobby handoff, global close, and failure handling.

### Modified Capabilities

None. There are no synchronized main specifications under `openspec/specs/`.

## Impact

- Backend changes affect `D20.Sessions`, game-server publication, Presence notifications, the user socket, WorkspaceChannel, runtime monitoring, and module descriptor generation.
- Frontend changes affect the persistent layout, workspace store, Lobby, game windows, and removal of controller adoption and shared-prop reconciliation.
- The public shell protocol gains `priv/specs/workspace.yaml`, including snapshots, `handoff_ready`, and the workspace `close` operation.
- The iframe SDK bootstrap shape and game-specific commands and projections do not change.
- No database migration, game aggregate migration, role-model change, persisted actor workspace, or iframe client change is required.
- Runtime sessions remain volatile and subject to existing Presence and idle-timeout behavior.
