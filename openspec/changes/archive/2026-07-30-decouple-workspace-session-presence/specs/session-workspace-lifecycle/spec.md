## ADDED Requirements

### Requirement: Session participation is independent of transport Presence
The Session runtime SHALL retain an admitted actor in `session.members` until an explicit membership removal, Session finish policy, or Session process termination. Closing a tab, losing a socket, or removing the final Phoenix Presence meta SHALL NOT remove that actor from membership.

#### Scenario: Final Presence connection closes
- **GIVEN** an actor is a member of an in-progress Session
- **WHEN** the actor's final SessionChannel Presence meta leaves
- **THEN** the actor remains in `session.members`
- **AND** the member status becomes `offline`
- **AND** the game engine does not receive a membership removal command

#### Scenario: Actor reconnects
- **GIVEN** an offline actor remains a Session member
- **WHEN** a new SessionChannel for that actor joins and tracks Presence
- **THEN** the existing membership is retained
- **AND** trusted profile fields are refreshed from server-owned Presence metadata
- **AND** the member status becomes `online`
- **AND** the game engine does not receive a join command

### Requirement: Session members expose transport status
Every projected Session member SHALL contain a `status` value of `online` or `offline`. Member profile and last-online metadata SHALL remain available when known, and Presence connection refs SHALL NOT be stored in Session state.

#### Scenario: First Presence meta appears
- **WHEN** Phoenix Presence reports a meta join for an actor
- **THEN** the actor is added to `session.members` when absent
- **AND** the member status becomes `online`
- **AND** Presence may update trusted profile and last-online metadata
- **AND** Phoenix `phx_ref` metadata is absent from the member projection

#### Scenario: Another tab joins
- **GIVEN** an actor already has one Presence meta
- **WHEN** another tab adds a second meta
- **THEN** the member remains `online`
- **AND** membership is not duplicated

#### Scenario: One of multiple tabs closes
- **GIVEN** an actor has more than one Presence meta
- **WHEN** one meta leaves
- **THEN** the member remains `online`
- **AND** no offline status transition is dispatched

### Requirement: SessionChannel tracks membership through Presence
A successful SessionChannel join SHALL resolve the actor scope, return the current projection, and then track Phoenix Presence with server-resolved profile metadata. SessionChannel SHALL NOT invoke a direct Session membership operation.

#### Scenario: New actor joins a SessionChannel
- **WHEN** an authorized actor joins an existing Session topic
- **THEN** SessionChannel returns the current caller-specific projection
- **AND** resolves trusted `display_name` and `avatar` for Presence tracking
- **AND** the resulting Presence `online` event adds the member with `online` status
- **AND** the game engine receives no `join` command

#### Scenario: Existing actor rejoins a SessionChannel
- **GIVEN** the actor is already a Session member
- **WHEN** a new Presence meta appears for that actor
- **THEN** trusted profile fields are refreshed
- **AND** the transport status becomes `online`
- **AND** the game engine receives no `join` command

#### Scenario: Actor explicitly joins the game
- **GIVEN** the actor has joined the SessionChannel
- **WHEN** the client sends the game `join` event
- **THEN** SessionChannel routes it through `D20.Sessions.dispatch/3`
- **AND** the game engine exclusively decides whether to add the actor to game player state
- **AND** `session.members` remains unchanged by the game command

### Requirement: Presence owns Session membership admission
Normalized Presence `online` updates SHALL add an absent actor or refresh an existing member. Normalized `offline` updates SHALL only mark an existing member offline. Neither update SHALL change game player state.

#### Scenario: Delayed offline arrives after explicit close
- **GIVEN** explicit Workspace close has removed the actor from membership
- **WHEN** the iframe teardown produces a delayed final Presence leave
- **THEN** the actor is not recreated
- **AND** no game command is dispatched

#### Scenario: Online arrives for an absent actor
- **WHEN** the Session process receives an online status update for an absent actor
- **THEN** the actor is added to `session.members`
- **AND** allowed profile and last-online metadata are stored
- **AND** no game command is dispatched

### Requirement: Workspace close explicitly removes participation
WorkspaceChannel SHALL expose `close` as the shell operation for leaving one Session. It SHALL derive the actor from socket scope, validate current membership, invoke explicit `D20.Sessions.remove_member/1`, and wait for authoritative snapshots to remove the window from every actor tab.

#### Scenario: Actor closes an in-progress game
- **GIVEN** the actor is a current member
- **WHEN** one Workspace tab sends `close`
- **THEN** the actor is removed from `session.members`
- **AND** the game engine receives no `left` command
- **AND** every WorkspaceChannel for the actor pushes a snapshot without the Session
- **AND** the Session process remains alive

