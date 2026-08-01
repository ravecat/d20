## ADDED Requirements

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

## MODIFIED Requirements

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

### Requirement: Presence owns Session membership admission

Normalized Presence `online` updates SHALL add or refresh Session membership and SHALL attempt game admission through the existing internal game `join` command. Normalized `offline` updates SHALL only mark an existing member offline and SHALL NOT remove Session membership or change game player state.

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

#### Scenario: Current tab dismisses its final game frame

- **GIVEN** an actor has exactly one Presence meta for a Session
- **WHEN** Workspace dismissal unmounts that iframe and its SessionChannel disconnects
- **THEN** Presence emits the final-meta offline transition
- **AND** the member remains in `session.members` with `offline` status
- **AND** game player state remains unchanged

#### Scenario: One of multiple game frames is dismissed

- **GIVEN** an actor has more than one Presence meta for a Session
- **WHEN** one Workspace instance dismisses its iframe
- **THEN** Presence emits no offline transition while another meta remains
- **AND** the member remains online

### Requirement: Public session contracts derive admission from channel presence

The public Session AsyncAPI contracts SHALL describe Phoenix channel join and Presence tracking as the trigger for game admission and SHALL NOT require a client-sent game `join` operation.

#### Scenario: Client implements the declared session protocol

- **WHEN** a client joins `session:{session_id}`
- **THEN** the server tracks the actor through Presence and attempts game admission
- **AND** the client does not send a separate `join` event

#### Scenario: Client intentionally leaves game player state

- **WHEN** the supported game workflow requires intentional game departure
- **THEN** the explicit game `left` command remains distinct from transport disconnect and Workspace window dismissal
- **AND** Session membership remains controlled by Presence lifecycle

## REMOVED Requirements

### Requirement: Workspace close explicitly removes participation

**Reason**: A window close is browser-local presentation intent and cannot reliably distinguish voluntary departure from final-tab teardown or transport loss. Deleting Session membership also conflicts with Presence-owned status and resumable Workspace discovery.

**Migration**: Workspace Close locally unmounts the iframe. Phoenix Presence marks the actor offline only after the final SessionChannel meta leaves, while `session.members` remains intact.
