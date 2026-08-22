## MODIFIED Requirements

### Requirement: The iframe client consumes the caller-specific D20 contract

The Next Station: London iframe client SHALL bootstrap `next-station-london` through the D20 SDK, SHALL replace its state from connect and projection events, and SHALL forward `draw` and `pass` payloads without deriving or weakening server legality.

#### Scenario: A projection arrives

- **WHEN** the D20 shell connects the iframe or publishes an updated caller-specific projection
- **THEN** the client replaces the displayed session, phase, permissions, legal options, networks, scores, and outcome with that projection
- **AND** it does not reconstruct hidden cards, another caller's legal options, participant order, or phase advancement

#### Scenario: A player confirms a route

- **WHEN** the pending caller selects a section or complete Double Section sequence exposed in `options` and confirms it during turn
- **THEN** the client sends `draw` with only the selected section endpoints and applicable power fields
- **AND** rendering coordinates or other client-only data are not included

### Requirement: The client presents every playable session state

The shared D20 shell SHALL present the ordinary owner start control with no game-specific start fields. After the outer session starts, the iframe client SHALL present reveal, active shared turn, submitted waiting, spectator viewing, four-round progress, scoring, multiplayer outcomes, solo ratings, action errors, and timeouts from the projection and SDK state.

#### Scenario: A solo owner starts through shared session controls

- **WHEN** one joined owner is in the waiting session phase and the game is in setup
- **THEN** the caller-specific projection omits declarative start-form attributes
- **AND** the shared `SessionPanel` sends an empty `start` payload
- **AND** the iframe remains unmounted until the outer session enters `in_progress`
- **AND** the game enters reveal and the server assigns the random pencil cycle during the first reveal

#### Scenario: A station instruction is being revealed

- **WHEN** the projection phase is reveal
- **THEN** the client exposes no route mutation controls
- **AND** it presents the state as station reveal rather than a player turn or a generic preparation step

#### Scenario: A submitted player waits

- **WHEN** the caller has submitted the current turn while another frozen player remains pending
- **THEN** route mutation controls are replaced with a waiting state
- **AND** committed networks and the shared instruction remain visible

#### Scenario: A spectator views the session

- **WHEN** the caller is not a frozen player
- **THEN** the client exposes no mutation controls
- **AND** allows viewing one existing player network without inventing a roster order
