# multi-session-game-workspace Specification

## Purpose

TBD - created by archiving change add-multi-session-game-workspace. Update Purpose after archive.

## Requirements

### Requirement: The application shell owns a persistent workspace

The shell SHALL mount one workspace outside replaceable Inertia page content. It SHALL keep every still-eligible game window mounted across Inertia navigation and SHALL NOT stop a runtime because the current page changes.

#### Scenario: Navigation preserves workspace sessions

- **GIVEN** the workspace contains an in-progress game window
- **WHEN** the actor navigates to another Inertia page
- **THEN** the destination replaces page content
- **AND** the game window and iframe remain mounted
- **AND** navigation does not stop the runtime

### Requirement: WorkspaceChannel authenticates the actor

The authenticated user socket SHALL expose one `workspace` channel. WorkspaceChannel SHALL derive the actor from socket scope and SHALL NOT accept a client-provided actor id as authority.

#### Scenario: Authenticated actor joins

- **GIVEN** a user socket with a current actor scope
- **WHEN** the client joins `workspace`
- **THEN** the channel returns discovery data only for that actor

#### Scenario: Unauthenticated client joins

- **GIVEN** a socket without a valid actor scope
- **WHEN** it joins `workspace`
- **THEN** the join is rejected with `forbidden`
- **AND** no descriptor is returned

### Requirement: WorkspaceChannel returns complete authoritative snapshots

Every successful join and every `snapshot` event SHALL contain a complete replacement `sessions` collection derived from current runtime state.

#### Scenario: Actor has multiple eligible sessions

- **GIVEN** the actor is an attached retained member of two live in-progress Sessions
- **WHEN** WorkspaceChannel builds a snapshot
- **THEN** both descriptors are returned
- **AND** sessions with the same slug remain distinct by id

#### Scenario: Actor has no eligible session

- **WHEN** WorkspaceChannel finds no eligible session
- **THEN** it returns an empty `sessions` collection

### Requirement: Eligibility follows current runtime state

A Session SHALL be eligible only when its runtime is alive, phase is `in_progress` or `finished`, slug is configured, the actor remains a retained member, and `D20.Sessions.Registry` contains the actor-to-Session attachment. Online or offline Presence SHALL NOT change eligibility, and ownership alone SHALL NOT grant it.

#### Scenario: Attached retained member is evaluated

- **WHEN** an attached retained-member Session is live, configured, and in-progress or finished
- **THEN** Workspace includes it

#### Scenario: Attached member is offline

- **WHEN** the actor attachment remains while Presence is offline
- **THEN** Workspace continues to include that Session

#### Scenario: Retained member is detached

- **WHEN** `session.members` contains the actor but its attachment is absent
- **THEN** Workspace excludes that Session

#### Scenario: Owner is no longer a member

- **GIVEN** an actor owns an in-progress session
- **AND** the actor id is absent from `session.members`
- **WHEN** WorkspaceChannel builds a snapshot
- **THEN** it excludes that session

#### Scenario: Module is unconfigured

- **WHEN** one otherwise eligible slug has no configured module
- **THEN** that session is omitted
- **AND** other valid descriptors remain available

### Requirement: Descriptors contain module bootstrap and handoff state

Every descriptor SHALL contain `id`, `slug`, `module`, fresh actor-bound `connection`, and boolean `handoff_ready`. Descriptor generation SHALL use the authenticated actor and socket request context.

#### Scenario: Eligible descriptor is projected

- **WHEN** WorkspaceChannel reports an eligible session
- **THEN** `connection.topic` identifies that session's existing SessionChannel
- **AND** `connection.token` is signed for the authenticated actor
- **AND** module URLs use the browser-facing socket scheme and host

#### Scenario: TLS terminates before the Phoenix socket

- **GIVEN** the browser connects securely through the trusted production proxy
- **AND** Phoenix receives the socket upgrade through an internal HTTP connection
- **WHEN** WorkspaceChannel builds a module descriptor
- **THEN** the production Endpoint normalizes the trusted forwarded scheme before socket dispatch
- **AND** the iframe URL uses HTTPS
- **AND** the module endpoint uses WSS with the public port

#### Scenario: Presence overlap changes

- **GIVEN** Lobby temporarily retains one actor Presence meta
- **WHEN** the module iframe registers another meta for the same session
- **THEN** a later snapshot reports `handoff_ready: true`

#### Scenario: Credentials refresh

