## RENAMED Requirements

- FROM: `Game detail page resolves registered games`
- TO: `Game detail page resolves persisted games by slug`

## MODIFIED Requirements

### Requirement: Catalog tile opens game detail page
The system SHALL allow users to open a persisted game's detail page by activating its catalog tile, using the game's required stored slug as the public route identity.

#### Scenario: Tile click navigates by persisted slug
- **WHEN** the user activates the Qwinto tile
- **THEN** the system navigates to `/games/qwinto`

#### Scenario: Tile target does not use BGG id or TypeID
- **WHEN** Qwinto has BGG id `183006` and an environment-local `game` TypeID
- **THEN** its tile target remains `/games/qwinto`

#### Scenario: Tile has no runtime metadata
- **WHEN** Qwinto metadata is unavailable
- **THEN** its tile still navigates through persisted slug `qwinto`

### Requirement: Game detail page resolves persisted games by slug
The system SHALL resolve `GET /games/:slug` from required persisted game slug. The detail Inertia props SHALL expose the loaded row's string `id`, string `slug`, and current `stage`. Internal Session matching SHALL continue using the loaded TypeID.

#### Scenario: Persisted detail is found
- **WHEN** the user opens `/games/qwinto`
- **THEN** the system loads the persisted Qwinto row by slug
- **AND** renders the game detail page with its TypeID and slug

#### Scenario: Unknown detail slug is not found
- **WHEN** the user opens `/games/missing`
- **THEN** the system returns `404 Not Found`

#### Scenario: TypeID is supplied as public route value
- **WHEN** a user requests a generated environment-local TypeID through `/games/:slug`
- **THEN** no persisted slug matches it
- **AND** the system returns `404 Not Found`

### Requirement: Game detail page uses runtime metadata
The system SHALL use runtime metadata for game detail presentation fields when metadata is available without deriving, replacing, or canonicalizing persisted slug.

#### Scenario: Detail page renders runtime title
- **WHEN** persisted slug `qwinto` resolves runtime title `Qwinto`
- **THEN** `/games/qwinto` presents `Qwinto`

#### Scenario: Detail page renders runtime preview image
- **WHEN** runtime metadata includes a preview image URL
- **THEN** the detail page presents that image as the game preview

#### Scenario: Detail page renders runtime description
- **WHEN** runtime metadata includes a description
- **THEN** the detail page presents that description

#### Scenario: Runtime name changes
- **WHEN** BGG returns a different title for persisted slug `qwinto`
- **THEN** the page may present the new title
- **AND** its canonical URL remains `/games/qwinto`

#### Scenario: Runtime name is unavailable
- **WHEN** persisted slug `qwinto` has no usable runtime name
- **THEN** `/games/qwinto` remains available with fallback presentation
