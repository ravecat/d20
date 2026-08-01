## Context

Phoenix Presence already tracks each SessionChannel process as one actor meta and emits normalized `online` and final-meta `offline` messages. D20 additionally stores the actor in `session.members` so temporary disconnects do not erase participation or game player state. Workspace Close currently bypasses that model by sending an actor-scoped command that deletes the member, even though the same visual action can also happen through browser-tab teardown and cannot reliably express durable leave intent.

The Workspace is mounted outside replaceable Inertia content, receives complete server snapshots, and owns iframe lifecycle. A dismissed iframe destroys its SDK bridge and embedded SessionChannel, which naturally updates Presence. Browser storage remains prohibited, and game-specific `left` commands remain available only where game rules intentionally expose them.

## Goals / Non-Goals

**Goals:**

- Make Presence `online` and `offline` the only generic Session membership lifecycle inputs.
- Remove explicit Session member deletion and the WorkspaceChannel close command.
- Make the window close control immediately dismiss only the current tab's iframe.
- Keep a dismissed id suppressed across replacement snapshots for the lifetime of that Workspace store.
- Restore all still-eligible member Sessions on Workspace remount or full reload.
- Preserve multi-tab correctness: one tab cannot mark an actor offline while another Presence meta remains.

**Non-Goals:**

- Removing or redefining game-specific `left` commands.
- Persisting dismissed windows in browser storage or on the server.
- Adding disconnect grace timers or durable Session persistence.
- Changing iframe bootstrap descriptors, SessionChannel topics, projections, or game rules.

## Decisions

### Workspace dismissal is local presentation state

`createWorkspace` keeps an in-memory collection of dismissed Session ids and filters complete server snapshots before exposing `WorkspaceState.sessions`. Activating Close adds the selected id and immediately unmounts its Svelte window, iframe, and SDK bridge. Later snapshots containing that id remain suppressed in the same Workspace instance.

This is preferred over mutating server membership because dismissal is a current-tab UI action. It is also preferred over browser storage because reload is an intentional recovery path for live memberships.

### Close does not write offline status

The close handler sends no WorkspaceChannel or Session command. Iframe teardown closes its SessionChannel; `D20Web.Presence` emits `offline` only when no metas remain. This preserves the invariant that transport status describes actual aggregate connections rather than UI intent.

Directly calling `Session.offline/2` was rejected because another tab or device can still be connected and would be incorrectly marked offline.

### Explicit membership removal is deleted end to end

Remove `Session.remove_member/2`, `Sessions.remove_member/1`, the game-server `{:remove_member, actor_id}` call, and WorkspaceChannel close handling. WorkspaceChannel's existing catch-all returns `unsupported_event` for legacy `close` calls just like other unsupported application events.

This reduces the generic Session API to Presence admission/status plus normal game dispatch and lifecycle operations. Game-specific `left` remains a domain command and never follows automatically from Workspace dismissal or transport disconnect.

### Presence status functions trust normalized actor identity

`Session.online/3` and `Session.offline/2` accept the actor id produced by the authenticated SessionChannel and normalized Presence pipeline. They do not repeat identity validation or expose `:invalid_identity`; their result is only the unchanged or updated Session wrapped in `{:ok, session}`.

Actor identity validation remains at the socket and command boundaries that accept external input. Repeating it inside Presence status mutation was rejected because these messages are server-produced and the `player_id()` type is already the internal precondition.

### Workspace close contract is removed

The internal Workspace AsyncAPI advances from `0.1.0` to `1.0.0` and removes the close operation, message, reply, payload, and error schemas. Join, complete snapshots, Phoenix system events, descriptor shapes, and authentication remain unchanged.

## Risks / Trade-offs

- [Dismissed games return after reload] -> This is intentional because dismissal is not durable leave; document and test remount behavior.
- [Legacy clients send `close`] -> WorkspaceChannel returns `unsupported_event`; update the first-party client and contract in the same change.
- [Server snapshots repeatedly contain dismissed ids] -> Filter them locally; the in-memory collection is bounded by Sessions encountered during one Workspace lifetime.
- [The user expects Close to abandon a game seat] -> Keep game-specific Leave as a separately named and rule-aware action; do not infer it from window chrome.
- [Offline projection is asynchronous] -> Treat Presence as authoritative and test final-meta normalization rather than forcing status during the click handler.

## Migration Plan

1. Add regression tests for local dismissal, snapshot suppression, remount restoration, and unsupported Workspace commands.
2. Remove backend member-removal APIs and update focused Session and Workspace tests.
3. Remove redundant identity validation from trusted Presence status functions.
4. Replace the frontend Workspace close call with local dismissal state and update component/model tests.
5. Remove the Workspace close protocol from AsyncAPI and validate the document.
6. Deploy shell backend and first-party assets together. No database or persisted-state migration is required.

Rollback restores the removed API, handler, client call, and AsyncAPI `0.1.0` contract. No data rollback is required.

## Open Questions

None. Durable game departure remains explicitly outside Workspace window dismissal.
