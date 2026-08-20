# game-detail Specification

## Purpose
Define how users navigate to and view registered game detail pages by internal slug.

## Requirements
### Requirement: Catalog tile opens game detail page
The system SHALL allow users to open a registered game's detail page by activating its tile in the `/games` catalog.

#### Scenario: Tile click navigates by internal slug
- **WHEN** the user activates the `qwinto` tile in the `/games` catalog
- **THEN** the system navigates to `/games/qwinto`

#### Scenario: Tile target does not use BGG id
- **WHEN** the `qwinto` registry entry has `bgg_id` `183006`
- **THEN** the catalog tile target remains `/games/qwinto`

### Requirement: Game detail page resolves registered games
The system SHALL render `/games/:slug` detail pages from implemented games declared in the game registry.

#### Scenario: Registered game detail page is found
- **WHEN** the user opens `/games/qwinto`
- **THEN** the system resolves `qwinto` from the game registry
- **AND** the system renders the game detail page

#### Scenario: Unknown game detail page is not found
- **WHEN** the user opens `/games/missing`
- **THEN** the system returns a not-found response

### Requirement: Game detail page uses runtime metadata
The system SHALL use runtime metadata for game detail presentation fields when metadata is available.

#### Scenario: Detail page renders runtime title
- **WHEN** runtime metadata for `qwinto` includes title `Qwinto`
- **THEN** the `/games/qwinto` detail page presents `Qwinto` as the game title

#### Scenario: Detail page renders runtime preview image
- **WHEN** runtime metadata for `qwinto` includes a preview image URL
- **THEN** the `/games/qwinto` detail page presents that image as the game preview

#### Scenario: Detail page renders runtime description
- **WHEN** runtime metadata for `qwinto` includes a description
- **THEN** the `/games/qwinto` detail page presents that description
