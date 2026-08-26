## RENAMED Requirements

- FROM: `Registry represents catalog availability`
- TO: `Persisted records represent release stage and enablement`
- FROM: `Catalog contains the requested games`
- TO: `Persisted catalog contains the migrated games`
- FROM: `Catalog entries expose availability and default order`
- TO: `Catalog entries expose release stage and default order`

## MODIFIED Requirements

### Requirement: Persisted records represent release stage and enablement
Every game SHALL have stage `planned`, `in_development`, or `released` and a separate boolean `enabled`. Released and in-development rows MUST have a valid engine; planned rows MAY omit or retain an engine. Enabled controls only whether a new Session may be created and MUST NOT control discoverability or existing Sessions.

#### Scenario: Released game is operationally bound
- **WHEN** a persisted game declares stage `released`
- **THEN** its engine is required

#### Scenario: In-development game is operationally bound
- **WHEN** a persisted game declares stage `in_development`
- **THEN** its engine is required

#### Scenario: Planned game has no engine
- **WHEN** a persisted game declares stage `planned` and engine null
- **THEN** the record is valid and discoverable
- **AND** new Session launch is unavailable

#### Scenario: Game is disabled
- **WHEN** any persisted game has enabled false
- **THEN** it remains discoverable with its stage unchanged
- **AND** no new Session may be created

### Requirement: Persisted catalog contains the migrated games
The catalog SHALL contain Fliptown, Koala Rescue Club, Next Station: London, Qwinto, Flip 7, Railroad Ink: Deep Blue Edition, Confusing Lands, Trails of Tucana, Shifting Stones, Trailblazers, Death Valley, Voyages, Sky Team, Qwixx, Nimalia, Lost Cities, Deep Sea Adventure, Waypoints, and Aquamarine with generated `game` TypeIDs and their former BGG bindings.

#### Scenario: Migrated home catalog is loaded
- **WHEN** the application resolves persisted games for the home page
- **THEN** all nineteen migrated games are included
- **AND** none depends on a checked-in game registry entry

### Requirement: Catalog entries expose release stage and default order
`D20.Games.list/0` SHALL include the local `game` TypeID, stage, and resolved display metadata without a public game slug. It SHALL return released games first, in-development games second, and planned games last, ordered by the K-sortable TypeID within each stage.

#### Scenario: Catalog list is ordered by stage
- **WHEN** `D20.Games.list/0` resolves records with mixed stages
- **THEN** all released entries precede all in-development entries
- **AND** all in-development entries precede all planned entries
- **AND** entries in one stage are ordered by their `game` TypeIDs

#### Scenario: Released stage is serialized
- **WHEN** Qwinto is rendered in home-page props
- **THEN** its entry includes `stage` `released`

#### Scenario: Planned stage is serialized
- **WHEN** Voyages is rendered in home-page props
- **THEN** its entry includes `stage` `planned`

### Requirement: Home cards communicate availability
The home page SHALL render games in the order received from the backend without client-side filtering, grouping, or sorting. It SHALL display released games with the full visual treatment and visually mute in-development and planned games while preserving readable titles, keyboard focus, and detail links. In-development games SHALL display an `In development` badge. Planned games SHALL NOT display a lifecycle badge because their presence in the catalog already communicates that they are planned. Game titles SHALL render directly over the artwork without a chip background, with a subtle left-side scrim for legibility.

#### Scenario: Backend order is preserved
- **WHEN** the home page receives the ordered catalog
- **THEN** card DOM order matches the received entry order exactly

#### Scenario: Title remains part of the artwork
- **WHEN** a home card has a game title
- **THEN** the title is rendered without an opaque chip background or border
- **AND** a subtle left-side shade improves contrast over the artwork

#### Scenario: Released card remains prominent
- **WHEN** the home page renders a released game
- **THEN** its preview is not muted and it has no lifecycle badge

#### Scenario: In-development card is labeled
- **WHEN** the home page renders an in-development game
- **THEN** its preview is muted and an `In development` badge is visible
- **AND** the catalog entry stage remains `in_development`

#### Scenario: Planned card is navigable without a redundant label
- **WHEN** the home page renders a planned game
- **THEN** its preview is muted and no lifecycle badge is visible
- **AND** its link uses only the stable local game id

### Requirement: Every catalog game has a detail page
The system SHALL resolve and render metadata details for every persisted catalog game independently of local engine availability or enabled state.

#### Scenario: Planned detail is opened
- **WHEN** a user requests the id-based detail route for a persisted planned game
- **THEN** the system renders its BGG-backed detail page without requiring an engine

#### Scenario: Disabled detail is opened
- **WHEN** a user requests the id-based detail route for a disabled persisted game
- **THEN** the detail remains visible
- **AND** new Session launch is unavailable

#### Scenario: Unknown detail is opened
- **WHEN** a user requests a detail route for an unknown local game id
- **THEN** the system returns `404 Not Found`
