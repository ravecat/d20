## Context

The shell currently uses one unique `D20.Registry` for Session process naming. A game server starts through `:via` with key `{:session, session_id}` and value `server_module`; later `D20.Sessions.get/1`, dispatch, preview, and stop resolve the same process by key.

Workspace discovery does not have an actor index. `D20.Sessions.list/1` selects every registered Session runtime, calls each process, and retains entries whose `session.members` contains the actor. Because `session.members` intentionally retains offline actors for identity and game projections, explicit Close cannot remain excluded from later discovery.

The agreed behavior distinguishes three concerns:

- runtime existence: the Session process is alive;
- retained membership and Presence: the actor profile remains in `session.members` with `online | offline`;
- Workspace attachment: the actor currently wants the live Session listed in Workspace.

The attachment relationship is volatile, actor-to-many-Sessions, many-actors-to-Session, and shares the Session process lifetime. This makes a duplicate process Registry an appropriate local index.

## Goals / Non-Goals

**Goals:**

- Index active actor-to-Session Workspace attachments without scanning every Session process.
- Preserve member profile, Presence status, game player state, and shared runtime after explicit Close.
- Keep ordinary disconnect and reload recoverable without browser storage.
- Make Close actor-wide, session-scoped, idempotent, and reversible through successful direct SessionChannel entry.
- Keep registration ownership and attach/detach serialization inside the Session process.
- Preserve public member statuses and wire shapes.

**Non-Goals:**

- Persist attachments across Session process termination or application restart.
- Use the attachment index as game membership, authorization, or game player state.
- Change the existing unique `D20.Registry` or use the duplicate Registry through `:via`.
- Add a `left` member status, delete retained members, or issue a game-specific `left` command.
- Add browser-local closed-id persistence or a database model.
- Make the local Session architecture distributed across nodes.

## Decisions

### 1. Keep runtime naming, retained membership, and Workspace attachment separate

The three sources will have distinct responsibilities:

| Source | Logical form | Responsibility |
| --- | --- | --- |
| `D20.Registry` | `{:session, session_id} -> {session_pid, server_module}` | Unique Session process naming and calls |
| `session.members` | `actor_id -> member` | Retained profile and `online | offline` Presence status |
| `D20.Sessions.Registry` | `actor_id -> [{session_pid, session_id}]` | Active Workspace attachment lookup |

`D20.Registry` remains `keys: :unique` because `:via` only supports unique process names. `D20.Sessions.Registry` will be a separate supervised Registry with `keys: :duplicate`, allowing one actor key to identify many Session processes and one Session process to register different actor keys.

Absence from `D20.Sessions.Registry` means only that the Session is not attached to that actor's Workspace. It does not mean the actor was deleted from the Session or game.

Alternatives considered:

- Add `left` to member status. Rejected because explicit Workspace attachment and Presence are separate concerns, and clients do not need a third public status.
- Delete the member on Close. Rejected because projections and games require retained identity and player state.
- Store closed ids in WorkspaceChannel or the browser. Rejected because Close must apply to every current and future Workspace for the actor and be reversed authoritatively.

### 2. Store actor id as key and Session id as Registry value

The Session process will call:

```elixir
Registry.register(D20.Sessions.Registry, actor_id, session.id)
```

Registry implicitly associates the calling Session PID with the entry, so lookup returns `[{session_pid, session_id}]`. `actor_id` is the key because the primary query is all attached Sessions for one actor. A composite `{actor_id, session_id}` key would require a Registry-wide select for that query, while storing PID in the value would duplicate information Registry already supplies.

The Session id is immutable and lets `D20.Sessions.list/1` reuse normal runtime resolution and error handling. Mutable Session state, slug, profile, and projections SHALL NOT be copied into the Registry value.

### 3. Hide raw Registry operations behind `D20.Sessions.Registry`

`D20.Sessions.Registry` will expose a narrow interface:

- `attach(actor_id, session_id)` returns whether the calling Session process created a new attachment;
- `detach(actor_id)` returns whether the calling Session process removed an attachment;
- `list(actor_id)` returns the registered `{session_pid, session_id}` pairs.

Duplicate Registry permits the same process to register the same key more than once, so `attach/2` must be idempotent. It will inspect values for the calling PID before registering. The game server mailbox serializes calls for a Session, preventing concurrent attach/detach operations from that owner.

Raw Registry access remains an implementation detail. Workspace and channels call `D20.Sessions`, not `Registry` directly.

### 4. Attach through a serialized Session call after successful SessionChannel authorization

Registration SHALL NOT be placed in the Presence `{:online, ...}` handler. Presence answers whether a channel meta currently exists; attachment answers whether the actor wants the Session represented in Workspace.

After SessionChannel validates the socket actor, topic, live Session, and slug, it will call `D20.Sessions.attach(scope)`. `D20.Sessions` sends a synchronous attach call to the configured Session process. The Session process then calls `D20.Sessions.Registry.attach/2`, making its own PID the registration owner.

The attach call is idempotent for Lobby, iframe, multiple tabs, reconnects, and repeated joins. A new attachment triggers actor Workspace invalidation. SessionChannel then follows the existing after-join Presence tracking path, which updates the retained member status and attempts game admission independently.

Alternatives considered:

- Register inside SessionChannel. Rejected because the channel PID would own the entry and closing one browser tab would delete the attachment.
- Register inside the Presence online handler. Rejected because it couples transport status to explicit Workspace attachment and obscures the separate lifecycle.
- Register from Workspace. Rejected because Workspace must discover existing attachments rather than create them speculatively.

