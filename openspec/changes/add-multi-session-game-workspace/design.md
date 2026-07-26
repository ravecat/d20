## Context

The shell can host several live games while Inertia replaces page content. A waiting session belongs to the game-page Lobby. An in-progress session belongs to the persistent workspace.

The old shared-prop and controller-transfer approach mixed:

- authoritative runtime membership;
- Lobby SessionChannel lifecycle;
- module iframe SessionChannel lifecycle;
- browser-local window presentation.

The resulting workspace could open a shell SessionChannel while the iframe opened another one. Presence changes then refreshed discovery and repeatedly disturbed the window.

## Goals

- Use current runtime state as the only workspace membership authority.
- Discover every eligible actor session in realtime.
- Keep waiting sessions page-owned and in-progress sessions workspace-owned.
- Keep the module iframe as the only owner of an in-progress game's SessionChannel.
- Preserve Presence across the short Lobby-to-iframe transition.
- Support multiple sessions and repeated slugs without recreating retained iframes.
- Make close remove the actor's session membership globally and keep presentation state browser-local.
- Keep windows visible as stale during temporary WorkspaceChannel loss.

## Non-Goals

- Persisting or restoring workspace presentation after a full document reload.
- Keeping finished sessions available for inspection.
- Moving game projections, game commands, or Presence onto WorkspaceChannel.
- Persisting runtime sessions or changing game engine contracts.
- Synchronizing Theater, Compact, focus, or order between tabs.

## Decisions

### 1. The root layout owns one persistent workspace

The root Inertia layout creates one workspace outside replaceable page content. It owns only descriptors and local presentation:

- entry order;
- Theater or Compact mode;
- focus;
- close progress and errors.

No workspace state is written to the URL or browser storage.

### 2. WorkspaceChannel owns discovery and shell lifecycle

The authenticated user socket exposes:

```text
workspace
```

The actor always comes from `socket.assigns.scope`. Join returns a complete snapshot and `snapshot` events replace the prior authoritative set.

WorkspaceChannel accepts one shell operation:

```json
{ "event": "close", "payload": { "id": "session-id" } }
```

It validates current membership, builds the actor-scoped session context, and dispatches the session `left` event. It rejects game commands.

The former Inertia shared prop, Workspace plug, and HTTP bootstrap endpoint are removed.

### 3. Eligibility comes from live runtime state

A descriptor is reported only when:

- the runtime process is alive;
- `session.phase == :in_progress`;
- `session.members` contains the current actor;
- the slug resolves to a configured module.

Ownership alone is insufficient. Waiting, finished, missing, and unconfigured sessions are excluded.

Each descriptor contains:

```json
{
  "id": "session-id",
  "slug": "game-slug",
  "handoff_ready": false,
  "module": {
    "embed_url": "https://game.example.test/",
    "allowed_origins": ["https://game.example.test"],
    "sandbox": ["allow-scripts", "allow-same-origin"]
  },
  "connection": {
    "endpoint": "wss://example.test/module",
    "topic": "session:session-id",
    "token": "fresh-actor-bound-token"
  }
}
```

Module bootstrap data is derived from the authenticated actor and the browser-facing user-socket
request URI. The production Endpoint enables SSL rewriting from the trusted forwarded scheme.
Phoenix runs that SSL handling before socket dispatch, so UserSocket receives and stores an
already-normalized public URI without reading proxy headers itself.

### 4. Accepted transitions and Presence invalidate snapshots

The shared game-server publication boundary invalidates the union of old and new member ids when phase or membership changes. This covers client commands, Presence-derived transitions, and automatic custom-server transitions.

Presence meta joins and leaves also invalidate that actor's workspace because they can change `handoff_ready` without changing eligibility.

Each WorkspaceChannel subscribes to an internal actor topic, rebuilds the full snapshot through `D20.Sessions`, and pushes it directly to its client. Duplicate invalidations are harmless.

WorkspaceChannel monitors every reported runtime pid. A `:DOWN` immediately rebuilds the snapshot.

### 5. The module iframe is the per-game realtime owner

The shell creates `Frame` from the descriptor and passes cloneable module bootstrap data through the SDK bridge. The loaded module iframe creates the only in-progress SessionChannel connection for that window.

