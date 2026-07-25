## Context

The current workspace implementation derives participation from active Phoenix Presence metadata. `D20Web.Presence` broadcasts `join` and final-meta `left` messages to the game server and directly invalidates WorkspaceChannel. The game server stores the latest Presence metadata in `session.members`, removes that member after final Presence loss, broadcasts projections to a SessionChannel topic, and directly invokes WorkspaceChannel invalidation.

This produces three coupled lifecycles:

- browser connections determine durable session participation;
- Lobby must retain a SessionChannel until the module iframe overlaps its Presence;
- Presence publication directly invalidates WorkspaceChannel and couples transport loss to membership.

Session processes are already correctly owned by `D20.Sessions.Supervisor`. A Phoenix WorkspaceChannel is already a process per joined browser tab, so another actor Workspace process is not required to correct lifecycle semantics.

## Goals / Non-Goals

**Goals:**

- Separate durable session participation from live transport Presence.
- Preserve participants through tab closure, socket loss, Lobby-to-iframe transition, and document reload while the Session process remains alive.
- Make explicit Workspace close the only shell operation that removes participation.
- Keep Presence topic construction, subscription, and event publication inside `D20Web.Presence`, with no Presence dependency on Sessions or WorkspaceChannel.
- Keep Workspace snapshots authoritative and browser-tab presentation local.
- Preserve existing game commands, game aggregates, custom servers, and per-game SessionChannel projections.

**Non-Goals:**

- Persisting sessions or memberships outside the volatile Session process.
- Adding a dynamic actor Workspace GenServer, membership database, or distributed runtime index.
- Synchronizing window mode, focus, or ordering across tabs.
- Changing whether a newly authenticated actor may join a live session when the game engine currently accepts or ignores that join.
- Making offline status alter game-specific player state or game start legality.

## Decisions

### 1. Session members are durable runtime participants

`session.members` remains keyed by actor id, but every value includes:

```elixir
%{
  status: :online | :offline,
  online_at: integer(),
  display_name: String.t(),
  avatar: String.t() | nil
}
```

Only `status` is required. Profile and last-online metadata are populated when available.

Presence `online` adds a missing actor with server-resolved public profile data or refreshes an existing member. Presence `offline` retains the member and changes only transport status.

Game `join` and `left` commands are forwarded to the game engine without changing `session.members`. This keeps the game-specific player roster independent from the generic Session participant set and permits non-player members.

Alternative considered: keep Presence metadata as the member value. Rejected because a meta represents one transport connection, can be replaced by another tab, and cannot represent durable participation.

### 2. SessionChannel tracks server-owned Presence

After resolving and authorizing a session topic, SessionChannel returns the current projection and schedules Phoenix Presence tracking in `:after_join`. The channel resolves `display_name` and `avatar` through Accounts and includes them in server-owned Presence metadata.

The normalized Presence `online` event then adds or refreshes `session.members`. Game admission remains an explicit client game command routed through the common `Sessions.dispatch/3` path.

Alternative considered: synchronously call `D20.Sessions.join/1` from Channel join. Rejected because it duplicates Presence-driven membership and couples channel connection to game player admission.

### 3. Presence owns member admission and transport status

Presence continues to normalize multiple metas at actor level:

- every meta join may publish `online`; the update is idempotent;
- only removal of the final actor meta publishes `offline`.

The Session process handles these as generic member updates without invoking the game engine. `online` adds an absent actor or refreshes an existing member. `offline` only updates an existing member and never removes or recreates one. Presence refs are not stored in Session state.

SessionChannel supplies trusted `display_name`, `avatar`, and `online_at` metadata when it calls `Presence.track/3`. `Session.online/3` stores only those allowed fields, so Phoenix refs are excluded. Account lookup runs in the Channel process and the shared game server has no Accounts dependency.

Alternative considered: retain ref comparison in `D20.Game.Server`. Rejected because one stored ref cannot model multiple concurrent metas and the reverse tab-close order can leave stale membership.

### 4. Runtime state publishes directly to the SessionChannel topic

`D20.Game.Server` publishes every accepted Session state directly to the
existing `session:<id>` topic owned by `D20Web.SessionChannel`. Phoenix
automatically subscribes each joined SessionChannel process to that exact topic,
so no separate Session runtime topic or manual Channel subscription is needed.

