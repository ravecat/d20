# session-workspace-lifecycle Specification

## Purpose

TBD - created by archiving change decouple-workspace-session-presence. Update Purpose after archive.

## Requirements

### Requirement: Session participation is independent of transport Presence

The Session runtime SHALL retain an actor in `session.members` until the Session process terminates. Closing a browser tab, losing a socket, removing the final Phoenix Presence meta, explicitly closing a Workspace game window, or issuing a game-specific `left` command SHALL NOT delete that actor's member record or game player state. Workspace attachment SHALL be tracked separately from retained membership and Presence status.

#### Scenario: Final Presence connection closes

- **GIVEN** an actor is an attached online member of an in-progress Session
- **WHEN** the actor's final SessionChannel Presence meta leaves without explicit Workspace Close
- **THEN** the actor remains in `session.members` with `status: offline`
- **AND** the actor-to-Session attachment remains registered
- **AND** the game engine does not receive a membership removal command

#### Scenario: Actor explicitly closes the Session

- **GIVEN** an actor is attached to a Session
- **WHEN** Workspace accepts Close for that actor and Session
- **THEN** the actor-to-Session attachment is removed
- **AND** the actor remains in `session.members` with `status: offline`
- **AND** retained profile fields and game player state remain unchanged
- **AND** the game engine receives no game-specific `left` command

#### Scenario: Actor reconnects without explicit Close

- **GIVEN** an offline actor remains a retained member and attachment owner
- **WHEN** a new SessionChannel for that actor joins and tracks Presence
- **THEN** attach is idempotent and the existing attachment remains singular
- **AND** trusted profile fields are refreshed
- **AND** the member status becomes `online`
- **AND** the game engine receives an idempotent internal `join` command
- **AND** the existing game player state is retained

### Requirement: Generic Session lifecycle separates membership Presence and attachment

The generic Session runtime SHALL expose normalized Presence `online` and `offline` transitions plus serialized actor `attach` and `detach` operations. Attach and detach SHALL change only the process-owned Workspace relationship, except detach SHALL also normalize an existing retained member to offline. No operation SHALL delete a retained member or translate attachment removal into a game command.

#### Scenario: Authenticated SessionChannel attaches

- **WHEN** shell web code successfully authorizes a SessionChannel join
- **THEN** it can attach the scoped actor through `D20.Sessions`
- **AND** the configured Session process owns the Registry mutation

#### Scenario: Authenticated Workspace detaches

- **WHEN** Workspace accepts Close for an actor and Session
- **THEN** it can detach the scoped actor through `D20.Sessions`
- **AND** the configured Session process owns the Registry mutation
- **AND** the member record remains retained

#### Scenario: Trusted Presence status is applied

- **GIVEN** the authenticated SessionChannel and normalized Presence pipeline supply an actor id
- **WHEN** `D20.Sessions.Session.online/3` or `offline/2` applies that status
- **THEN** the function returns the unchanged or updated Session
- **AND** it does not return `invalid_identity`
- **AND** external identity validation remains owned by the socket and command boundaries

#### Scenario: Game exposes intentional departure

- **WHEN** a game supports an explicit domain `left` command
- **THEN** that command can update game player state according to game rules
- **AND** it remains distinct from Workspace detach

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

A successful SessionChannel join SHALL resolve and authorize the actor scope, synchronously attach that actor through the Session runtime, return the current projection, and then track Phoenix Presence with server-resolved profile metadata. Attachment SHALL remain distinct from Presence membership updates and game admission.

#### Scenario: New actor joins a SessionChannel

- **WHEN** an authorized actor joins an existing Session topic
- **THEN** SessionChannel attaches the actor through `D20.Sessions`
- **AND** returns the current caller-specific projection
- **AND** tracks trusted profile metadata through Presence
- **AND** the resulting Presence online event adds the retained member and attempts internal game `join`

#### Scenario: Existing actor reconnects

- **GIVEN** the actor is already attached and remains a retained Session member
- **WHEN** another SessionChannel successfully joins
- **THEN** attach is an idempotent no-op
- **AND** Presence refreshes profile and online status

#### Scenario: Detached actor enters through a direct Session flow

- **GIVEN** a live Session retains the actor member but has no actor attachment
- **WHEN** a valid direct page or module flow successfully joins SessionChannel
- **THEN** the actor is attached again before Presence tracking
- **AND** every active Workspace for the actor is invalidated

#### Scenario: Lobby joins the SessionChannel

- **WHEN** Lobby creates and joins its Session store
- **THEN** Lobby sends no application event named `join`
- **AND** Lobby derives player and spectator presentation from authoritative projections

### Requirement: Presence owns Session membership admission

Normalized Presence online updates SHALL add or refresh retained Session membership and attempt game admission through the existing internal game `join` command. Normalized offline updates SHALL only mark an existing member offline and SHALL NOT remove retained membership, actor attachment, or game player state. Accepted Workspace Close SHALL detach before terminating matching SessionChannels.

