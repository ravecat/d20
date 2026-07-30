# game-catalog-availability Specification

## Purpose
TBD - created by archiving change expand-game-catalog-statuses. Update Purpose after archive.
## Requirements
### Requirement: Registry represents catalog availability
The system SHALL allow each configured game to declare optional availability status `active` or `in_progress`. The system SHALL treat a missing status as inactive. Active and in-progress entries MUST include a valid local engine binding and non-empty iframe sandbox policy; inactive entries MUST be valid with only a slug and BGG identifier.

#### Scenario: Active game is operationally bound
- **WHEN** a registry entry declares status `active`
- **THEN** the registry requires its engine and sandbox bindings

#### Scenario: In-progress game is operationally bound
- **WHEN** a registry entry declares status `in_progress`
- **THEN** the registry requires its engine and sandbox bindings

#### Scenario: Missing status is inactive
- **WHEN** a registry entry omits status, engine, and sandbox
- **THEN** the registry accepts it as an inactive catalog entry

### Requirement: Catalog contains the requested games
The configured catalog SHALL contain Fliptown, Koala Rescue Club, Next Station: London, Qwinto, Flip 7, Railroad Ink: Deep Blue Edition, Confusing Lands, Trails of Tucana, Shifting Stones, Trailblazers, Death Valley, Voyages, Sky Team, Qwixx, Nimalia, Lost Cities, Deep Sea Adventure, Waypoints, and Aquamarine using their stable internal slugs and BGG identifiers.

#### Scenario: Home catalog is loaded
- **WHEN** the application resolves configured games for the home page
- **THEN** all nineteen configured games are included

### Requirement: Catalog entries expose availability and default order
`D20.Games.list/0` SHALL include the registry status alongside each game's slug and resolved display metadata. It SHALL return active games first, in-progress games second, and inactive games last while preserving registry order within each availability group.

#### Scenario: Catalog list is ordered by availability
- **WHEN** `D20.Games.list/0` resolves entries with mixed availability
- **THEN** all active entries precede all in-progress entries
- **AND** all in-progress entries precede all inactive entries
- **AND** entries with the same availability retain their registry-relative order

#### Scenario: Active status is serialized
- **WHEN** Qwinto is rendered in home-page props
- **THEN** its entry includes status `active`

#### Scenario: Inactive status is serialized
- **WHEN** a status-less game is rendered in home-page props
- **THEN** its entry has no active or in-progress status

### Requirement: Home cards communicate availability
The home page SHALL render games in the order received from the backend without client-side filtering, grouping, or sorting. It SHALL display active games with the full visual treatment and visually mute in-progress and inactive games while preserving readable titles, keyboard focus, and detail links. In-progress games SHALL additionally display a visible `Soon` badge without changing their internal `in_progress` status. Game titles SHALL render directly over the artwork without a chip background, with a subtle left-side scrim for legibility.

#### Scenario: Backend order is preserved
- **WHEN** the home page receives the ordered catalog from the backend
- **THEN** card DOM order matches the received entry order exactly

#### Scenario: Title remains part of the artwork
- **WHEN** a home card has a game title
- **THEN** the title is rendered without an opaque chip background or border
- **AND** a subtle left-side shade improves contrast over the artwork

#### Scenario: Active card remains prominent
- **WHEN** the home page renders an active game
- **THEN** its preview is not muted and it has no `Soon` badge

#### Scenario: In-progress card is labeled
- **WHEN** the home page renders an in-progress game
- **THEN** its preview is muted and a `Soon` badge is visible
- **AND** the catalog entry status remains `in_progress`

#### Scenario: Inactive card remains navigable
- **WHEN** the home page renders a game without status
- **THEN** its preview is muted and its link still targets `/games/:slug`

### Requirement: Every catalog game has a detail page
The system SHALL resolve and render metadata details for every configured catalog entry independently of local engine availability.

#### Scenario: Inactive detail is opened
- **WHEN** a user requests `/games/:slug` for a configured inactive game
- **THEN** the system renders its BGG-backed detail page without requiring an engine

#### Scenario: Unknown detail is opened
- **WHEN** a user requests `/games/:slug` for an unconfigured slug
- **THEN** the system returns `404 Not Found`
