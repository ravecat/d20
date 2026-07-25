## ADDED Requirements

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

- **GIVEN** the actor is a current member of two live in-progress sessions
- **WHEN** WorkspaceChannel builds a snapshot
- **THEN** both descriptors are returned
- **AND** sessions with the same slug remain distinct by id

#### Scenario: Actor has no eligible session

- **WHEN** WorkspaceChannel finds no eligible session
- **THEN** it returns an empty `sessions` collection

### Requirement: Eligibility follows current runtime state

A session SHALL be eligible only when its runtime is alive, its phase is `in_progress`, its current `members` contains the actor id, and its slug resolves to a configured module. Ownership alone SHALL NOT grant eligibility.

#### Scenario: Waiting or finished session is evaluated

- **WHEN** a current-member session is `waiting_for_players` or `finished`
- **THEN** WorkspaceChannel excludes it

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

The server SHALL invalidate affected actor workspaces after accepted phase or membership changes. Presence meta joins and leaves SHALL also invalidate the actor so `handoff_ready` remains current.

#### Scenario: Waiting session starts

- **WHEN** an accepted transition changes a current-member session to `in_progress`
- **THEN** each affected WorkspaceChannel pushes a snapshot containing it

#### Scenario: Session finishes or actor leaves

- **WHEN** a reported session finishes or removes the actor
- **THEN** each affected WorkspaceChannel pushes a snapshot excluding it

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

### Requirement: Lobby handoff preserves Presence without controller transfer

When Lobby observes `in_progress`, the page SHALL immediately return to its clean Play state and SHALL retain the Lobby session store only as a temporary Presence lease. The lease SHALL be detached when WorkspaceChannel reports `handoff_ready: true`.

#### Scenario: Lobby session starts

- **WHEN** the Lobby session becomes `in_progress`
- **THEN** the page cleans the query URL
- **AND** hides Lobby and renders Play
- **AND** passes the existing Lobby store only as an invisible Presence lease
- **AND** no session controller is adopted by the workspace window

#### Scenario: Module Presence is ready

- **GIVEN** the temporary Lobby lease remains attached
- **WHEN** WorkspaceChannel reports the descriptor with `handoff_ready: true`
- **THEN** the workspace detaches the Lobby store
- **AND** the iframe Presence remains

#### Scenario: Handoff is not ready

- **WHEN** the descriptor is absent, stale, failed, or has `handoff_ready: false`
- **THEN** the lease remains attached
- **AND** Lobby content remains hidden

### Requirement: Workspace reconciliation supports multiple stable windows

The workspace SHALL reconcile snapshots by session id, preserve local mode and order for retained ids, and keep one iframe and SDK bridge per retained entry.

#### Scenario: Snapshot adds and retains sessions

- **GIVEN** session A is mounted
- **WHEN** a snapshot contains A and B
- **THEN** A remains mounted
- **AND** B is added

#### Scenario: Snapshot removes a session

- **WHEN** the next authoritative snapshot omits a prior id
- **THEN** its window and iframe are unmounted
- **AND** local presentation for that id is removed

#### Scenario: Presentation changes

- **WHEN** a retained entry changes between Theater and Compact or survives navigation
- **THEN** the same iframe node and SDK bridge remain mounted

### Requirement: Window close globally removes actor membership

Each game window SHALL expose one close control. It SHALL send `close` with the session id through WorkspaceChannel, keep the window mounted while pending, and wait for the authoritative snapshot. WorkspaceChannel SHALL dispatch the actor-scoped session `left` event and SHALL reject game commands.

#### Scenario: Actor closes a game

- **GIVEN** the same actor has the game open in one or more tabs
- **WHEN** one tab activates close
- **THEN** WorkspaceChannel validates current membership and dispatches the session `left` event
- **AND** the actor is removed from `session.members`
- **AND** every actor WorkspaceChannel pushes a snapshot without the session
- **AND** every affected tab removes its window
- **AND** the runtime is not explicitly stopped

#### Scenario: Close fails or times out

- **WHEN** WorkspaceChannel close fails or times out
- **THEN** the local window remains mounted
- **AND** presents a retryable error
- **AND** the client does not locally suppress the descriptor

#### Scenario: Game command is sent to WorkspaceChannel

- **WHEN** a client sends an event other than the supported shell close
- **THEN** WorkspaceChannel replies with `unsupported_event`
- **AND** does not mutate game state

### Requirement: Workspace presentation is browser-local and accessible

The workspace SHALL keep order, focus, Theater, and Compact in memory for the current tab. Controls SHALL have accessible names, visible keyboard focus, and keyboard activation.

#### Scenario: Another window is expanded

- **WHEN** the actor expands a Compact entry
- **THEN** it becomes the Theater entry
- **AND** the prior entry remains reachable in Compact mode
- **AND** no game command is sent

#### Scenario: Redundant controls are avoided

- **WHEN** a workspace window is rendered
- **THEN** its header and dock do not expose Focus, Minimize, or Detach
- **AND** expansion and close remain available in the established overlay

### Requirement: Temporary WorkspaceChannel loss keeps windows stale

During a temporary user-socket disconnect in the same JavaScript lifetime, existing windows SHALL remain mounted with a stale loading state. After WorkspaceChannel reconnects, its new complete snapshot SHALL be applied.

#### Scenario: User socket disconnects and reconnects

- **WHEN** WorkspaceChannel becomes stale
- **THEN** existing windows and iframes remain mounted
- **AND** display a reconnecting overlay
- **WHEN** WorkspaceChannel returns a ready snapshot
- **THEN** the workspace reconciles that authoritative snapshot

### Requirement: Full page reload does not promise restoration

The client SHALL NOT persist session ids, descriptors, tokens, projections, modes, order, or focus in browser storage.

#### Scenario: Document reloads

- **WHEN** a full page reload destroys the JavaScript workspace
- **THEN** the new workspace starts from the new WorkspaceChannel join snapshot
- **AND** sessions absent from that snapshot are not recreated

### Requirement: Finished sessions are absent from workspace

The workspace SHALL stop presenting a session after its authoritative phase becomes `finished`.

#### Scenario: Active game finishes

- **WHEN** an in-progress game reaches `finished`
- **THEN** WorkspaceChannel pushes a snapshot excluding it
- **AND** the workspace unmounts its window
- **AND** does not retain it for inspection