That existing SessionChannel continues to own:

- caller-specific projections;
- game commands;
- command errors and timeouts;
- Presence;
- its own transport recovery.

The workspace store does not create, retain, transfer, or dispose a per-game SessionController. Descriptor refresh preserves the keyed window, iframe node, and SDK bridge.

### 6. Lobby handoff uses a server-observed Presence overlap

Lobby owns its normal session store only while the query-selected session is waiting.

After start:

1. the page hides Lobby, cleans the query URL, and returns to Play;
2. the Lobby store remains attached as a temporary Presence lease;
3. WorkspaceChannel reports the new in-progress descriptor;
4. the workspace mounts `Frame`;
5. the module iframe joins its SessionChannel and registers Presence;
6. Presence invalidates WorkspaceChannel;
7. the descriptor becomes `handoff_ready: true` when the actor has at least two metas;
8. the workspace detaches the temporary Lobby store.

No session controller moves from Lobby to workspace. No `presence_ready` event is added to SessionChannel.

Delayed Presence `left` messages carry connection refs, so leaving the old Lobby connection cannot remove a member already represented by a newer module connection.

### 7. Close globally removes actor membership

The window overlay has one close control. It calls WorkspaceChannel `close`, keeps the window mounted while the reply is pending, and waits for the next authoritative snapshot to remove it.

An accepted close removes the actor from `session.members`, so every WorkspaceChannel for that actor removes the window. The runtime is not stopped. A rejected or timed-out close keeps the window and exposes retry.

The dock does not duplicate close, Focus, Minimize, or Detach controls.

### 8. Reconciliation preserves retained windows

For every complete snapshot the workspace:

- retains entries with the same id and refreshes their descriptor;
- adds new ids without replacing repeated slugs;
- removes missing ids;
- preserves local mode and order for retained ids;
- releases a matching Lobby Presence lease when `handoff_ready` becomes true.

The iframe is keyed by session id and is not recreated by mode changes, navigation, or descriptor refresh.

### 9. Transport and reload behavior

During temporary WorkspaceChannel loss, existing windows stay mounted with a stale overlay. After reconnection, the new complete snapshot is applied immediately. Each iframe handles its separate module-socket recovery internally.

A full document reload destroys the JavaScript workspace and all browser connections. The new workspace renders only the new server snapshot. The design does not use browser storage to promise restoration.

### 10. Workspace has a separate AsyncAPI contract

`priv/specs/workspace.yaml` defines:

- authenticated join;
- complete join and pushed snapshots;
- descriptor and `handoff_ready` schemas;
- workspace `close` request and reply;
- channel errors and closure.

Game-specific AsyncAPI files continue to describe SessionChannel only and gain no shell lifecycle events.

## Risks and Tradeoffs

- Presence gap during start - prevented by retaining Lobby until `handoff_ready`.
- Duplicate SessionChannels - prevented by making the iframe the sole in-progress owner.
- Removed actor missing invalidation - prevented by notifying the union of old and new members.
- Missed PubSub notifications - recovered by complete join snapshots and reconnect.
- Actor data leakage - prevented by socket-derived identity and actor-specific internal topics.
- Global close races - reduced by server-authoritative membership and complete snapshots.
- Full reload may lose volatile membership after the final Presence `left` notification - accepted because restoration is outside scope.
- Registry visibility remains node-local - unchanged from the existing runtime architecture.
- The production Endpoint trusts the forwarded scheme only at the existing proxy boundary -
  production ingress must strip client-supplied forwarding headers and write the public scheme.

## Migration Plan

1. Add WorkspaceChannel discovery, close, Presence invalidation, and runtime monitoring.
2. Add socket-based module descriptor generation and the Workspace AsyncAPI contract.
3. Mount one persistent workspace in the root layout.
4. Render module frames directly from descriptors without shell SessionControllers.
5. Replace Lobby controller transfer with the `handoff_ready` Presence lease.
6. Remove shared props, HTTP bootstrap, obsolete controller lifecycle code, and SessionChannel lifecycle events.
7. Validate backend, frontend, contracts, and the real Koala browser flow.

Rollback restores the former shared-prop bootstrap path. No persisted data conversion is required.

## Open Questions

None for the initial behavior.
