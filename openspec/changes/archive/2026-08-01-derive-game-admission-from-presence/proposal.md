## Why

Lobby currently sends an explicit game `join` command after its SessionChannel becomes ready, even though the server already receives the authoritative actor connection through Phoenix Presence. This duplicates lifecycle policy in the client and makes admission depend on a client-side phase check instead of the session runtime and game rules.

## What Changes

- Treat a normalized Presence `online` event as an automatic attempt to admit the actor into game player state through the existing internal `join` command.
- Keep Presence admission and Session membership server-owned: the game engine continues to decide whether the actor becomes a player or remains a spectator.
- Keep normalized Presence `offline` status-only so reloads, temporary socket loss, multiple tabs, and Lobby-to-iframe transitions do not remove durable membership or game player state.
- Remove the Lobby-owned `joinRequested` flow and the `join` method from the shared frontend Session store.
- **BREAKING**: remove the client-sent game `join` operation from the public SessionChannel AsyncAPI contracts. The internal `join` command remains part of the session-to-engine protocol.
- Preserve the explicit game `left` command and Workspace membership removal as separate intentional operations.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `session-workspace-lifecycle`: Presence `online` now updates durable membership and attempts game admission, while Presence `offline` remains transport status only and Lobby sends no explicit game `join` event.
- `game-server-runtime`: the shared runtime applies Presence membership and internal game admission as one serialized server transition, retaining membership when admission is rejected.
- `koala-server-runtime`: Koala inherits the shared Presence-driven admission behavior without disturbing its roll-state timeout.

## Impact

- Tracking issue: `ravecat/d20#26`.
- Backend changes affect `D20.Game.Server` Presence handling and focused runtime and channel tests. No new public `D20.Sessions` function is introduced.
- Frontend changes affect `assets/js/shared/stores/session.ts` and `assets/js/shared/components/lobby.svelte`.
- Public AsyncAPI changes affect Qwinto, Koala Rescue Club, and Next Station London session contracts. Separate iframe clients must stop sending `join`; duplicate legacy sends remain safe during a coordinated rollout because engine admission is idempotent.
- No database migration or dependency change is required. Rollback restores explicit Lobby `join` and the previous AsyncAPI operation while leaving durable Presence membership semantics intact.
