# game-metadata-fallback Specification

## Purpose
Define how persisted games and their user-facing surfaces remain available when BoardGameGeek enrichment is unavailable.
## Requirements
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

### Requirement: Missing BGG credentials are supported outside production
The application SHALL start and serve persisted games outside production when `BGG_API_KEY` is absent or empty. Production startup MUST fail when usable BGG credentials are absent. The BGG source adapter SHALL return an explicit configuration error without sending an external request when usable credentials are absent at runtime.

#### Scenario: Development application starts without a BGG key
- **WHEN** the application starts outside production without `BGG_API_KEY`
- **THEN** startup succeeds
- **AND** BGG-backed enrichment operates in degraded mode

#### Scenario: Production application starts without a BGG key
- **WHEN** the application starts in production without a non-empty `BGG_API_KEY`
- **THEN** startup fails with a configuration error

#### Scenario: Metadata is requested without a BGG key outside production
- **WHEN** metadata enrichment is requested outside production while `BGG_API_KEY` is absent or empty
- **THEN** no request is sent to BGG
- **AND** persisted games are resolved with empty fallback metadata

### Requirement: Catalog remains complete during metadata degradation
The catalog listing SHALL retain every selected valid game within its database result limit when BGG enrichment is wholly or partially unavailable. The home projection SHALL continue to select `Playable games` from authoritative local launch facts, place up to 32 other selected environment-visible persisted records exactly once in the flat `games` array, and preserve each selected record's local id, stage, collection membership, response order, and fallback preview behavior. Metadata failure MUST NOT alter carousel item counts, slide membership, or the exactly-one-accessible-link rule. `Games.list/1` SHALL handle the provider result and per-record metadata schema validation inline, using each selected row's `bgg_id`, without additional `:available`/`:unavailable` arguments or single-use catalog metadata helpers. A failed batch SHALL emit one catalog-scope fallback warning, not missing-game warnings for every row; successful batches with omitted or invalid metadata SHALL log and fall back only for the affected records.

#### Scenario: Home loads without BGG credentials
- **WHEN** a user requests the home page without configured BGG credentials outside production
- **THEN** the response is successful
- **AND** playable selection still follows local launch policy
- **AND** every record selected by the bounded browse query still appears once in games
- **AND** visible canonical cards use empty fallback metadata

#### Scenario: Home loads during a BGG outage
- **WHEN** either home list query cannot enrich its returned records
- **THEN** neither home collection is replaced with an empty list solely because of that failure
- **AND** server-selected membership and order remain based on local records and query options

#### Scenario: Fallback playable card has no provider metadata
- **WHEN** a playable entry has empty fallback metadata
- **THEN** its compact landscape card remains linked through `/games/:slug`
- **AND** it remains keyboard accessible through the generic accessible label
- **AND** launchable collection membership is unchanged

#### Scenario: Fallback browse card has no provider metadata
- **WHEN** a browse entry has empty fallback metadata
- **THEN** its canonical Games card remains linked through `/games/:slug`
- **AND** hero or compact presentation renders the non-image landscape fallback without requiring a display name
- **AND** its selected array membership and derived slide position are unchanged

#### Scenario: Fallback entry is represented at a loop boundary
- **WHEN** a fallback card has a visual sentinel or repeated row representation
- **THEN** only its canonical fallback card exposes an accessible local link
- **AND** visual repetition does not require provider metadata

#### Scenario: Successful batch omits one selected game
- **WHEN** a successful batch includes valid metadata for some selected games but omits another selected bgg id
- **THEN** valid records retain their provider metadata and the omitted record retains empty schema metadata
- **AND** one fallback warning identifies the omitted local game without changing any selected id or stage

### Requirement: Registered detail pages remain available during metadata degradation
The system SHALL render the detail page for every persisted local game id even when BGG enrichment is unavailable. Session creation and existing-session connection SHALL depend on persisted game bindings and Session runtime, not on external display metadata.

#### Scenario: Released game detail loads without BGG credentials
- **WHEN** a user requests Koala Rescue Club's `/games/:slug` route without configured BGG credentials
- **THEN** the response renders the persisted Koala Rescue Club detail successfully
- **AND** retains its launch controls when enabled and otherwise launchable

#### Scenario: Persisted detail loads during an upstream failure
- **WHEN** a user requests a persisted game detail and BGG enrichment fails
- **THEN** `/games/:slug` renders optional-field fallback states without a display name
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

### Requirement: Metadata degradation is observable without exposing credentials
The system SHALL record metadata enrichment failures with enough provider and reason context for diagnosis. Logs and client props MUST NOT contain the BGG API key or authorization header.

#### Scenario: BGG enrichment fails
- **WHEN** a persisted game falls back because BGG enrichment failed
- **THEN** the server records the provider failure reason
- **AND** neither logs nor rendered props expose BGG credentials