- **GIVEN** a retained session receives fresh connection data
- **WHEN** the workspace reconciles the snapshot
- **THEN** it stores the new descriptor
- **AND** it does not recreate the retained iframe or SDK bridge

### Requirement: Accepted transitions and Presence publish realtime snapshots

The server SHALL invalidate affected actor Workspaces after eligible phase, retained membership, attach, or detach changes. Online-to-offline Presence alone SHALL NOT change Workspace discovery.

#### Scenario: Actor attaches through SessionChannel

- **WHEN** a successful join creates an actor attachment to an eligible Session
- **THEN** every actor Workspace receives a complete snapshot containing it

#### Scenario: Actor detaches through Close

- **WHEN** accepted Close removes the selected actor attachment
- **THEN** every actor Workspace receives a complete snapshot omitting it

#### Scenario: Waiting session starts

- **WHEN** an accepted transition changes a current-member session to `in_progress`
- **THEN** each affected WorkspaceChannel pushes a snapshot containing it

#### Scenario: Session finishes

- **WHEN** a reported Session changes phase to `finished`
- **THEN** each affected WorkspaceChannel pushes a snapshot retaining its finished descriptor

#### Scenario: Final Presence meta leaves ordinarily

- **WHEN** an attached actor's final Presence meta leaves without Close
- **THEN** member status becomes offline
- **AND** Workspace discovery eligibility remains unchanged

#### Scenario: Removed member is notified

- **WHEN** a transition removes an actor from `session.members`
- **THEN** invalidation includes that removed actor

#### Scenario: Duplicate invalidations occur

- **WHEN** duplicate invalidations describe the same runtime state
- **THEN** equivalent complete snapshots are allowed
- **AND** client reconciliation remains idempotent

### Requirement: WorkspaceChannel monitors reported runtimes

Each WorkspaceChannel SHALL monitor every runtime represented by its current snapshot and SHALL rebuild the snapshot when a monitored process terminates.

#### Scenario: Runtime exits

- **WHEN** a reported runtime exits normally or abnormally
- **THEN** its process monitor delivers termination
- **AND** WorkspaceChannel immediately pushes a snapshot without it

### Requirement: The module iframe owns in-progress game realtime

The shell SHALL render the module iframe directly from each workspace descriptor. The iframe SHALL own the per-game SessionChannel used for projections, game commands, Presence, and game transport recovery. The shell workspace SHALL NOT create a second per-game SessionController.

#### Scenario: Workspace adds a game

- **WHEN** a new descriptor appears
- **THEN** the shell mounts one iframe and SDK bridge
- **AND** passes cloneable `endpoint`, `topic`, and `token` bootstrap data
- **AND** does not join that SessionChannel from a shell session store

#### Scenario: Game state changes

- **WHEN** the module sends a game command or receives a projection
- **THEN** communication uses the iframe-owned SessionChannel
- **AND** WorkspaceChannel carries neither game commands nor projections

### Requirement: Waiting sessions remain page-owned

Successful creation SHALL redirect with status 303 to `/games/:slug?session=<id>`. A valid query-selected waiting session SHALL render in Lobby and SHALL NOT appear in workspace.

#### Scenario: Successful creation opens Lobby

- **WHEN** session creation succeeds
- **THEN** the redirect selects the live waiting session on its matching game page
- **AND** Lobby presents waiting controls and member state

#### Scenario: Invalid selected session

- **WHEN** the selected session is missing or belongs to another slug
- **THEN** the page does not expose it as Lobby state
- **AND** page props expose no module token

### Requirement: Workspace reconciliation supports multiple stable windows

The workspace SHALL reconcile authoritative snapshots by Session id and SHALL NOT maintain a client-side closed-id set. Close persistence and re-entry SHALL be derived from server-owned attachments. It SHALL preserve local mode and one iframe and SDK bridge for each retained visible id.

#### Scenario: Snapshot adds and retains sessions

- **GIVEN** session A is mounted
- **WHEN** a snapshot contains A and B
- **THEN** A remains mounted
- **AND** B is added

#### Scenario: Snapshot removes a session

- **WHEN** the next authoritative snapshot omits a prior id
- **THEN** its window and iframe are unmounted
- **AND** local presentation for that id is removed

#### Scenario: Detached Session stays absent

- **WHEN** a fresh authoritative snapshot omits a detached Session
- **THEN** its iframe remains unmounted
- **AND** no browser-local exclusion is required

#### Scenario: Direct re-entry restores a Session

- **WHEN** a successful direct SessionChannel join recreates an attachment
- **THEN** every actor Workspace reconciles the returned Session as an addition

