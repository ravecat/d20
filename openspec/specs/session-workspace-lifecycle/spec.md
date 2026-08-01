# session-workspace-lifecycle Specification

## Purpose

TBD - created by archiving change decouple-workspace-session-presence. Update Purpose after archive.

## Requirements

### Requirement: Session participation is independent of transport Presence

The Session runtime SHALL retain an actor in `session.members` until the Session process terminates. Closing a game window or tab, losing a socket, removing the final Phoenix Presence meta, or issuing a game-specific `left` command SHALL NOT remove that actor from Session membership.

#### Scenario: Final Presence connection closes

- **GIVEN** an actor is a member of an in-progress Session
- **WHEN** the actor's final SessionChannel Presence meta leaves
- **THEN** the actor remains in `session.members`
- **AND** the member status becomes `offline`
- **AND** the game engine does not receive a membership removal command

#### Scenario: Actor reconnects

- **GIVEN** an offline actor remains a Session member and game player
- **WHEN** a new SessionChannel for that actor joins and tracks Presence
- **THEN** the existing membership is retained
- **AND** trusted profile fields are refreshed from server-owned Presence metadata
- **AND** the member status becomes `online`
- **AND** the game engine receives an idempotent internal `join` command
- **AND** the existing game player state is retained

### Requirement: Generic Session membership API is Presence-only

The generic Session runtime SHALL expose actor membership updates through normalized Presence `online` and `offline` transitions, trust the actor id supplied by that server-owned pipeline, and SHALL NOT expose an explicit member-removal operation or repeat identity validation inside those status functions.

#### Scenario: Caller inspects the shared Session API

- **WHEN** shell or web code interacts with Session membership
- **THEN** it can apply Presence online and offline status transitions
- **AND** it cannot delete a member through `D20.Sessions`, `D20.Sessions.Session`, or a game-server call

#### Scenario: Trusted Presence status is applied

- **GIVEN** the authenticated SessionChannel and normalized Presence pipeline supply an actor id
- **WHEN** `D20.Sessions.Session.online/3` or `offline/2` applies that status
- **THEN** the function returns the unchanged or updated Session
- **AND** it does not return `invalid_identity`
- **AND** external identity validation remains owned by the socket and command boundaries

#### Scenario: Game exposes intentional departure

- **WHEN** a game supports an explicit domain `left` command
- **THEN** that command can update game player state according to game rules
- **AND** it does not become a generic Session membership-removal operation

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

A successful SessionChannel join SHALL resolve the actor scope, return the current projection, and then track Phoenix Presence with server-resolved profile metadata. SessionChannel SHALL NOT invoke a direct Session membership or admission operation.

#### Scenario: New actor joins a SessionChannel

- **WHEN** an authorized actor joins an existing Session topic
- **THEN** SessionChannel returns the current caller-specific projection
- **AND** resolves trusted `display_name` and `avatar` for Presence tracking
- **AND** the resulting Presence `online` event adds the member with `online` status
- **AND** the session runtime sends an internal `join` command to the game engine
- **AND** the game engine exclusively decides whether to add the actor to game player state

#### Scenario: Existing actor rejoins a SessionChannel

- **GIVEN** the actor is already a Session member
- **WHEN** a new Presence meta appears for that actor
- **THEN** trusted profile fields are refreshed
- **AND** the transport status becomes `online`
- **AND** the game engine receives an idempotent internal `join` command

#### Scenario: Lobby joins the SessionChannel

- **WHEN** Lobby creates and joins its Session store
- **THEN** Lobby sends no application event named `join`
- **AND** Lobby derives player and spectator presentation from authoritative projections

### Requirement: Presence owns Session membership admission

Normalized Presence `online` updates SHALL add or refresh Session membership and SHALL attempt game admission through the existing internal game `join` command. Normalized `offline` updates SHALL only mark an existing member offline and SHALL NOT remove Session membership or change game player state. An accepted Workspace Close SHALL terminate every SessionChannel for the authenticated actor and concrete Session so the final Presence meta derives the offline transition.

#### Scenario: Online actor is accepted as a player

- **WHEN** the Session process receives an online status update for an actor allowed by the current game phase and rules
- **THEN** the actor is added to or refreshed in `session.members`
- **AND** allowed profile and last-online metadata are stored
- **AND** the game engine receives an internal `join` command with the actor identity
- **AND** the accepted game player state and membership are published together

#### Scenario: Online actor is not admitted by the game

- **WHEN** the Session process receives an online status update and the game rejects admission because of phase, capacity, or rules
- **THEN** the actor remains an online Session member
- **AND** game player state remains unchanged
- **AND** the actor receives the spectator projection permitted by the game

#### Scenario: Duplicate online status arrives

- **GIVEN** the actor is already a game player
- **WHEN** another tab, reconnect, or iframe produces another Presence online update
- **THEN** membership remains singular and online
- **AND** the internal `join` attempt does not duplicate or reset the existing player

#### Scenario: Actor closes all attachments to one Session

- **GIVEN** an actor has one or more Presence metas for a Session
- **WHEN** WorkspaceChannel accepts Close for that actor and Session
- **THEN** every matching actor SessionChannel leaves the concrete Session topic
- **AND** Presence emits the final-meta offline transition
- **AND** the member remains in `session.members` with `offline` status
- **AND** game player state remains unchanged

#### Scenario: Another actor remains present

- **GIVEN** two actors have Presence metas for the same Session
- **WHEN** one actor closes the Session
- **THEN** only that actor's SessionChannels leave
- **AND** the other actor remains present and online

### Requirement: Public session contracts derive admission from channel presence

The public Session AsyncAPI contracts SHALL describe Phoenix channel join and Presence tracking as the trigger for game admission and SHALL NOT require a client-sent game `join` operation. Workspace Close SHALL remain a shell transport operation and SHALL NOT become a Session game command.

#### Scenario: Client implements the declared session protocol

- **WHEN** a client joins `session:{session_id}`
- **THEN** the server tracks the actor through Presence and attempts game admission
- **AND** the client does not send a separate `join` event

#### Scenario: Client intentionally leaves game player state

- **WHEN** the supported workflow requires intentional game departure
- **THEN** the explicit game `left` command remains distinct from transport disconnect and Workspace Close
- **AND** Session membership remains controlled by Presence lifecycle

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

When Lobby observes that its Session is in progress or finished, it SHALL navigate to the canonical game detail URL while the current page session descriptor continues to own the Lobby branch. The navigation response SHALL remove that descriptor, allowing normal component cleanup to detach the Session store. Workspace discovery SHALL NOT wait for Presence overlap or a handoff flag.

#### Scenario: Waiting Session starts

- **WHEN** Lobby receives an in-progress projection
- **THEN** Lobby requests the canonical game detail URL
- **AND** the Lobby component remains mounted while that navigation is pending
- **AND** the response supplies no selected session and returns the game page to Play
- **AND** normal component cleanup detaches its SessionChannel
- **AND** Workspace mounts the reported in-progress iframe from durable membership
- **AND** no Session controller or Presence lease is transferred

#### Scenario: Selected Session is already finished

- **WHEN** Lobby receives a finished projection
- **THEN** it follows the same canonical navigation and response-owned cleanup lifecycle

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
