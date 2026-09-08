## MODIFIED Requirements

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