#### Scenario: Unrelated retained window survives

- **WHEN** one selected Session is detached
- **THEN** other retained Session ids keep their iframe identity and presentation state

#### Scenario: Presentation changes

- **WHEN** a retained visible entry changes between Theater and Compact or survives navigation
- **THEN** the same iframe node and SDK bridge remain mounted

### Requirement: Window close is actor-wide and Session-scoped

Each game window SHALL expose Close for its selected Session. After acceptance, the selected actor attachment SHALL be removed, every active actor Workspace SHALL unmount the matching window, and every matching actor SessionChannel SHALL leave, without deleting membership, changing game player state, stopping the runtime, or affecting another Session or actor.

#### Scenario: Actor closes one game in multiple Workspaces

- **WHEN** the actor closes Session A while Session A and B are visible in two Workspaces
- **THEN** only the actor-to-Session A attachment is removed
- **AND** both Workspaces omit A and retain B
- **AND** matching Session A channels stop

#### Scenario: Later snapshot is built

- **WHEN** ordinary discovery runs after Close
- **THEN** it continues to omit the detached Session

#### Scenario: Another actor remains attached

- **GIVEN** another actor has a SessionChannel meta for the same Session
- **WHEN** the current actor closes that Session
- **THEN** only SessionChannels belonging to the current actor leave
- **AND** the other actor remains mounted and online

### Requirement: WorkspaceChannel accepts only the close_session application command

WorkspaceChannel SHALL accept self-scoped `close_session`, reject other application events, and delegate attachment mutation to the authenticated Session runtime.

#### Scenario: Attached actor closes

- **WHEN** an authenticated actor sends `close_session` for an attached Session
- **THEN** WorkspaceChannel replies successfully
- **AND** the Session runtime removes only that actor attachment

#### Scenario: Missing or detached target closes

- **WHEN** Close targets a missing runtime, unrelated Session, or absent attachment
- **THEN** WorkspaceChannel replies successfully
- **AND** the request is an idempotent no-op

#### Scenario: Game command is sent to WorkspaceChannel

- **WHEN** a client sends a game command through WorkspaceChannel
- **THEN** WorkspaceChannel replies with `unsupported_event`
- **AND** does not mutate game state

### Requirement: Workspace presentation is browser-local and accessible

The workspace SHALL keep order, focus, Theater, and Compact presentation in memory for the current tab. Controls SHALL have accessible names, visible keyboard focus, and keyboard activation. Layout controls SHALL remain browser-local, while accepted Close SHALL apply to every active Workspace for the authenticated actor.

#### Scenario: Another window is expanded

- **WHEN** the actor expands a Compact entry
- **THEN** it becomes the Theater entry
- **AND** the prior entry remains reachable in Compact mode
- **AND** no game command is sent

#### Scenario: Window is closed

- **WHEN** the actor activates a window's accessible Close control
- **THEN** the current Workspace waits for server acceptance
- **AND** every active Workspace for that actor removes the matching Session after its replacement snapshot arrives
- **AND** another eligible visible window can become the automatic Theater entry

#### Scenario: Redundant controls are avoided

- **WHEN** a workspace window is rendered
- **THEN** its header and dock do not expose Focus, Minimize, or Detach
- **AND** expansion and actor-wide Close remain available in the established overlay

### Requirement: Temporary WorkspaceChannel loss keeps windows stale

During a temporary user-socket disconnect in the same JavaScript lifetime, existing windows SHALL remain mounted with a stale loading state. After WorkspaceChannel reconnects, its new complete snapshot SHALL be applied.

#### Scenario: User socket disconnects and reconnects

- **WHEN** WorkspaceChannel becomes stale
- **THEN** existing windows and iframes remain mounted
- **AND** display a reconnecting overlay
- **WHEN** WorkspaceChannel returns a ready snapshot
- **THEN** the workspace reconciles that authoritative snapshot

### Requirement: Full page reload follows authoritative attachment state

The client SHALL persist no Session discovery or closed-id state in browser storage. A fresh Workspace SHALL restore only Sessions returned by the server-owned attachment index.

#### Scenario: Document reloads during attachment

- **WHEN** reload temporarily makes an attached member offline
- **THEN** the Registry attachment remains
- **AND** the new Workspace snapshot restores the Session

#### Scenario: Document reloads after Close

- **WHEN** a fresh Workspace joins after the actor detached a Session
- **THEN** the snapshot excludes it
- **AND** client state does not recreate it
