## RENAMED Requirements

- FROM: `Implemented games are declared in a game registry`
- TO: `Games are persisted with internal and external identity`
- FROM: `Game lookup uses the internal slug`
- TO: `Game lookup separates external slug and local id`
- FROM: `Session engine lookup uses the game registry`
- TO: `Session engine lookup uses the persisted game record`

## MODIFIED Requirements

### Requirement: Games are persisted with internal and external identity
The system SHALL declare every catalog game as a persisted row with an environment-local string-backed `game` TypeID primary key and a required operator-assigned slug. Each row SHALL contain only the identities and operational bindings `id`, `slug`, `bgg_id`, `stage`, `enabled`, and optional `engine`; it SHALL NOT contain iframe sandbox policy or provider-derived presentation metadata. Slug SHALL remain stable across environments and SHALL NOT be derived from TypeID, BoardGameGeek metadata, or engine module name.

#### Scenario: Persisted record declares a playable game
- **WHEN** the application loads the local Qwinto row
- **THEN** the row includes an environment-local `game` TypeID
- **AND** slug `qwinto`
- **AND** engine `D20.Qwinto.Game`
- **AND** BGG id `183006`
- **AND** stage `released`
- **AND** enabled true
- **AND** it does not include iframe sandbox policy

#### Scenario: Planned game is persisted
- **WHEN** a planned game has no engine or client repository yet
- **THEN** its persisted row still has a required unique slug
- **AND** the slug can identify future engine, repository, and deployment work

#### Scenario: Persisted record excludes provider-derived metadata
- **WHEN** the application loads any game row
- **THEN** title, preview URL, description, player counts, and other BGG-derived fields are absent from persisted game data
- **AND** slug remains a local operational field rather than runtime metadata

### Requirement: Game lookup separates external slug and local id
The system SHALL resolve catalog pages and public game navigation by persisted slug. It SHALL resolve database relations, Session ownership, engine selection after route resolution, Workspace descriptors, module HTTP requests, socket scope, and signed module claims by canonical `game` TypeID. The Game schema SHALL own both types of lookup without treating either BGG id or runtime title as identity.

#### Scenario: Existing game slug is found
- **WHEN** a caller fetches persisted slug `qwinto`
- **THEN** the system returns the persisted Qwinto game and its local TypeID

#### Scenario: Unknown game slug is rejected
- **WHEN** a caller fetches a slug absent from persistence
- **THEN** the system returns a game-not-found result

#### Scenario: Existing local id is found
- **WHEN** an internal runtime boundary fetches Qwinto's persisted `game` TypeID
- **THEN** the system returns the same persisted Qwinto row

#### Scenario: Database is recreated
- **WHEN** another environment assigns a different TypeID to the Qwinto row
- **THEN** its slug remains `qwinto`
- **AND** its public game route and module host remain unchanged

#### Scenario: BGG name changes
- **WHEN** the provider-derived Qwinto name changes
- **THEN** both its persisted slug and local TypeID remain unchanged

### Requirement: Session engine lookup uses the persisted game record
The system SHALL resolve the engine for new Session creation from the persisted game selected by slug at the browser boundary or by TypeID at the module boundary, then SHALL capture that loaded module and the game's TypeID in the new Session process.

#### Scenario: Engine is resolved from a slug route
- **WHEN** a user creates a Session from `/games/qwinto`
- **THEN** the system resolves the persisted Qwinto row by slug
- **AND** loads `D20.Qwinto.Game` from engine integer `4`
- **AND** creates the Session under Qwinto's local TypeID

#### Scenario: Engine is changed while a Session runs
- **WHEN** an operator edits a game's engine after a Session has started
- **THEN** the running Session retains its captured TypeID and engine
- **AND** only later Session creation uses the edited engine

#### Scenario: Required engine is absent
- **WHEN** a write attempts to persist released or in-development stage without an engine
- **THEN** record validation rejects the configuration before Session creation

### Requirement: BGG id is an external metadata binding
The system SHALL treat `bgg_id` as an editable unique positive BGG metadata binding and SHALL NOT use it as application, route, Session, or deployment identity.

#### Scenario: Metadata lookup uses BGG id
- **WHEN** runtime metadata is requested for the persisted Qwinto game
- **THEN** the system requests BGG id `183006`

#### Scenario: BGG id is corrected
- **WHEN** an administrator changes the BGG id of a persisted game
- **THEN** later metadata reads use the new BGG id
- **AND** slug, public routes, iframe host, TypeID, running Sessions, and Workspace association remain unchanged