#### Scenario: Online actor is accepted as a player

- **WHEN** the Session process receives an online status update for an attached actor allowed by game rules
- **THEN** retained membership and profile metadata are updated
- **AND** the game engine receives internal `join`

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

- **WHEN** WorkspaceChannel accepts Close for that actor and Session
- **THEN** the Session process detaches that actor first
- **AND** every matching actor SessionChannel leaves
- **AND** the retained member is offline
- **AND** game player state remains unchanged

#### Scenario: Final Presence meta leaves ordinarily

- **WHEN** the final SessionChannel Presence meta leaves without Workspace Close
- **THEN** the retained member becomes offline
- **AND** the attachment and game player state remain unchanged

#### Scenario: Another actor remains present

- **GIVEN** two actors have Presence metas for the same Session
- **WHEN** one actor closes the Session
- **THEN** only that actor's SessionChannels leave
- **AND** the other actor remains present and online

### Requirement: Public session contracts derive admission from channel presence

The public Session AsyncAPI contracts SHALL keep Phoenix channel join and Presence tracking as the trigger for game admission and SHALL expose only `online | offline` member statuses. Workspace Close SHALL remain a shell attachment operation and SHALL NOT become a Session game command.

#### Scenario: Client implements the declared session protocol

- **WHEN** a client joins `session:{session_id}`
- **THEN** the server attaches the actor, tracks Presence, and attempts game admission
- **AND** the client sends no separate game `join` event

#### Scenario: Client intentionally closes a Workspace game

- **WHEN** the client sends Workspace `close_session`
- **THEN** the server detaches the actor without adding a public member status
- **AND** game-specific `left` remains distinct

#### Scenario: Client intentionally leaves game player state

- **WHEN** the supported workflow requires intentional game departure
- **THEN** the explicit game `left` command remains distinct from transport disconnect and Workspace Close
- **AND** Session membership remains controlled by Presence lifecycle

### Requirement: Session and Presence publications respect their ownership boundaries

`D20.Sessions.Server` SHALL publish accepted Session transitions to SessionChannel and SHALL delegate Workspace invalidation for phase, membership, attach, and detach changes to `D20Web.Workspace`. `D20Web.Presence` SHALL continue to publish only normalized online and offline messages and SHALL NOT own attachment mutations.

#### Scenario: Accepted phase transition changes Workspace eligibility

- **WHEN** an accepted Session transition changes eligible phase or retained member ids
- **THEN** the Session server publishes the updated Session to the SessionChannel topic
- **AND** `D20Web.Workspace` publishes actor discovery invalidation for affected member ids
- **AND** joined SessionChannel processes receive the update through their existing Phoenix subscription

#### Scenario: Presence status changes

- **WHEN** Presence reports an actor meta join or final-meta leave
- **THEN** `D20Web.Presence` publishes the normalized `online` or `offline` message to its private topic
- **AND** the Session runtime receives the message through `D20Web.Presence.subscribe/1`
- **AND** Presence does not call `D20.Sessions` or WorkspaceChannel

#### Scenario: Presence status changes only

- **WHEN** an attached member changes between online and offline
- **THEN** SessionChannel subscribers receive the updated projection
- **AND** actor Workspace discovery is not invalidated

#### Scenario: Attachment changes

- **WHEN** a Session process creates or removes an actor attachment
- **THEN** `D20Web.Workspace` invalidates discovery for that actor
- **AND** Presence does not publish or mutate the attachment

### Requirement: Workspace derives sessions from durable membership

WorkspaceChannel SHALL report every live configured in-progress or finished Session returned by the authenticated actor's attachment Registry lookup. The actor SHALL also remain a retained Session member. Waiting, missing, unconfigured, non-member, and detached Sessions SHALL remain excluded independently of online or offline status.

#### Scenario: Offline attached member joins WorkspaceChannel

- **GIVEN** an actor is an offline retained member with an active attachment
- **WHEN** the actor joins WorkspaceChannel
- **THEN** the complete snapshot includes that Session

#### Scenario: Offline detached member joins WorkspaceChannel

- **GIVEN** an actor remains an offline retained member without an attachment
- **WHEN** the actor joins WorkspaceChannel
- **THEN** the complete snapshot excludes that Session

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
- **AND** Workspace mounts the reported in-progress iframe from retained membership and attachment
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

The client SHALL continue to avoid browser storage. After a full document reload, a retained actor attachment SHALL restore its eligible live Session, while a prior explicit Close SHALL remain absent until direct re-entry recreates the attachment.

#### Scenario: Actor reloads an attached game

- **WHEN** reload temporarily changes the retained member from online to offline
- **THEN** the attachment remains registered
- **AND** the new snapshot contains the Session
- **AND** the remounted iframe rejoins and returns Presence online

#### Scenario: Actor reloads after explicit Close

- **WHEN** a detached actor creates a fresh WorkspaceChannel
- **THEN** the new snapshot excludes the retained Session
- **AND** client state does not recreate it

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
