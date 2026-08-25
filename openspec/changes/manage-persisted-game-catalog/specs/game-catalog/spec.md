## RENAMED Requirements

- FROM: `Games page lists playable registry games`
- TO: `Games page lists persisted catalog games`
- FROM: `Catalog entries link by internal slug`
- TO: `Catalog entries link by stable local id`

## MODIFIED Requirements

### Requirement: Games page lists persisted catalog games
The system SHALL render the home game catalog from persisted `games` rows enriched with runtime metadata. Each catalog Inertia entry SHALL expose stable local game identity as string `id` containing the canonical `game` TypeID, current implementation stage as `stage`, and runtime `game` metadata without a public slug field.

#### Scenario: Persisted game appears in the catalog
- **WHEN** a persisted Qwinto row has a canonical `game` TypeID
- **THEN** the catalog includes a game tile whose stable identity is that TypeID

#### Scenario: Provider-only game is not listed
- **WHEN** BGG contains a game that has no persisted D20 game row
- **THEN** the catalog does not list that game

#### Scenario: Disabled game remains listed
- **WHEN** a persisted game has enabled false
- **THEN** the catalog still includes its tile and detail link

### Requirement: Catalog entries link by stable local id
The system SHALL link every catalog entry directly to `/games/:game_id` and SHALL NOT append or expose a BGG-derived public slug.

#### Scenario: Runtime name is available
- **WHEN** a persisted `game` TypeID resolves the runtime name `Qwinto`
- **THEN** its catalog tile links to `/games/:game_id` using that full TypeID
- **AND** the name remains presentation only

#### Scenario: Runtime metadata is unavailable
- **WHEN** a persisted `game` TypeID has empty fallback metadata
- **THEN** its catalog tile still links to `/games/:game_id` using that full TypeID
- **AND** it remains keyboard accessible

#### Scenario: BGG binding changes
- **WHEN** a later response resolves a different presentation name for a persisted `game` TypeID
- **THEN** its catalog link retains the same full TypeID
- **AND** local game identity remains unchanged
