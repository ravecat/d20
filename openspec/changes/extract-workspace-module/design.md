## Context

The checkpoint at `7811eb5` implements actor-scoped workspace discovery with three owners:

- `D20.Sessions` looks up authoritative runtime sessions and also owns actor PubSub subscription and invalidation.
- `D20Web.WorkspaceChannel` constructs actor-specific descriptors, monitors reported runtimes, and pushes complete snapshots.
- `D20.Game.Server` publishes every accepted Session update to SessionChannel and then delegates workspace invalidation to `D20.Sessions`.

The resulting behavior is correct, but Phoenix transport details live in a domain context while one workspace refresh operation is split across modules. The refactor must preserve the current channel contract and leave all client files untouched.

## Goals / Non-Goals

**Goals:**

- Give workspace subscription, invalidation, and snapshot construction one explicit web-layer owner.
- Keep authoritative runtime lookup and membership filtering behind `D20.Sessions`.
- Keep socket callbacks, process monitors, replies, and pushes in `D20Web.WorkspaceChannel`.
- Preserve complete-snapshot refresh behavior and direct SessionChannel publication.
- Preserve all existing client, AsyncAPI, game, Session, and supervision contracts.

**Non-Goals:**

- Changing workspace eligibility, descriptor fields, events, payloads, or close semantics.
- Moving Session process ownership or runtime lookup into the web layer.
- Sending workspace deltas instead of complete snapshots.
- Adding a new process, supervisor, cache, database state, or dependency.
- Modifying frontend files.

## Decisions

### Use a stateless `D20Web.Workspace` boundary

`D20Web.Workspace` will expose three public operations:

- `subscribe/1` subscribes the calling process to the authenticated actor's private workspace topic.
- `publish_session_changes/2` compares previous and current Session discovery state and invalidates every affected actor.
- `snapshot/1` obtains actor-visible runtimes from `D20.Sessions.list_runtime/1` and converts eligible sessions into socket-specific descriptors plus the runtime map used by channel monitors.

The module will not own a process or state. PubSub already provides fan-out to every WorkspaceChannel for an actor, and snapshots are intentionally rebuilt from current authoritative runtime state.

Alternative considered: keep PubSub helpers in `D20.Sessions`. Rejected because actor workspace topics and refresh messages are Phoenix delivery details, not Session-domain operations.

Alternative considered: put all helpers directly in `D20Web.WorkspaceChannel`. Rejected because `D20.Game.Server` needs a callable publication boundary and should not depend on Channel callback internals.

### Keep runtime discovery in `D20.Sessions`

`D20.Sessions.list_runtime/1` will continue to resolve registered Session processes and filter them by durable actor membership. `D20Web.Workspace.snapshot/1` will continue to apply workspace presentation eligibility (`:in_progress` and configured game module) and build module connection descriptors from the authenticated socket.

This keeps Registry process lookup and Session membership in the domain context while keeping `D20Web.Module` and socket request context in the web layer.

Alternative considered: move `list_runtime/1` into `D20Web.Workspace`. Rejected because process discovery and actor membership are authoritative Session concerns and are also useful independently of one transport projection.

### Keep channel process lifecycle in `D20Web.WorkspaceChannel`

The channel will delegate subscription and snapshot construction to `D20Web.Workspace`, but retain:

- authorization and `close` handling;
- `handle_info/2` callbacks;
- `Process.monitor/1` and `Process.demonitor/2`;
- snapshot pushes and socket assigns.

Monitoring must remain in the channel because monitors belong to the calling process and their references are stored in that socket's assigns.

### Preserve publication order and message shape

`D20.Game.Server.broadcast/2` will first publish `{:session, session}` directly to the existing SessionChannel topic. After successful publication it will call `D20Web.Workspace.publish_session_changes/2`.

Workspace invalidation will retain `{:sessions_changed, actor_id}` and complete-snapshot refresh semantics. It will compare phase and member-id sets, then publish to the union of previous and current member ids so removed actors are also notified.

The private actor topic may be renamed under workspace ownership because it is not a public channel or AsyncAPI contract. Publisher and subscriber will move atomically in the same change.

## Risks / Trade-offs

- [Risk] `D20.Game.Server` gains another explicit dependency on `D20Web` - Mitigation: it already publishes through `D20Web.SessionChannel`, and both dependencies are narrow transport boundaries.
- [Risk] Moving publisher and subscriber topic code could silently stop invalidation - Mitigation: keep the topic function private to one module and cover duplicate, phase, membership-add, and membership-remove invalidations through WorkspaceChannel tests.
- [Risk] Public helper extraction could accidentally change descriptor ordering or fields - Mitigation: move snapshot code without rewriting it and retain existing join/snapshot assertions.
- [Trade-off] `D20Web.Workspace` owns both PubSub and projection assembly - Accepted because they are the two halves of one workspace refresh boundary and do not justify separate single-use modules.

## Migration Plan

1. Add `D20Web.Workspace` with the existing PubSub comparison and snapshot construction behavior.
2. Update `D20Web.WorkspaceChannel` to delegate subscription and snapshots while retaining monitoring and pushes.
3. Update `D20.Game.Server` to publish workspace invalidation through the new module.
4. Remove actor workspace PubSub helpers from `D20.Sessions`.
5. Update focused tests to call the new public boundary and verify unchanged channel behavior.
6. Run formatting, focused Sessions and channel tests, the full backend suite, and strict OpenSpec validation.

Rollback is a revert to checkpoint `7811eb5`; there is no data migration or persistent state to restore.

## Open Questions

None.
