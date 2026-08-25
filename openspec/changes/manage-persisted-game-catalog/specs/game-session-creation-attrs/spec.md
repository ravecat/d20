## MODIFIED Requirements

### Requirement: Games declare session creation attrs
The system SHALL allow each engine selected by a persisted game to declare attrs required to create a Session through its Ecto changeset.

#### Scenario: Game declares creation attrs
- **WHEN** the shell renders an id-based detail before a launchable Session exists
- **THEN** it obtains the creation attrs changeset from the persisted game's resolved engine
- **AND** includes a `schema` prop containing JSON Schema generated from that changeset
- **AND** the schema root contains the declared creation defaults

#### Scenario: Game has no creation attrs
- **WHEN** a launchable engine returns a changeset with no fields
- **THEN** the shell provides an object JSON Schema with no properties and an empty object default
- **AND** renders no game-specific creation controls

#### Scenario: Launch is unavailable
- **WHEN** the persisted game cannot launch because of stage, environment, enabled, or engine
- **THEN** the shell provides `schema: null`
- **AND** the client does not initialize an SJSF form

#### Scenario: Persisted record does not own creation attrs
- **WHEN** the shell resolves a persisted game
- **THEN** the record provides local id, engine, BGG id, implementation stage, and enabled
- **AND** provides neither creation attrs nor iframe sandbox policy
- **AND** engine changeset validation remains authoritative

### Requirement: JSON Schema migration preserves session submission
The system SHALL preserve the existing Inertia Session creation request and server validation behavior while using the id-based game route.

#### Scenario: Selected values create a Session
- **WHEN** a user submits controls rendered from the game form schema
- **THEN** SJSF passes the typed value to Inertia
- **AND** the client posts the same flat attrs to `POST /games/:game_id/sessions`
- **AND** the captured engine changeset remains authoritative

#### Scenario: Invalid attrs remain visible as server errors
- **WHEN** the server rejects submitted attrs
- **THEN** no Session process starts
- **AND** the Inertia integration maps the error to the corresponding SJSF field path

### Requirement: Session creation submits game attrs
The system SHALL submit game creation attrs with the request that creates a Session for a stable local game id.

#### Scenario: Play creates a Session with attrs
- **WHEN** a user submits Play from an id-based detail route
- **THEN** the client posts selected attrs to `POST /games/:game_id/sessions`
- **AND** the server uses those attrs while creating the Session

#### Scenario: Created Session URL remains shareable
- **WHEN** Session creation succeeds
- **THEN** the server redirects with status 303 to `/games/:game_id?session=:id`
- **AND** the page attaches the existing Session instead of asking for creation attrs again

#### Scenario: Invalid attrs reject Session creation
- **WHEN** the selected engine rejects submitted attrs
- **THEN** the server starts no Session
- **AND** the user returns to the same local game id with creation errors
