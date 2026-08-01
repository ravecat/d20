## ADDED Requirements

### Requirement: Window close is actor-wide and Session-scoped

Each game window SHALL expose one close control that requests closure of the selected Session for the authenticated actor. After server acceptance, every active Workspace for that actor SHALL suppress and unmount the matching window, iframe, and SDK bridge, and every matching actor SessionChannel SHALL leave the concrete Session topic without removing Session membership or game player state.

#### Scenario: Actor closes a game window

- **GIVEN** two active Workspace instances for the same actor present the same Session
- **WHEN** the actor activates that Session window's close control in either Workspace
- **THEN** the client sends one WorkspaceChannel `close_session` command containing the Session id
- **AND** both Workspace instances receive a complete replacement snapshot omitting that Session
- **AND** both instances unmount that Session window, iframe, and SDK bridge
- **AND** no membership-removal or game `left` command is sent

#### Scenario: Later durable snapshot is built after Close

- **GIVEN** Close stopped the actor's SessionChannel but preserved runtime and membership
- **WHEN** a later ordinary discovery snapshot is rebuilt
- **THEN** it may report the Session again
- **AND** the client reconciles that authoritative snapshot without a retained closed-id filter

#### Scenario: Another actor remains attached

- **GIVEN** another actor has a SessionChannel meta for the same Session
- **WHEN** the current actor closes that Session
- **THEN** only SessionChannels belonging to the current actor leave
- **AND** the other actor remains mounted and online

### Requirement: WorkspaceChannel accepts only the close_session application command

WorkspaceChannel SHALL provide authenticated join replies, server-pushed complete snapshots, and a self-scoped `close_session` command. It SHALL reject every other client-sent application event as unsupported.

#### Scenario: Actor closes a Session attachment

- **WHEN** an authenticated actor sends `close_session` with a binary Session id
- **THEN** WorkspaceChannel replies successfully
- **AND** coordinates SessionChannel termination and replacement Workspace snapshots for the actor and Session
- **AND** does not mutate Session membership or game state

#### Scenario: Actor closes a missing or unrelated attachment

- **WHEN** an actor sends `close_session` for an id without a matching actor SessionChannel
- **THEN** WorkspaceChannel replies successfully
- **AND** the actor-scoped command has no SessionChannel effect

#### Scenario: Offline durable member repeats Close

- **GIVEN** an actor is already offline
- **WHEN** that authenticated actor repeats `close_session`
- **THEN** WorkspaceChannel accepts the idempotent request
- **AND** Presence or membership status is not inspected

#### Scenario: Game command is sent to WorkspaceChannel

- **WHEN** a client sends a game command through WorkspaceChannel
- **THEN** WorkspaceChannel replies with `unsupported_event`
- **AND** does not mutate game state

## MODIFIED Requirements

### Requirement: Workspace reconciliation supports multiple stable windows

The workspace SHALL reconcile authoritative snapshots by session id, preserve local mode for retained ids, keep one iframe and SDK bridge per retained visible entry, and SHALL NOT maintain a parallel client-side set of closed ids.

#### Scenario: Snapshot adds and retains sessions

- **GIVEN** session A is mounted
- **WHEN** a snapshot contains A and B
- **THEN** A remains mounted
- **AND** B is added

#### Scenario: Snapshot removes a session

- **WHEN** the next authoritative snapshot omits a prior id
- **THEN** its window and iframe are unmounted
- **AND** local presentation for that id is removed

#### Scenario: Preserved Session returns in a fresh snapshot

- **GIVEN** session A was closed and its durable member record was preserved offline
- **WHEN** a fresh Workspace snapshot contains A and B
- **THEN** A and B are both reconciled from the authoritative snapshot
- **AND** no client-side closed-id filter suppresses A

#### Scenario: Presentation changes

- **WHEN** a retained visible entry changes between Theater and Compact or survives navigation
- **THEN** the same iframe node and SDK bridge remain mounted

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

### Requirement: Full page reload does not promise restoration

The client SHALL NOT persist session ids, descriptors, tokens, projections, modes, order, focus, or closed ids in browser storage.

#### Scenario: Document reloads after close

- **GIVEN** a live Session was closed in the prior Workspace instance without removing durable membership
- **WHEN** a full page reload destroys the JavaScript workspace
- **THEN** the new Workspace starts from its new WorkspaceChannel join snapshot
- **AND** the Session is presented again when durable discovery still reports it

#### Scenario: Session is no longer reported

- **WHEN** a fresh WorkspaceChannel join snapshot omits a prior Session
- **THEN** the new Workspace does not recreate it from client state

### Requirement: Eligibility follows current runtime state

A session SHALL be eligible only when its runtime is alive, its phase is `in_progress` or `finished`, its current `members` contains the actor, and its slug resolves to a configured module. Presence status SHALL NOT affect eligibility.

#### Scenario: Durable member session is evaluated

- **WHEN** a current-member Session is live, configured, and `in_progress` or `finished`
- **THEN** WorkspaceChannel includes it

#### Scenario: Durable member is offline

- **GIVEN** an actor remains in `session.members` with `status: offline`
- **WHEN** WorkspaceChannel builds a snapshot
- **THEN** Presence status does not exclude that Session

### Requirement: Accepted transitions and Presence publish realtime snapshots

The server SHALL invalidate affected actor workspaces after accepted phase or durable membership changes. Presence status alone SHALL NOT change Workspace discovery.

#### Scenario: Final Presence meta leaves

- **WHEN** the final SessionChannel Presence meta for an actor leaves
- **THEN** the Session process serializes the member's offline status
- **AND** Workspace discovery eligibility remains unchanged

## REMOVED Requirements

### Requirement: Window dismissal is browser-local

**Reason**: Browser-local dismissal leaves the same actor present in the Session topic through other Workspace tabs and does not express actor intent for the concrete Session.

**Migration**: Clients send Workspace `close_session` and remove the window when the existing complete `snapshot` event omits the Session.

### Requirement: WorkspaceChannel accepts no application commands

**Reason**: WorkspaceChannel now owns one shell-level `close_session` command that coordinates presentation and transport lifecycle without mutating the Session aggregate.

**Migration**: Continue rejecting game commands and every application event except `close_session`.