### 5. Detach through the Session process before actor-wide channel shutdown

WorkspaceChannel will pass its authenticated scope and requested Session id to `D20Web.Workspace`. The Workspace boundary calls `D20.Sessions.detach(scope, session_id)`, which synchronously asks that Session process to:

1. remove its own registration under the actor key when present;
2. mark an existing retained member offline immediately;
3. publish a changed Session projection when status changed;
4. invalidate actor Workspace discovery when attachment changed;
5. leave game state and runtime lifecycle unchanged.

After detach completes or resolves as an idempotent missing attachment, Workspace publishes the existing actor-scoped close message. Every matching SessionChannel stops, while every WorkspaceChannel rebuilds a complete snapshot from authoritative registry lookup instead of applying a one-time id filter.

Missing runtime, unrelated actor, absent attachment, repeated Close, and delayed final Presence offline are idempotent. Other Sessions and other actors remain unchanged.

### 6. Retain attachments across ordinary Presence offline

The normalized Presence offline handler continues to set an existing member status to `offline` and does not call `detach`. Therefore closing one browser tab, closing the final tab without using Workspace Close, reloading, losing a socket, or suffering transient network failure leaves the actor-to-Session attachment intact.

A fresh WorkspaceChannel lookup returns the offline attachment and mounts its iframe. The successful SessionChannel join idempotently confirms attachment, then Presence returns the member to online.

### 7. Reattach through a successful direct SessionChannel join

A detached Session remains resolvable by direct Session id through the existing unique `D20.Registry`. A valid direct page or module bootstrap can therefore authorize and join SessionChannel without being listed in Workspace first.

The successful join invokes the same serialized attach call. A newly created attachment invalidates every active Workspace for the actor, whose next complete snapshots contain the Session when its phase is `in_progress` or `finished`. Existing member data and game player state are retained; the following Presence online transition refreshes profile and performs the existing idempotent internal game `join` attempt.

### 8. Build actor Session lists from the attachment index

`D20.Sessions.list/1` will call `D20.Sessions.Registry.list(actor_id)` and resolve only those Session ids. It will retain the current return shape `{pid, {session, slug}}`, skip entries whose runtime disappeared during lookup, and avoid the current Registry-wide select plus one process call per unrelated Session.

Registry cleanup after process exit can be delayed briefly, so callers must continue to tolerate stale PIDs or a `session_not_found` race. Workspace already monitors every reported runtime and rebuilds complete snapshots on `:DOWN`.

### 9. Invalidate Workspace only when attachment or existing discovery facts change

The game server will notify `D20Web.Workspace` when `attach` creates or `detach` removes an actor relationship. Existing phase and durable member-id comparison remains for other discovery transitions. Online-to-offline and profile-only updates do not change attachment eligibility and do not invalidate Workspace.

SessionChannel publication still precedes Workspace invalidation when a Session projection changes. Attachment-only changes may invalidate Workspace without publishing an unchanged Session projection. Equivalent duplicate complete snapshots remain valid and client reconciliation remains idempotent.

### 10. Preserve public protocols

Session projections continue to expose only `online | offline`. Workspace keeps the existing topic, join reply, `close_session` command and reply, descriptor shape, and complete `snapshot` event. Only semantics change: accepted Close persists through Registry detachment, and a successful later direct join restores the attachment.

The Workspace AsyncAPI description and behavior tests will be updated. Game-session AsyncAPI enum schemas require no version change.

## Risks / Trade-offs

- [Registry registration owned by the wrong process] -> Execute raw attach and detach only inside the Session process and test that one channel exit does not remove the relationship.
- [Duplicate joins create duplicate Registry entries] -> Make `attach/2` idempotent per `{actor_id, self(), session_id}` and cover multiple tabs and reconnects.
- [Registry cleanup is briefly delayed after Session exit] -> Resolve Session state through the existing safe API, skip missing runtimes, and keep Workspace process monitors.
- [The new Registry partition exits] -> Supervise it before `D20.Sessions.Supervisor`; process-owned links may terminate attached volatile Sessions, matching the existing local volatile runtime model.
- [Attach succeeds but Presence tracking later fails] -> The actor remains attached and offline, allowing Workspace or direct transport recovery without data loss.
- [A stale channel races with Close] -> Serialize detach before broadcasting actor channel shutdown and reconcile only authoritative complete snapshots.
- [Live runtime exists during hot upgrade without attachment entries] -> The next successful SessionChannel join idempotently creates the attachment; a cold deploy naturally starts both registries before Sessions.

## Migration Plan

1. Add and supervise `D20.Sessions.Registry` before dynamic Session processes.
2. Add registry and public Session attach/detach interfaces plus default and custom game-server callbacks.
3. Attach through authorized SessionChannel joins and detach through Workspace Close.
4. Replace membership-scan discovery with actor-indexed lookup and publish attachment invalidations.
5. Update backend, frontend reconciliation, and Workspace AsyncAPI behavior tests.
6. Run targeted validation followed by `just check` and strict OpenSpec validation.

Rollback removes the new child and lifecycle calls and restores membership-scan discovery. No database or stored-data conversion is required.

## Open Questions

None. Registry ownership, key and value shape, attach point, Close ordering, reload behavior, and direct re-entry are fixed by this design.