#### Scenario: Non-member closes a game
- **WHEN** an actor requests close for a Session where that actor is not a member
- **THEN** WorkspaceChannel rejects the request as forbidden
- **AND** Session and game state remain unchanged

### Requirement: Session and Presence publications respect their ownership boundaries
`D20.Game.Server` SHALL publish accepted Session transitions directly to the SessionChannel topic and SHALL delegate actor discovery invalidation to `D20.Sessions`. `D20Web.Presence` SHALL own its private Presence topic, expose subscription to normalized status messages, publish those messages directly, and SHALL NOT invoke `D20.Sessions` or WorkspaceChannel.

#### Scenario: Accepted phase transition changes Workspace eligibility
- **WHEN** a Session changes from waiting to in-progress
- **THEN** the game server publishes the updated Session to the SessionChannel topic
- **AND** `D20.Sessions` publishes actor discovery invalidation for affected member ids
- **AND** joined SessionChannel processes receive the update through their existing Phoenix subscription

#### Scenario: Presence status changes
- **WHEN** Presence reports an actor meta join or final-meta leave
- **THEN** `D20Web.Presence` publishes the normalized `online` or `offline` message to its private topic
- **AND** the Session runtime receives the message through `D20Web.Presence.subscribe/1`
- **AND** Presence does not call `D20.Sessions` or WorkspaceChannel

#### Scenario: Online status changes only
- **WHEN** an existing member changes between online and offline
- **THEN** SessionChannel subscribers receive the updated projection
- **AND** actor Workspace discovery is not invalidated

### Requirement: Workspace derives sessions from durable membership
WorkspaceChannel SHALL report every live configured in-progress Session whose durable `members` contains the authenticated actor, regardless of current Presence status. Waiting, finished, missing, unconfigured, and non-member Sessions SHALL remain excluded.

#### Scenario: Offline member joins WorkspaceChannel
- **GIVEN** an actor is an offline member of a live in-progress Session
- **WHEN** the actor joins WorkspaceChannel
- **THEN** the complete snapshot includes that Session

#### Scenario: Runtime terminates
- **WHEN** a reported Session process terminates
- **THEN** the monitoring WorkspaceChannel pushes a complete snapshot without it

### Requirement: Lobby transition does not retain a Presence lease
When Lobby observes that its Session is in progress or finished, it SHALL hide, clean the page selection, and detach its Session store through normal component cleanup. Workspace discovery SHALL NOT wait for Presence overlap or a handoff flag.

#### Scenario: Waiting Session starts
- **WHEN** Lobby receives an in-progress projection
- **THEN** Lobby returns the game page to Play
- **AND** its SessionChannel detaches
- **AND** Workspace mounts the reported in-progress iframe from durable membership
- **AND** no Session controller or Presence lease is transferred

### Requirement: Workspace descriptors omit Presence handoff state
Workspace join replies and snapshots SHALL contain Session identity, module bootstrap, and actor-bound connection data without `handoff_ready`. Descriptor refresh SHALL preserve retained iframe identity.

#### Scenario: Workspace receives a descriptor
- **WHEN** an eligible Session is projected
- **THEN** the descriptor contains `id`, `slug`, `module`, and `connection`
- **AND** it does not contain `handoff_ready`

### Requirement: Full document reload restores live memberships
The client SHALL continue to avoid browser storage. After a full document reload, the new WorkspaceChannel snapshot SHALL restore every live in-progress Session where the actor remains a durable member.

#### Scenario: Actor reloads an in-progress game
- **GIVEN** the actor is a member of a live in-progress Session
- **WHEN** a full reload closes the old socket and creates a new WorkspaceChannel
- **THEN** temporary Presence loss marks the member offline without removing membership
- **AND** the new snapshot contains the Session
- **AND** Workspace remounts its iframe

#### Scenario: Session expired before reload
- **GIVEN** the volatile Session process has terminated
- **WHEN** the actor reloads
- **THEN** the Session is absent from the new Workspace snapshot

### Requirement: Shared Session processes remain owned by Sessions supervision
All dynamically created game Session processes SHALL remain children of `D20.Sessions.Supervisor`. Workspace channels or actor-specific processes SHALL hold only derived references and SHALL NOT supervise shared Session processes.

#### Scenario: Actor Workspace disconnects
- **WHEN** every WorkspaceChannel for one actor disconnects
- **THEN** shared Session processes remain alive under `D20.Sessions.Supervisor`
- **AND** other participating actors remain unaffected
