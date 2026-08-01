## ADDED Requirements

### Requirement: Window dismissal is browser-local

Each game window SHALL expose one close control that suppresses the selected Session id in the current Workspace store and immediately unmounts its window, iframe, and SDK bridge without sending a WorkspaceChannel or Session command.

#### Scenario: Actor dismisses a game window

- **GIVEN** the current Workspace presents a Session window
- **WHEN** the actor activates its close control
- **THEN** that Workspace instance immediately removes the window
- **AND** destroys the iframe-owned bridge and SessionChannel
- **AND** sends no WorkspaceChannel `close`, Session membership-removal, or game `left` command

#### Scenario: Replacement snapshot retains a dismissed Session

- **GIVEN** a Session id was dismissed in the current Workspace instance
- **WHEN** a later complete snapshot still contains that Session
- **THEN** the Workspace keeps it suppressed
- **AND** does not remount its iframe

#### Scenario: Another actor tab remains attached

- **GIVEN** the same actor has another SessionChannel meta in a different tab or device
- **WHEN** the current Workspace dismisses its window
- **THEN** the other tab remains mounted and online
- **AND** the shared Session membership and game player state remain unchanged

### Requirement: WorkspaceChannel accepts no application commands

WorkspaceChannel SHALL provide authenticated join replies and server-pushed complete snapshots and SHALL reject every client-sent application event as unsupported.

#### Scenario: Legacy close is sent

- **WHEN** a client sends the removed Workspace `close` event
- **THEN** WorkspaceChannel replies with `unsupported_event`
- **AND** Session membership, game state, and Workspace discovery remain unchanged

#### Scenario: Game command is sent to WorkspaceChannel

- **WHEN** a client sends a game command through WorkspaceChannel
- **THEN** WorkspaceChannel replies with `unsupported_event`
- **AND** does not mutate game state

## MODIFIED Requirements

### Requirement: Workspace reconciliation supports multiple stable windows

The workspace SHALL reconcile snapshots by session id, preserve local mode and order for retained ids, keep one iframe and SDK bridge per retained visible entry, and exclude ids dismissed during the current Workspace lifetime.

#### Scenario: Snapshot adds and retains sessions

- **GIVEN** session A is mounted
- **WHEN** a snapshot contains A and B
- **THEN** A remains mounted
- **AND** B is added

#### Scenario: Snapshot removes a session

- **WHEN** the next authoritative snapshot omits a prior id
- **THEN** its window and iframe are unmounted
- **AND** local presentation for that id is removed

#### Scenario: Snapshot contains a locally dismissed session

- **GIVEN** session A was dismissed during the current Workspace lifetime
- **WHEN** a replacement snapshot contains A and B
- **THEN** A remains unmounted
- **AND** B is reconciled normally

#### Scenario: Presentation changes

- **WHEN** a retained visible entry changes between Theater and Compact or survives navigation
- **THEN** the same iframe node and SDK bridge remain mounted

### Requirement: Workspace presentation is browser-local and accessible

The workspace SHALL keep order, focus, Theater, Compact, and dismissed Session ids in memory for the current tab. Controls SHALL have accessible names, visible keyboard focus, and keyboard activation.

#### Scenario: Another window is expanded

- **WHEN** the actor expands a Compact entry
- **THEN** it becomes the Theater entry
- **AND** the prior entry remains reachable in Compact mode
- **AND** no game command is sent

#### Scenario: Window is dismissed

- **WHEN** the actor activates a window's accessible Close control
- **THEN** only the current tab's presentation changes
- **AND** another eligible visible window can become the automatic Theater entry

#### Scenario: Redundant controls are avoided

- **WHEN** a workspace window is rendered
- **THEN** its header and dock do not expose Focus, Minimize, or Detach
- **AND** expansion and browser-local close remain available in the established overlay

### Requirement: Full page reload does not promise restoration

The client SHALL NOT persist session ids, descriptors, tokens, projections, modes, order, focus, or dismissed ids in browser storage.

#### Scenario: Document reloads after local dismissal

- **GIVEN** a live eligible Session was dismissed in the prior Workspace instance
- **WHEN** a full page reload destroys the JavaScript workspace
- **THEN** the new Workspace starts from its new WorkspaceChannel join snapshot
- **AND** the Session is presented again when that snapshot still reports it

#### Scenario: Session is no longer reported

- **WHEN** a fresh WorkspaceChannel join snapshot omits a prior Session
- **THEN** the new Workspace does not recreate it from client state

## REMOVED Requirements

### Requirement: Window close globally removes actor membership

**Reason**: Window chrome cannot reliably express durable departure and global removal conflicts with Presence-owned online/offline status, multi-tab connections, and reload recovery.

**Migration**: Close suppresses the id only in the current Workspace store and unmounts its iframe. The server continues to report the durable membership, and a fresh Workspace mount restores the Session.
