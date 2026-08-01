## Context

The Workspace currently derives every in-progress or finished window from durable Session membership and suppresses a closed id only inside one Svelte store. The iframe owns the corresponding SessionChannel, so local unmount removes only that tab's Presence meta. With the same actor open in two tabs, the other Workspace and iframe remain active.

The domain distinction established by the preceding Presence refactor remains valid: `session.members` records durable participation, game `players` records authoritative game state, and Presence records current connectivity. Close must affect connectivity and presentation without deleting either durable record.

## Goals / Non-Goals

**Goals:**

- Make Close apply to one authenticated actor and one concrete Session across all active tabs and devices.
- Programmatically terminate every matching SessionChannel so Presence can derive the final offline transition.
- Remove the matching window from every active actor Workspace only after the server accepts the command.
- Preserve Session membership, game player state, and the runtime process so ordinary durable discovery remains available.
- Keep duplicate Close commands and replacement snapshots idempotent.

**Non-Goals:**

- Remove an actor from `session.members` or from a game aggregate.
- Dispatch a game-specific `left` command.
- Stop the shared Session runtime.
- Persist closed ids in the database, browser storage, or a server-side actor preference.
- Change iframe module bootstrap data or the module SDK contract.

## Decisions

### WorkspaceChannel accepts one shell command

`WorkspaceChannel.handle_in("close_session", %{"id" => session_id}, socket)` will take the authenticated actor from socket scope and publish Close for that actor and binary Session id. It will not resolve the Session, inspect membership or Presence status, build a dispatch scope, or call a Session mutation. A missing or unrelated id is an idempotent no-op; every other application event remains `unsupported_event`.

The command cannot affect another actor because the actor id never comes from the payload and every SessionChannel handler matches both the authenticated actor and selected Session id. Expressing Close as a game command would incorrectly couple shell lifecycle to game rules.

### Close uses one actor-scoped PubSub command

Every SessionChannel will subscribe to the authenticated actor's private Workspace topic in addition to its automatic concrete Session topic subscription. `D20Web.Workspace.close_session_for_actor/2` will broadcast one command, `{:close_session, actor_id, session_id}`, on that actor topic. SessionChannel processes for the actor will receive the command; only the process whose scope contains the selected Session id will return `{:stop, :normal, socket}`. Channels for the actor's other Sessions and channels belonging to other actors remain active. Each WorkspaceChannel for that actor will build a fresh snapshot and omit the selected id from that one push. No public SessionChannel leave proxy, duplicate publication, or retained exclusion set is required.

The broadcast uses cluster-wide PubSub because one actor's tabs or devices can terminate on different Phoenix nodes. Direct SessionChannel subscription also covers a live matching SessionChannel whose Workspace connection cannot currently consume the UI event.

No Session or game process receives a Close mutation. Phoenix Presence removes each stopped channel meta and emits the existing normalized offline update only after the final meta disappears. Offline status does not change durable Workspace eligibility.

### Clients acknowledge Close through the replacement snapshot

The Workspace store will expose `closeSession(id)` as a Phoenix `close_session` call. It will not remove the window optimistically. Every active WorkspaceChannel receives the command and pushes one complete snapshot built from durable discovery with the selected id omitted. The store replaces its Session list directly and Svelte unmounts the iframe and bridge while browser-local layout remains independent. Duplicate commands and snapshots are harmless.

Waiting for the snapshot keeps all active Workspaces on the same accepted outcome. Neither client nor WorkspaceChannel maintains a parallel dismissal set. Because durable membership and runtime state are preserved, a later ordinary discovery snapshot or fresh Workspace join may report the Session again.

### Public wire additions are backward-compatible

The internal Workspace AsyncAPI adds a `close_session` command with its reply. Existing clients continue to consume the unchanged complete `snapshot` event, so the contract advances from 1.0.0 to 1.1.0.

## Risks / Trade-offs

- [A Workspace is disconnected when Close is broadcast] - It is not active and needs no presentation update; a later fresh join derives state from durable membership.
- [All SessionChannels for an actor receive Close] - Each handler matches both actor and Session ids, so unrelated SessionChannels perform one pattern check and remain active.
- [A later snapshot reports the preserved Session again] - This is intentional because Close has no retained dismissal state; each snapshot remains a direct view of durable discovery at the time it is built.
- [Server-initiated SessionChannel shutdown races iframe unmount] - Both outcomes remove the same Presence meta and Phoenix channel termination is idempotent from the aggregate's perspective.
- [A forged Session id names another Session] - The actor id remains server-owned, so the command can only stop that actor's own matching SessionChannel and is otherwise a no-op.

## Migration Plan

1. Add failing backend and frontend regression tests for actor-wide Close, SessionChannel shutdown, and preservation of Session and game state.
2. Subscribe SessionChannel to the actor Workspace topic and broadcast one actor-scoped Close command.
3. Change the Svelte Workspace store to call Close and reconcile the replacement `snapshot`.
4. Update AsyncAPI and focused contract tests, then verify the two-tab browser scenario.
5. Roll back by removing the command handlers and restoring immediate browser-local suppression; no stored data requires migration.

## Open Questions

None.
