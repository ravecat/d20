# game-session-creation-attrs Specification

## Purpose
TBD - created by archiving change initialize-sessions-with-game-attrs. Update Purpose after archive.
## Requirements
### Requirement: Games declare session creation attrs
The system SHALL allow each game engine to declare the attrs required to create a session for that game.

#### Scenario: Game declares creation attrs
- **WHEN** the shell renders `/games/:slug` before a session exists
- **THEN** the shell obtains the creation attrs description from the resolved game engine
- **AND** the shell includes that description in the game page props

#### Scenario: Game has no creation attrs
- **WHEN** a game engine does not declare creation attrs
- **THEN** the shell treats the game as requiring no creation attrs
- **AND** the shell does not render game-specific creation controls

#### Scenario: Registry does not own creation attrs
- **WHEN** the shell resolves a game from the registry
- **THEN** the registry provides operational game bindings such as slug, engine, BGG id, and sandbox
- **AND** the registry does not provide game-specific creation attrs or validation rules

### Requirement: Session creation submits game attrs
The system SHALL submit game creation attrs with the request that creates a session.

#### Scenario: Play creates a session with attrs
- **WHEN** a user submits Play from `/games/:slug` with game creation controls filled
- **THEN** the client posts the selected attrs to `POST /games/:slug/sessions`
- **AND** the server uses those attrs while creating the session

#### Scenario: Created session URL remains shareable
- **WHEN** session creation succeeds
- **THEN** the server redirects to `/games/:slug?session=:id`
- **AND** the redirected page attaches the existing session instead of asking for creation attrs again

#### Scenario: Invalid attrs reject session creation
- **WHEN** a user submits attrs that the game engine rejects
- **THEN** the server does not start a session process
- **AND** the user remains on `/games/:slug` with a session creation error

### Requirement: Game initialization consumes creation attrs
The system SHALL pass validated session creation attrs into the game engine before the session process starts.

#### Scenario: Engine initializes from attrs
- **WHEN** the server creates a session for a game that supports creation attrs
- **THEN** the session initializes the hosted game state using those attrs
- **AND** the session process starts only after game initialization succeeds

#### Scenario: Engine without attrs rejects unexpected attrs
- **WHEN** the server creates a session for a game that does not support creation attrs
- **AND** the request includes non-empty attrs
- **THEN** the server rejects session creation

#### Scenario: Engine without attrs accepts empty attrs
- **WHEN** the server creates a session for a game that does not support creation attrs
- **AND** the request includes no attrs
- **THEN** the session initializes the game through the engine's default initialization path

### Requirement: Session start does not carry creation attrs
The system SHALL treat session start as a lifecycle transition for an already-created session, not as game setup input.

#### Scenario: Start sends no creation attrs
- **WHEN** the owner starts a waiting session
- **THEN** the client sends the channel `start` event without game creation attrs
- **AND** the session attempts to transition the already-initialized game into play

#### Scenario: Start cannot change creation attrs
- **WHEN** a waiting session was created with game creation attrs
- **AND** a later start command includes different attrs
- **THEN** the game ignores or rejects those creation attrs according to its command validation
- **AND** the initialized game setup remains unchanged

### Requirement: Koala Rescue Club sheet is a creation attr
The system SHALL select the Koala Rescue Club sheet during session creation.

#### Scenario: Koala session is created with a supported sheet
- **WHEN** a user creates a Koala Rescue Club session with sheet `dharug` or `yugambeh`
- **THEN** the initialized Koala game stores that selected sheet
- **AND** later joins allocate player sheets using that selected sheet

#### Scenario: Koala session rejects unsupported sheet
- **WHEN** a user creates a Koala Rescue Club session with an unsupported sheet
- **THEN** the server rejects session creation
- **AND** no Koala session process is started

#### Scenario: Koala start uses initialized sheet
- **WHEN** the owner starts a Koala Rescue Club session
- **THEN** the start command requires no `sheet` attr
- **AND** the game enters the roll phase using the sheet selected at session creation
