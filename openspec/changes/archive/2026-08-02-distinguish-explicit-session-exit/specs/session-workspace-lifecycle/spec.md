## RENAMED Requirements

- FROM: `Generic Session membership API is Presence-only`
- TO: `Generic Session lifecycle separates membership Presence and attachment`

## MODIFIED Requirements

### Requirement: Session participation is independent of transport Presence

The Session runtime SHALL retain an actor in `session.members` until the Session process terminates. Closing a browser tab, losing a socket, removing the final Phoenix Presence meta, explicitly closing a Workspace game window, or issuing a game-specific `left` command SHALL NOT delete that actor's member record or game player state. Workspace attachment SHALL be tracked separately from retained membership and Presence status.

#### Scenario: Final Presence connection closes

- **GIVEN** an actor is an attached online member of an in-progress Session
- **WHEN** the actor's final SessionChannel Presence meta leaves without explicit Workspace Close
- **THEN** the actor remains in `session.members` with `status: offline`
- **AND** the actor-to-Session attachment remains registered
- **AND** the game engine receives no membership removal command

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

#### Scenario: Game exposes intentional departure

- **WHEN** a game supports an explicit domain `left` command
- **THEN** that command can update game player state according to game rules
- **AND** it remains distinct from Workspace detach

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

### Requirement: Presence owns Session membership admission

Normalized Presence online updates SHALL add or refresh retained Session membership and attempt game admission through the existing internal game `join` command. Normalized offline updates SHALL only mark an existing member offline and SHALL NOT remove retained membership, actor attachment, or game player state. Accepted Workspace Close SHALL detach before terminating matching SessionChannels.

#### Scenario: Online actor is accepted as a player

- **WHEN** the Session process receives an online status update for an attached actor allowed by game rules
- **THEN** retained membership and profile metadata are updated
- **AND** the game engine receives internal `join`

#### Scenario: Final Presence meta leaves ordinarily

- **WHEN** the final SessionChannel Presence meta leaves without Workspace Close
- **THEN** the retained member becomes offline
- **AND** the attachment and game player state remain unchanged

#### Scenario: Actor closes all attachments to one Session

- **WHEN** Workspace accepts Close for the actor and Session
- **THEN** the Session process detaches that actor first
- **AND** every matching actor SessionChannel leaves
- **AND** the retained member is offline
- **AND** game player state remains unchanged

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

### Requirement: Session and Presence publications respect their ownership boundaries

`D20.Game.Server` SHALL publish accepted Session transitions to SessionChannel and SHALL delegate Workspace invalidation for phase, membership, attach, and detach changes to `D20Web.Workspace`. `D20Web.Presence` SHALL continue to publish only normalized online and offline messages and SHALL NOT own attachment mutations.

#### Scenario: Presence status changes only

- **WHEN** an attached member changes between online and offline
- **THEN** SessionChannel receives the updated projection
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

### Requirement: Full document reload restores live memberships

The client SHALL continue to avoid browser storage. After a full document reload, a retained actor attachment SHALL restore its eligible live Session, while a prior explicit Close SHALL remain absent until direct re-entry recreates the attachment.

#### Scenario: Actor reloads an attached game

- **WHEN** reload temporarily changes the retained member from online to offline
- **THEN** the attachment remains registered
- **AND** the new Workspace snapshot contains the Session
- **AND** the remounted iframe rejoins and returns Presence online

#### Scenario: Actor reloads after explicit Close

- **WHEN** a detached actor creates a fresh WorkspaceChannel
- **THEN** the new snapshot excludes the retained Session
- **AND** client state does not recreate it
