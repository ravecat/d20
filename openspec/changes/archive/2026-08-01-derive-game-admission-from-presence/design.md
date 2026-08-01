## Context

Phoenix distinguishes the transport-level `phx_join` from application events pushed after a channel is joined. `D20Web.SessionChannel` already tracks every authorized actor with Phoenix Presence, and `D20Web.Presence` normalizes meta changes into `{:online, actor_id, attrs}` and final-meta `{:offline, actor_id}` messages consumed by the session runtime.

The current Lobby duplicates that server-observed connection by waiting for a ready projection, checking `waiting_for_players`, and pushing a second application event named `join`. The runtime then routes that command to the game engine. Presence `online` independently adds the same actor to `session.members`.

Durable Session membership and game player state must remain distinct. Membership drives Workspace discovery and survives transport loss. Game player state is governed by each engine's phase, capacity, identity, and idempotency rules. Existing engines already accept repeated setup joins for an existing player and treat active-phase joins as unchanged state, which provides the required reconnect behavior.

## Goals / Non-Goals

**Goals:**

- Make the server-observed Presence `online` event sufficient to attempt game admission.
- Keep the attempt inside the existing Session and engine command path without adding `Sessions.admit/1`.
- Serialize membership and game admission in the owning `:gen_statem` process and publish one final authoritative Session update.
- Retain an online member as a spectator when phase, capacity, or game rules reject admission.
- Remove client phase and retry state used only to send `join`.
- Keep reload, reconnect, multi-tab, and Lobby-to-iframe transitions safe.

**Non-Goals:**

- Treating transport disconnect as an intentional game `left` or Workspace close.
- Adding admission approval, locking, or invitations beyond the current possession-of-session-link policy.
- Introducing a new public Sessions API or a second admission state machine.
- Changing explicit `left`, Workspace `close`, or game-specific command semantics.
- Modifying separately delivered iframe game repositories in this change.

## Decisions

### Presence online applies membership before internal game admission

`D20.Game.Server` will first call `Session.online/3` and then attempt `Session.dispatch/3` with `%D20.Command{event: "join", actor_id: actor_id, attrs: attrs}` against the updated Session. Both operations run within one `handle_event/4` callback, so other calls and Presence messages cannot interleave between them.

If both operations succeed, the server stores and publishes the final Session once. If game admission returns an error, the server still stores and publishes the online membership update. The actor is therefore connected and visible as a Session member but absent from game player state, which is the existing spectator representation.

Alternative considered: add `Sessions.admit/1`. This adds a public operation for an event the runtime already receives and creates another caller-visible lifecycle path without improving serialization or engine authority.

Alternative considered: publish the membership update and enqueue an internal `join` as a second event. That exposes an avoidable intermediate projection and allows `start` or another command to interleave before admission.

### Presence offline remains status-only

Final-meta `offline` continues to call only `Session.offline/2`. It never constructs `left`, removes membership, or changes the game roster. An explicit domain action remains necessary for intentional departure because a channel can leave during reload, network loss, navigation, process restart, and normal Lobby-to-iframe replacement.

Alternative considered: map final Presence leave to game `left`. This reintroduces the coupling that previously removed players during transient transport changes and breaks durable Workspace recovery.

### Repeated online events rely on engine-level idempotency

Presence may emit `online` for another tab, a reconnect, and the iframe connection after Lobby. Every event may attempt the same internal `join`. Supported engines must preserve an existing player's state when that actor joins again and must leave active games unchanged for late or reconnecting actors.

Focused engine tests already cover this invariant. The change will retain or strengthen those tests where necessary and add runtime coverage proving that duplicate online messages neither duplicate nor reset a player.

Alternative considered: have the server inspect each game's player collection before dispatch. That would make the generic runtime depend on game state shape and bypass engine-owned admission rules.

### Client-sent join is removed from the declared public protocol

Lobby will subscribe immediately and react only to authoritative phase projections. The Session store will no longer expose `join()`, and `joinRequested` will be removed. AsyncAPI contracts will describe channel join as both Presence admission and game-admission attempt and will remove the separate `joinGame` operation and message.

The generic SessionChannel handler and public `Sessions.dispatch/3` remain game-agnostic. They are not given a special `join` rejection branch. This preserves rolling compatibility for separately delivered clients that temporarily send a duplicate legacy `join`, while the declared protocol and first-party shell stop requiring it.

### Ordering follows the session process mailbox

Presence tracking occurs after the Phoenix channel join reply, so the reply may represent the Session before the connecting actor is admitted. The subsequent authoritative projection contains online membership and the result of game admission. UI permissions and start availability continue to follow projections, not the transport join reply alone.

If another actor starts the Session concurrently with a Presence admission, the session process mailbox decides the order atomically. Admission processed first may add a player; start processed first leaves the late actor as a spectator. No client-side phase check can provide stronger ordering than the authoritative process.

## Risks / Trade-offs

- [The initial channel reply can precede admission] -> Keep the existing projection push as the authoritative follow-up and test that admission arrives without a client command.
- [Duplicate Presence metas can repeat admission] -> Require idempotent existing-player joins and cover multi-meta or reconnect behavior at runtime and engine layers.
- [Admission rejection has no command reply] -> Preserve the online member and expose spectator permissions through the next projection; admission is implicit and non-blocking by design.
- [A legacy client sends explicit `join` after automatic admission] -> Keep engine joins idempotent and do not add a special channel rejection during the rollout.
- [A late join races with start] -> Accept mailbox ordering as authoritative and cover the invariant that state is never partially updated.
- [Contract removal affects separate iframe clients] -> Remove the operation from AsyncAPI, document the coordinated client change, and preserve temporary server compatibility.

## Migration Plan

1. Add runtime and channel tests for automatic admission, rejection-to-spectator fallback, duplicate online events, and offline retention.
2. Implement combined Presence online handling in `D20.Game.Server`.
3. Remove Lobby and Session store explicit join code.
4. Update all Session AsyncAPI contracts and validate them.
5. Deploy shell and server together. Separately delivered iframe clients may remove legacy `join` before or after this deployment because duplicate admission remains idempotent.

Rollback restores the Session store `join()` method, Lobby request guard, and AsyncAPI operation. Presence online handling can be reverted independently without changing stored schemas or durable Session membership behavior.

## Open Questions

None.
