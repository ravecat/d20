## MODIFIED Requirements

### Requirement: BGG metadata is optional enrichment
The system SHALL use successfully resolved BGG metadata as a persisted game's display metadata. Failure to resolve BGG metadata MUST NOT change whether the local game exists or whether its persisted launch policy is available.

#### Scenario: BGG metadata is available
- **WHEN** BGG returns valid metadata for a persisted game
- **THEN** the system returns the BGG display fields without deriving a public game slug
- **AND** local id, implementation stage, enabled state, engine, and Session behavior remain locally defined

#### Scenario: BGG metadata request fails
- **WHEN** BGG returns an HTTP error, times out, or cannot be reached
- **THEN** the system returns the persisted game with empty fallback metadata

#### Scenario: BGG metadata cannot be parsed
- **WHEN** BGG returns a response that cannot be parsed
- **THEN** the system returns the persisted game with empty fallback metadata
- **AND** the provider failure does not become a game-not-found result

#### Scenario: BGG omits one game from a batch
- **WHEN** a batch response resolves some persisted games but omits another
- **THEN** resolved metadata is preserved for present games
- **AND** each omitted game receives empty fallback metadata

### Requirement: Catalog remains complete during metadata degradation
The home catalog SHALL include every valid persisted game in implementation-stage and K-sortable TypeID order when BGG enrichment is wholly or partially unavailable. Each entry SHALL preserve its `game` TypeID, implementation stage, and empty-field preview behavior.

#### Scenario: Catalog loads without BGG credentials
- **WHEN** a user requests the home page without configured BGG credentials
- **THEN** the response is successful
- **AND** every persisted game appears with local id, implementation stage, and empty metadata

#### Scenario: Catalog loads during a BGG outage
- **WHEN** the catalog metadata request fails upstream
- **THEN** the response is successful
- **AND** the catalog is not replaced with an empty list

#### Scenario: Fallback catalog card has no provider metadata
- **WHEN** a catalog entry has empty fallback metadata
- **THEN** its card links through `/games/:game_id`
- **AND** remains keyboard accessible through the generic accessible label
- **AND** renders the non-image preview state without requiring a display name

### Requirement: Registered detail pages remain available during metadata degradation
The system SHALL render the detail page for every persisted local game id even when BGG enrichment is unavailable. Session creation and existing-session connection SHALL depend on persisted game bindings and Session runtime, not on external display metadata.

#### Scenario: Released game detail loads without BGG credentials
- **WHEN** a user requests Koala Rescue Club's `/games/:game_id` TypeID route without configured BGG credentials
- **THEN** the response renders the persisted Koala Rescue Club detail successfully
- **AND** retains its launch controls when enabled and otherwise launchable

#### Scenario: Persisted detail loads during an upstream failure
- **WHEN** a user requests a persisted game detail and BGG enrichment fails
- **THEN** `/games/:game_id` renders optional-field fallback states without a display name
- **AND** the response is not `404 Not Found`

#### Scenario: Existing session reconnects without BGG metadata
- **WHEN** a user requests a persisted game detail with a valid matching Session while BGG is unavailable
- **THEN** the page receives the existing Session data
- **AND** the Session remains usable

#### Scenario: Unknown valid game id is requested
- **WHEN** a user requests a well-formed `game` TypeID absent from persistence
- **THEN** the system returns `404 Not Found`

#### Scenario: Malformed or wrong-prefix game id is requested
- **WHEN** a user requests a malformed TypeID or a valid TypeID whose prefix is not `game`
- **THEN** TypeID/Ecto casting and Phoenix.Ecto exception mapping return `400 Bad Request`
- **AND** the system does not attempt runtime metadata enrichment
