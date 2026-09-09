## MODIFIED Requirements

### Requirement: Catalog entries expose release stage and default order
`D20.Games.list/1` SHALL include the positive BGG ID as `id`, non-null internal route `slug` and nullable local `stage`, and resolved display metadata, without local `Game.id` in the catalog envelope. Selected local rows SHALL retain their persisted stage and slug; null stage and a decimal BGG route slug SHALL allow a runtime catalog entry without a visible local association. A slug SHALL describe an internal detail route and SHALL NOT imply a local record, implemented engine, or launch availability. Default listing SHALL NOT filter by launchability or impose lifecycle or id ordering. Native Ecto ordering SHALL be applied only when explicitly supplied. Home SHALL explicitly order its playable selection by released then in-development stage and local id.

#### Scenario: Catalog list has no implicit availability or order
- **WHEN** `D20.Games.list/1` resolves records with default options
- **THEN** playable, in-development, and disabled records remain eligible within the result limit
- **AND** no default order is promised

#### Scenario: Home explicitly orders playable records
- **WHEN** home requests playable records through `Games.list_playable/1`
- **THEN** released entries precede in-development entries
- **AND** entries in one stage are ordered by their internal `game` TypeIDs without exposing those IDs in the listing envelope

#### Scenario: Released stage is serialized
- **WHEN** Qwinto is serialized as a catalog entry
- **THEN** its entry includes `stage` `released`

#### Scenario: In-development stage is serialized
- **WHEN** Voyages is serialized as a catalog entry
- **THEN** its entry includes `stage` `in_development`

### Requirement: Home cards communicate availability
The home page SHALL preserve server order within `Playable games` and losslessly preserve response game order when deriving the Games presentation sequence. It MUST NOT filter, select, exclude, deduplicate, shuffle, or change collection membership. Playable compact cards SHALL use the full playable visual treatment. Games hero and compact variants SHALL preserve readable titles, keyboard focus, stable canonical detail links, and lifecycle treatment without implying launch eligibility. In-development browse entries SHALL display an `In development` badge on their canonical card treatment. Released browse entries SHALL NOT display a redundant lifecycle badge. Entries whose stage is null SHALL use neutral presentation without an in-development badge or in-development muting. Missing local fields SHALL NOT be inferred as an implementation stage or launch state. Game titles SHALL render directly over artwork without a chip background and with a legibility scrim appropriate to the hero or compact size.

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

#### Scenario: No local stage is known
- **WHEN** a delivered Games entry has null stage
- **THEN** it retains neutral card presentation without an in-development badge or in-development muting
- **AND** the client does not infer implementation or launch eligibility from its slug

### Requirement: Every catalog game has a detail page
The system SHALL render metadata details for persisted games whose stages belong to `:visible_game_stages` independently of enabled state or local engine availability, and SHALL support provider-only numeric detail routes under the game-detail resolution contract. The default configured list SHALL expose only released games; development configuration SHALL include both stages. Application code SHALL read this policy without checking environment identity. Hidden detail pages SHALL return 404. Internal catalog listing and administrative record access SHALL remain policy-neutral. A validated matching existing Session SHALL remain accessible after stage, enabled, or visible-stage configuration edits; a supplied but invalid Session id SHALL NOT bypass visibility.

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
- **WHEN** a user requests a detail route with no exact local slug and the provider does not resolve the supplied string
- **THEN** the system returns 404

#### Scenario: Visibility changes after Session creation
- **WHEN** the configured stage list no longer includes a running Session's game stage
- **THEN** the ordinary detail page returns 404
- **AND** the validated matching Session remains accessible through the same detail route with its Session parameter

#### Scenario: No visible stage is configured
- **WHEN** `:visible_game_stages` is empty
- **THEN** Playable returns no records and ordinary local detail requests return 404
- **AND** successful provider discovery retains Games entries with null local stage and decimal BGG route slugs
- **AND** `Games.list/1` still applies only its explicit caller filters
