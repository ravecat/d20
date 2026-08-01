## MODIFIED Requirements

### Requirement: Session participation is independent of transport Presence

The Session runtime SHALL retain an admitted actor in `session.members` until an explicit membership removal, Session finish policy, or Session process termination. Closing a tab, losing a socket, or removing the final Phoenix Presence meta SHALL NOT remove that actor from membership or game player state.

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

Normalized Presence `online` updates SHALL add or refresh Session membership and SHALL attempt game admission through the existing internal game `join` command. Normalized `offline` updates SHALL only mark an existing member offline and SHALL NOT change game player state.

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

#### Scenario: Delayed offline arrives after explicit close

- **GIVEN** explicit Workspace close has removed the actor from membership
- **WHEN** the iframe teardown produces a delayed final Presence leave
- **THEN** the actor is not recreated
- **AND** no game command is dispatched

## ADDED Requirements

### Requirement: Public session contracts derive admission from channel presence

The public Session AsyncAPI contracts SHALL describe Phoenix channel join and Presence tracking as the trigger for game admission and SHALL NOT require a client-sent game `join` operation.

#### Scenario: Client implements the declared session protocol

- **WHEN** a client joins `session:{session_id}`
- **THEN** the server tracks the actor through Presence and attempts game admission
- **AND** the client does not send a separate `join` event

#### Scenario: Client intentionally leaves game player state

- **WHEN** the supported workflow requires intentional game departure
- **THEN** the explicit game `left` command remains distinct from transport disconnect and Workspace membership removal
