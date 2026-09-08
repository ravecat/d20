# game-catalog-availability Specification

## Purpose
Define persisted game release stages, launch enablement, catalog ordering, home-card treatment, and detail discoverability.
## Requirements
### Requirement: Persisted records represent release stage and enablement
Every game SHALL have stage `in_development` or `released` and a separate boolean `enabled`. New records SHALL default to in-development. Only released rows MUST have a valid engine; in-development rows MAY omit an engine. Enabled SHALL control new-Session launch independently of stage and SHALL NOT hide an otherwise environment-visible detail page. Existing planned rows SHALL migrate to in-development without changing local ids, BGG ids, enabled state, or timestamps. Every engine binding SHALL be preserved. The stage migration SHALL NOT identify or special-case any game or engine.

#### Scenario: A game record is created
- **WHEN** a record is created with a valid BGG id and slug and no stage or engine
- **THEN** it is valid with stage `in_development` and engine null

#### Scenario: A game is released
- **WHEN** a game is assigned stage `released` without an engine
- **THEN** changeset validation and the database constraint reject it

#### Scenario: Planned is submitted after migration
- **WHEN** a write supplies the removed `planned` stage
- **THEN** changeset validation and the database domain reject it

#### Scenario: Existing catalog rows are migrated
- **WHEN** the two-stage migration runs
- **THEN** all former planned records become in-development with their existing identities
- **AND** every existing engine binding retains its permanent engine id regardless of stage

#### Scenario: Migration is rolled back
- **WHEN** the previous three-stage database constraints are restored
- **THEN** engine-less in-development rows are mapped to planned and the old default is restored
- **AND** the old planned distinction for engine-bound rows is not reconstructed, and all engine bindings are preserved

### Requirement: Persisted catalog contains the migrated games
The catalog SHALL contain Fliptown, Koala Rescue Club, Next Station: London, Qwinto, Flip 7, Railroad Ink: Deep Blue Edition, Confusing Lands, Trails of Tucana, Shifting Stones, Trailblazers, Death Valley, Voyages, Sky Team, Qwixx, Nimalia, Lost Cities, Deep Sea Adventure, Waypoints, and Aquamarine with generated `game` TypeIDs and their former BGG bindings.

#### Scenario: Persisted catalog is loaded
- **WHEN** the application resolves persisted catalog records
- **THEN** all nineteen migrated games are included
- **AND** none depends on a checked-in game registry entry

### Requirement: Catalog entries expose release stage and default order
`D20.Games.list/1` SHALL include the local `game` TypeID, stable public `slug`, stage, and resolved display metadata. Default listing SHALL NOT filter by launchability or impose lifecycle or id ordering. Native Ecto ordering SHALL be applied only when explicitly supplied. Home SHALL explicitly order its playable selection by released then in-development stage and local id.

#### Scenario: Catalog list has no implicit availability or order
- **WHEN** `D20.Games.list/1` resolves records with default options
- **THEN** playable, in-development, and disabled records remain eligible within the result limit
- **AND** no default order is promised

#### Scenario: Home explicitly orders playable records
- **WHEN** home requests playable records through `Games.list_playable/1`
- **THEN** released entries precede in-development entries
- **AND** entries in one stage are ordered by their `game` TypeIDs

#### Scenario: Released stage is serialized
- **WHEN** Qwinto is serialized as a catalog entry
- **THEN** its entry includes `stage` `released`

#### Scenario: In-development stage is serialized
- **WHEN** Voyages is serialized as a catalog entry
- **THEN** its entry includes `stage` `in_development`

### Requirement: Home cards communicate availability
The home page SHALL preserve server order within `Playable games` and losslessly preserve response game order when deriving the Games presentation sequence. It MUST NOT filter, select, exclude, deduplicate, shuffle, or change collection membership. Playable compact cards SHALL use the full playable visual treatment. Games hero and compact variants SHALL preserve readable titles, keyboard focus, stable canonical detail links, and lifecycle treatment without implying launch eligibility. In-development browse entries SHALL display an `In development` badge on their canonical card treatment. Released browse entries SHALL NOT display a redundant lifecycle badge. Game titles SHALL render directly over artwork without a chip background and with a legibility scrim appropriate to the hero or compact size.

#### Scenario: Playable order is preserved
- **WHEN** the home page receives the ordered playable collection
- **THEN** its compact-card canonical order matches the response exactly

#### Scenario: Browse response order is preserved
- **WHEN** the home page receives a bounded server-selected games array
- **THEN** derived Games slide order follows the array response order
- **AND** no entry is filtered, duplicated as an accessible link, or regrouped by policy

