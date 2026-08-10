# game-session-creation-attrs Specification

## Purpose
Define how game engines declare, validate, initialize, and present session creation attributes so the shell can render portable launch forms while preserving server-authoritative game setup.

## Requirements
### Requirement: Games declare session creation attrs
The system SHALL allow each game engine to declare the attrs required to create a session for that game through its Ecto changeset.

#### Scenario: Game declares creation attrs
- **WHEN** the shell renders `/games/:slug` before a launchable session exists
- **THEN** the shell obtains the creation attrs changeset from the resolved game engine
- **AND** the shell includes a `schema` prop containing JSON Schema generated from that changeset
- **AND** the schema root contains the declared creation defaults derived from the changeset data

#### Scenario: Game has no creation attrs
- **WHEN** a launchable game engine returns a changeset with no fields
- **THEN** the shell provides an object JSON Schema with no properties and an empty object default
- **AND** the shell does not render game-specific creation controls

#### Scenario: Launch is unavailable
- **WHEN** the resolved game cannot launch a session
- **THEN** the shell provides `schema: null`
- **AND** the client does not initialize an SJSF form

#### Scenario: Registry does not own creation attrs
- **WHEN** the shell resolves a game from the registry
- **THEN** the registry provides operational game bindings such as slug, engine, BGG id, and sandbox
- **AND** the registry does not provide game-specific creation attrs or validation rules

### Requirement: Game creation forms use a JSON Schema transport
The system SHALL represent launchable game creation controls with JSON Schema generated from the game changeset at the game page boundary.

#### Scenario: Enum creation field is described
- **WHEN** a game changeset contains a supported `Ecto.Enum` field
- **THEN** the form schema describes the field with its dumped enum values
- **AND** SJSF renders the available values as native radio choices by default
- **AND** the field submits the selected typed enum value

#### Scenario: Boolean creation fields are described
- **WHEN** a game changeset contains supported boolean fields
- **THEN** the form schema describes those fields as booleans
- **AND** SJSF renders boolean controls that submit typed values

#### Scenario: Required fields are described
- **WHEN** a supported changeset field is present in the changeset required metadata
- **THEN** the form schema includes that property name in its required array
- **AND** SJSF applies the corresponding required constraint

### Requirement: Game creation schemas preserve changeset defaults
The system SHALL encode game-defined new-session defaults from changeset data in the generated JSON Schema.

#### Scenario: Enum default selects a choice
- **WHEN** an enum creation field has a default in changeset data
- **THEN** the form schema root `default` contains its JSON-serializable value
- **AND** the matching client choice is initially selected

#### Scenario: Boolean defaults initialize controls
- **WHEN** boolean creation fields have defaults in changeset data
- **THEN** the form schema root `default` contains those values
- **AND** the matching client controls reflect those values before interaction

#### Scenario: Schema prop is the schema
- **WHEN** the shell derives a creation form from a game changeset
- **THEN** the `schema` prop is the JSON Schema itself
- **AND** the shell does not wrap it in separate `schema` and `initial` members

### Requirement: JSON Schema migration preserves session submission
The system SHALL preserve the existing Inertia session creation request and server validation behavior while changing the page form description.

#### Scenario: Selected values create a session
- **WHEN** a user submits controls rendered from the game form schema
- **THEN** SJSF passes the typed form value to the Inertia integration
- **AND** the client posts the same flat game attrs to `POST /games/:slug/sessions`
- **AND** the game changeset remains authoritative for casting and validation

#### Scenario: Invalid attrs remain visible as server errors
- **WHEN** the server rejects submitted game attrs
- **THEN** no session process starts
- **AND** the Inertia integration maps the server error to the corresponding SJSF field path

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

### Requirement: Waiting-room start does not redefine creation attrs
The system SHALL collect game creation attrs before creating the session and SHALL NOT expose a second descriptor-driven setup form in the waiting room.

#### Scenario: Owner starts a created session
- **WHEN** the session owner activates Start in the waiting room
- **THEN** the client sends the `start` command with an empty attrs object
- **AND** the client does not read an `attrs` field from the session projection

### Requirement: Game creation forms integrate with the shell visual language
The client SHALL present SJSF-generated game creation controls with the shell's shared form styling while preserving their native semantics and accessible states.

#### Scenario: Launch form is ready for interaction
- **WHEN** SJSF renders a launchable game's creation form
- **THEN** the form initializes with a working ID builder and renders without a client error
- **AND** generated controls use the shell's theme colors, borders, typography, and focus treatment
- **AND** the primary submit action spans the available form width
- **AND** the primary submit action is labeled `Play`

#### Scenario: Launch form is displayed on a narrow viewport
- **WHEN** the game page is displayed on a supported narrow viewport
- **THEN** the generated form remains within the activation panel without horizontal overflow

#### Scenario: Multiple-choice controls adapt to available space
- **WHEN** SJSF renders a group of radio or checkbox choices
- **THEN** each choice occupies a separate full-width row
- **AND** each choice row uses the same minimum interaction height as the submit action
- **AND** long choice labels wrap without causing horizontal overflow

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