`D20.Sessions` owns only actor-scoped subscription and publication for session
discovery invalidation.

`D20Web.Presence` owns Presence publication:

- construction of its private Presence topic;
- subscription to normalized Presence status messages;
- publication of `online` and final-meta `offline` messages.

`D20.Game.Server.broadcast/2` publishes Session state to the SessionChannel topic, delegates actor discovery changes to `D20.Sessions.publish_actor_changes/2`, and subscribes to Presence messages through `D20Web.Presence.subscribe/1`. Actor discovery invalidation occurs only when phase or member-id membership changes, not when member metadata or online status changes. Presence never calls `D20.Sessions` or WorkspaceChannel.

Alternative considered: introduce a separate internal Session runtime topic owned by `D20.Sessions`. Rejected because SessionChannel processes are already subscribed to their transport topic and the proxy topic adds another subscription without changing delivery semantics.

### 5. Workspace remains a derived channel projection

WorkspaceChannel subscribes through `D20.Sessions.subscribe_actor/1`, requests current runtime state through `D20.Sessions.list_runtime/1`, and continues to monitor reported Session pids for immediate abnormal or normal termination removal.

No actor Workspace GenServer is added. Multiple tabs may perform duplicate snapshot calculations and monitors, but snapshots are idempotent and the expected number of actor sessions is small.

Alternative considered: a dynamically supervised `Workspace(actor_id)` process. Deferred because it would optimize multi-tab duplication but would not solve the dependency or membership problem. It can be added later behind the same channel contract if measurements justify it.

### 6. Workspace close is explicit membership removal

WorkspaceChannel validates that the authenticated actor is currently a member and calls `D20.Sessions.remove_member/1`. The resulting actor invalidation removes the descriptor from every actor WorkspaceChannel. Game `join` and `left` remain ordinary engine commands on SessionChannel.

Delayed `offline` messages after iframe teardown are harmless because offline updates never admit absent members.

### 7. Lobby handoff needs no Presence lease

When Lobby observes `in_progress`, it hides, cleans the page URL, calls its normal Session store cleanup, and returns the page to Play. The phase transition already makes the durable member eligible for Workspace discovery, so Workspace mounts the iframe even if the Lobby Presence disappears before the iframe joins.

`handoff_ready` is removed from Workspace descriptors, AsyncAPI, TypeScript state, and reconciliation. The iframe remains the sole in-progress SessionChannel owner after Lobby cleanup.

### 8. Reload recovery follows live runtime membership

A full document reload destroys channels and temporarily marks members offline, but does not remove them. The new WorkspaceChannel join snapshot therefore includes every live in-progress Session where the actor remains a member and remounts its module iframe. No browser storage is used.

Recovery still fails after the volatile Session process expires or terminates, which is consistent with the existing runtime model.

## Risks / Trade-offs

- [Offline waiting players remain in the game roster] -> Preserve the agreed reconnect model; expose member status so Lobby can render only online members while game-specific start legality remains unchanged.
- [A live actor can reconnect immediately after explicit close and join again] -> Presence online intentionally admits the actor again. A future invitation or closed-membership policy can restrict re-admission separately.
- [Multiple WorkspaceChannel tabs duplicate monitors and snapshot work] -> Keep the simpler recoverable projection now; add an actor Workspace process only after measuring a real cost.
- [Public member projection shape changes] -> Update every AsyncAPI member schema, TypeScript type, focused projection test, and browser flow together.
- [PubSub delivery is transient] -> Workspace and SessionChannel always recover from authoritative Session state on join or reconnect.

## Migration Plan

1. Add durable member status transitions and explicit member removal.
2. Publish Session state directly to SessionChannel, keep actor discovery publication in `D20.Sessions`, and retain Presence topic ownership in `D20Web.Presence`.
3. Convert Presence messages to `online` and `offline` status updates.
4. Make SessionChannel provide trusted profile metadata to Presence tracking.
5. Remove Workspace Presence inspection, handoff fields, and Lobby leases.
6. Update AsyncAPI contracts and frontend member types.
7. Validate unit, channel, frontend, full-suite, and real-browser lifecycle behavior.

Rollback restores Presence-derived membership and `handoff_ready`. No persisted data conversion is required because all affected state is volatile.

## Open Questions

None for this change. Late joins retain current engine-controlled behavior; restricting in-progress admission is a separate policy change.
