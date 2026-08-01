## MODIFIED Requirements

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
