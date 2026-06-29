## ADDED Requirements

### Requirement: Games page lists playable registry games
The system SHALL render the `/games` game catalog from implemented games declared in the game registry.

#### Scenario: Registered game appears in the catalog
- **WHEN** `qwinto` is declared in the game registry
- **THEN** the `/games` catalog includes a game tile for `qwinto`

#### Scenario: Provider-only game is not listed
- **WHEN** BGG contains a game that is not declared in the game registry
- **THEN** the `/games` catalog does not list that game as playable

### Requirement: Catalog entries link by internal slug
The system SHALL link each catalog entry to the internal game route for its registry slug.

#### Scenario: Catalog link is generated for a registered game
- **WHEN** the `/games` page renders the catalog tile for `qwinto`
- **THEN** the tile links to `/games/qwinto`

### Requirement: Catalog game tiles include previews
The system SHALL render each `/games` catalog entry as a game tile with a preview area. The tile SHALL use runtime metadata for title and preview image when metadata is available, and SHALL render a non-provider fallback preview state when metadata does not include an image.

#### Scenario: Catalog renders runtime title
- **WHEN** runtime metadata for `qwinto` includes title `Qwinto`
- **THEN** the `/games` catalog tile presents `Qwinto` as the game title

#### Scenario: Catalog renders runtime preview image
- **WHEN** runtime metadata for `qwinto` includes a preview image URL
- **THEN** the `/games` catalog tile presents that image in the tile preview area

#### Scenario: Catalog renders fallback preview
- **WHEN** runtime metadata for `qwinto` does not include a preview image URL
- **THEN** the `/games` catalog tile still renders a preview area
- **AND** the preview area uses a fallback state that does not require a configured preview URL