#### Scenario: Playable card remains prominent
- **WHEN** the home page renders a game accepted by launch policy in `Playable games`
- **THEN** its compact landscape preview uses the playable visual treatment
- **AND** collection membership does not change its persisted stage

#### Scenario: In-development browse card is labelled
- **WHEN** an in-development record appears in the Games composition
- **THEN** an `In development` badge is visible on its canonical card treatment
- **AND** its persisted stage remains `in_development`

#### Scenario: Released browse card remains navigable without a redundant label
- **WHEN** a released record appears in the Games composition
- **THEN** no lifecycle badge is visible
- **AND** its canonical link uses the stable persisted game slug

#### Scenario: Disabled browse card remains a detail link
- **WHEN** a disabled persisted game appears in the Games composition
- **THEN** its canonical card remains readable, keyboard focusable, and linked to its detail route
- **AND** its presence does not imply new-Session launch availability

#### Scenario: Hero and compact visual representations coexist
- **WHEN** one delivered browse entry is represented visually in more than one Games row or loop position
- **THEN** its lifecycle treatment remains consistent
- **AND** exactly one representation exposes the canonical accessible detail link

#### Scenario: In-development decorative card is narrow
- **WHEN** a decorative in-development compact card is narrower than 11rem
- **THEN** it shows the title and status without overlapping category chips
- **AND** categories remain present on the canonical hero card instead of competing for space in its decorative copy

### Requirement: Every catalog game has a detail page
The system SHALL render metadata details for persisted games whose stages belong to `:visible_game_stages` independently of enabled state or local engine availability. The default configured list SHALL expose only released games; development configuration SHALL include both stages. Application code SHALL read this policy without checking environment identity. Hidden detail pages SHALL return 404. Internal catalog listing and administrative record access SHALL remain policy-neutral. A validated matching existing Session SHALL remain accessible after stage, enabled, or visible-stage configuration edits; a supplied but invalid Session id SHALL NOT bypass visibility.

#### Scenario: In-development detail is opened in development
- **WHEN** the configured stages include in-development and a user opens an in-development game's local detail route
- **THEN** its metadata detail renders even without an engine

#### Scenario: In-development detail is opened in production
- **WHEN** the default released-only policy is configured and a user opens an in-development game's detail without a Session parameter
- **THEN** the response is 404

#### Scenario: Invalid Session is supplied for a hidden game
- **WHEN** an in-development game's detail is requested under the released-only policy with a missing or mismatched Session id
- **THEN** the existing Session-error redirect remains unchanged and exposes no game details
- **AND** following the redirect to the fresh detail route returns 404

#### Scenario: Released disabled detail is opened
- **WHEN** a user requests a disabled released game's detail
- **THEN** the detail remains visible with new-Session launch unavailable

#### Scenario: An active Session outlives publication
- **WHEN** a game's stage changes to in-development after Session creation
- **THEN** a validated matching Session remains accessible through its existing detail workspace
- **AND** new launch remains denied when in-development is absent from the configured list

#### Scenario: Unknown detail is opened
- **WHEN** a user requests a detail route for an unknown game slug
- **THEN** the system returns 404

#### Scenario: Visibility changes after Session creation
- **WHEN** the configured stage list no longer includes a running Session's game stage
- **THEN** the ordinary detail page returns 404
- **AND** the validated matching Session remains accessible through the same detail route with its Session parameter

#### Scenario: No visible stage is configured
- **WHEN** `:visible_game_stages` is empty
- **THEN** home visibility queries return no records and ordinary local detail requests return 404
- **AND** `Games.list/1` still applies only its explicit caller filters

### Requirement: Game visibility is explicit application configuration
The application SHALL configure `:visible_game_stages` as `[:released]` in `config/config.exs` and override it with `[:released, :in_development]` in `config/dev.exs`. Visibility query construction, detail access, and new-Session authorization SHALL read this key directly through `Application.fetch_env!/2`. `Games.list/1` SHALL remain policy-neutral and apply only caller-supplied filters. The application SHALL NOT retain `:d20, :env`, `Games.visible_stages/0`, or compile-time environment flags for this policy.

#### Scenario: Default configuration is resolved
- **WHEN** test or production configuration is loaded without an explicit stage-policy override
- **THEN** the permitted stage list is `[:released]`

#### Scenario: Development configuration is resolved
- **WHEN** development configuration is loaded
- **THEN** the permitted stage list is `[:released, :in_development]`
