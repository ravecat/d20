## RENAMED Requirements

- FROM: `Games page lists playable registry games`
- TO: `Games page lists persisted catalog games`

## MODIFIED Requirements

### Requirement: Games page lists persisted catalog games
The system SHALL render the home game catalog from persisted `games` rows enriched with runtime metadata. Each catalog Inertia entry SHALL expose environment-local identity as string `id` containing the canonical `game` TypeID, stable external identity as string `slug`, current implementation stage as `stage`, and runtime `game` metadata.

#### Scenario: Persisted game appears in the catalog
- **WHEN** the persisted Qwinto row has slug `qwinto` and a canonical `game` TypeID
- **THEN** the catalog includes one game tile carrying both identities

#### Scenario: Provider-only game is not listed
- **WHEN** BGG contains a game that has no persisted D20 game row
- **THEN** the catalog does not list that game

#### Scenario: Disabled game remains listed
- **WHEN** a persisted game has enabled false
- **THEN** the catalog still includes its tile and slug-based detail link

### Requirement: Catalog entries link by internal slug
The system SHALL link every persisted catalog entry to `/games/:slug` using its required stored slug. It SHALL NOT derive route slug from BGG title, BGG id, engine module, or environment-local TypeID.

#### Scenario: Catalog link is generated for a persisted game
- **WHEN** the catalog renders the persisted Qwinto row
- **THEN** the tile links to `/games/qwinto`

#### Scenario: Runtime metadata is unavailable
- **WHEN** the persisted Qwinto row has empty fallback metadata
- **THEN** its tile still links to `/games/qwinto`
- **AND** remains keyboard accessible

#### Scenario: BGG binding or name changes
- **WHEN** an operator edits Qwinto's BGG binding or BGG returns a different presentation name
- **THEN** its catalog link remains `/games/qwinto`
- **AND** its TypeID and slug remain separate from provider metadata
