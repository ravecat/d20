## RENAMED Requirements

- FROM: `Implemented games are declared in a game registry`
- TO: `Games are persisted with stable local identity`
- FROM: `Game lookup uses the internal slug`
- TO: `Game lookup uses the stable local id`
- FROM: `Session engine lookup uses the game registry`
- TO: `Session engine lookup uses the persisted game record`

## MODIFIED Requirements

### Requirement: Games are persisted with stable local identity
The system SHALL declare catalog games as persisted rows keyed by string-backed TypeID `games.id` values with prefix `game`. Each row SHALL contain only the stable local identity and operational bindings `bgg_id`, `stage`, `enabled`, and optional `engine`; it SHALL NOT contain iframe sandbox policy or provider-derived presentation metadata.

#### Scenario: Persisted record declares a playable game
- **WHEN** the application loads the local Qwinto row by its `game` TypeID
- **THEN** the row includes engine `D20.Qwinto.Game`
- **AND** BGG id `183006`
- **AND** stage `released`
- **AND** enabled true
- **AND** it does not include a stored slug or iframe sandbox policy

#### Scenario: Persisted record excludes provider-derived metadata
- **WHEN** the application loads any game row
- **THEN** title, public slug, preview URL, description, player counts, and other BGG-derived fields are absent from persisted game data

### Requirement: Game lookup uses the stable local id
The system SHALL resolve games by canonical `game` TypeID `games.id` values across database, public route, Session, engine, Workspace, module, and token boundaries. The Game schema SHALL own the TypeID id type, and other contexts SHALL reference it directly. The system SHALL NOT derive or expose a public game slug.

#### Scenario: Existing local id is found
- **WHEN** a caller fetches Qwinto's persisted `game` TypeID
- **THEN** the system returns the persisted Qwinto game

#### Scenario: Unknown valid local id is rejected
- **WHEN** a caller fetches a well-formed `game` TypeID absent from persistence
- **THEN** the system returns a game-not-found result

#### Scenario: Malformed local id uses TypeID/Ecto casting
- **WHEN** a caller fetches a malformed TypeID or a valid TypeID whose prefix is not `game`
- **THEN** Ecto raises `Ecto.Query.CastError`
- **AND** Phoenix.Ecto maps that exception to `400 Bad Request` at the HTTP boundary

#### Scenario: BGG name changes
- **WHEN** the provider-derived Qwinto name changes
- **THEN** its persisted `game` TypeID remains unchanged

### Requirement: Session engine lookup uses the persisted game record
The system SHALL resolve the engine for new Session creation from the persisted game selected by local id and SHALL capture that loaded module in the new Session process.

#### Scenario: Engine is resolved for a new Session
- **WHEN** a new Session is created for Qwinto's persisted `game` TypeID
- **THEN** the system loads `D20.Qwinto.Game` from engine integer `4`
- **AND** validates it through `D20.Game.ensure_engine/1`

#### Scenario: Engine is changed while a Session runs
- **WHEN** an operator edits a game's engine after a Session has started
- **THEN** the running Session retains its captured engine
- **AND** only later Session creation uses the edited engine

#### Scenario: Required engine is absent
- **WHEN** a write attempts to persist released or in-development stage without an engine
- **THEN** record validation rejects the configuration before Session creation

### Requirement: BGG id is an external metadata binding
The system SHALL treat `bgg_id` as an editable unique positive BGG metadata binding and SHALL NOT use it as local application identity.

#### Scenario: Metadata lookup uses BGG id
- **WHEN** runtime metadata is requested for Qwinto's persisted `game` TypeID
- **THEN** the system requests BGG id `183006`

#### Scenario: BGG id is corrected
- **WHEN** an administrator changes the BGG id of a persisted game
- **THEN** later metadata reads use the new BGG id
- **AND** routes, running Sessions, Workspace association, and module identity remain bound to its unchanged `game` TypeID
