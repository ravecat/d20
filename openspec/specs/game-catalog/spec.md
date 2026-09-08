# game-catalog Specification

## Purpose
Define how the persisted D20 game catalog is queried, linked, and presented with runtime metadata.
## Requirements
### Requirement: Catalog listing supports composable query options
`D20.Games.list/1` SHALL accept an optional keyword list and SHALL return at most 32 persisted games by default without restricting launchability or requesting an order. It SHALL support native Ecto `where` keyword conditions or dynamic expressions, native `order_by` values, and a `limit` normalized to 0 through 100. Integer limits SHALL be clamped to that range; missing, nil, or non-integer limits SHALL use 32. Unknown option keys SHALL be ignored. Filtering SHALL be expressed through schema fields in `where`, not a named `filter: :playable` alias. Listing SHALL NOT add implicit launch eligibility or environment policy. Options SHALL be normalized directly into a keyword list using defaults, without an intermediate tuple or custom validation errors; metadata fallback SHALL remain local to enrichment. Query assembly and option types SHALL be inline in `list/1` and its typespec, without a separate list-option type or single-use query helpers. Filtering, caller ordering, and the limit SHALL compose before `Repo.all` and before metadata enrichment. No inline SQL fragment or in-memory shuffle SHALL be used. The batch response, metadata schema validation, fallback, and entry assembly SHALL be inline in `list/1`, without single-use catalog metadata helpers or artificial availability-status arguments. Returned records SHALL retain the existing `{:ok, entries}` shape and runtime metadata/fallback behavior.

#### Scenario: List is called without options
- **WHEN** `D20.Games.list()` or `D20.Games.list([])` is called
- **THEN** at most 32 persisted records are returned, including playable or non-playable candidates
- **AND** no order, randomness, or newest-first behavior is guaranteed
- **AND** runtime metadata or local fallback metadata is attached only for the selected records

#### Scenario: Launchable records are limited
- **WHEN** home calls `Games.list_playable(8)`
- **THEN** at most eight records accepted by authoritative new-Session launch policy are returned
- **AND** released entries precede in-development entries, with local id breaking ties
- **AND** the context owns the native field expression and ordering without exposing Ecto queries to the controller

#### Scenario: Native conditions and order are supplied
- **WHEN** list receives an Ecto `where` condition or dynamic expression with native `order_by` and a limit
- **THEN** the database applies those conditions and order before limiting
- **AND** an id-exclusion expression excludes selected ids without a custom exclusion option

#### Scenario: Schema conditions do not imply launch policy
- **WHEN** list receives `where: [stage: :in_development]` while in-development launch is disabled
- **THEN** matching records remain eligible within the limit
- **AND** listing does not infer launchability from the supplied field

#### Scenario: Limit is zero or no records match
- **WHEN** list receives `limit: 0` or its conditions match no records
- **THEN** it returns `{:ok, []}` without requesting BGG metadata

#### Scenario: Limit reaches the supported maximum
- **WHEN** list receives `limit: 100` and at least 100 records match
- **THEN** exactly 100 records are returned and enriched

#### Scenario: Requested limit exceeds the maximum
- **WHEN** list receives an integer limit above 100 and at least 100 records match
- **THEN** exactly 100 records are returned and enriched without an error

#### Scenario: Limit is negative
- **WHEN** list receives a negative integer limit
- **THEN** it returns an empty list without requesting metadata

#### Scenario: Limit has no valid integer value
- **WHEN** list receives nil or a non-integer limit
- **THEN** it uses the default limit of 32 before loading records and enriching metadata

#### Scenario: Unsupported options are supplied
- **WHEN** list receives unknown keys, including the former filter alias
- **THEN** those keys are ignored while supported options and defaults are applied

#### Scenario: Query expressions are invalid
- **WHEN** a supplied where or order_by value is invalid
- **THEN** Ecto retains its native validation errors

### Requirement: Home curates persisted catalog games
The system SHALL resolve both home collections from persisted `games` rows through `D20.Games.list_playable/1` and `D20.Games.list_browse/1`, which construct Ecto queries inside the context and reuse `list/1`. Controllers SHALL pass ordinary limits and excluded ids without constructing Ecto queries or enumerating schema engine mappings. `Playable games` SHALL contain at most eight records accepted by the authoritative new-Session launch policy in catalog order. `Browse games` SHALL select at most 32 remaining environment-visible persisted records without requesting an order, and SHALL include each selected record exactly once in a flat array without group wrappers or synthetic group ids. `PageController` SHALL call the domain operations and serialize the resulting `playableGames` and `games` props without a dedicated `D20.Games.home/1`, `D20.Games.home_partition/2`, injected randomizer, or in-memory browse shuffle. Each entry SHALL expose stable local game identity as canonical string `game` TypeID, stable public `slug`, current `stage`, and runtime `game` metadata.

#### Scenario: Launchable persisted game appears in the playable collection
- **WHEN** a persisted Qwinto row passes launch policy and is among the first eight eligible records
- **THEN** `Playable games` includes its canonical `game` TypeID entry

#### Scenario: Persisted game is not selected as playable
- **WHEN** an environment-visible persisted record is non-launchable or follows the first eight eligible records
- **THEN** it remains eligible for the bounded browse query and appears exactly once if selected
- **AND** it does not appear in `Playable games`

#### Scenario: Home props are serialized
- **WHEN** the home controller receives the two non-overlapping list results
- **THEN** it serializes flat `playableGames` and `games` arrays of catalog-entry maps inline
- **AND** all selected entries are included in the initial Inertia response

#### Scenario: Provider-only game is not listed
- **WHEN** BGG contains a game that has no persisted D20 game row
- **THEN** neither home collection includes that game

#### Scenario: Disabled game remains represented
- **WHEN** an environment-visible persisted game has enabled false
- **THEN** it is excluded from `Playable games`
- **AND** it remains eligible for `Browse games`
- **AND** its detail route remains addressable

#### Scenario: Browse selection excludes ids through the context
- **WHEN** a controller passes selected playable ids to `Games.list_browse/1`
- **THEN** the context applies environment visibility and id exclusion before limiting and metadata enrichment
- **AND** the controller receives the selected catalog entries without constructing an Ecto expression

### Requirement: Catalog entries link by stable persisted slug
The system SHALL expose exactly one canonical accessible detail link per delivered game in its owning home section. Each link SHALL target `/games/:slug` using the immutable operator-assigned slug; runtime BGG names SHALL NOT determine the route. Visual loop sentinels or repeated presentation MUST NOT add another accessible link for the same entry.

#### Scenario: Runtime name is available
- **WHEN** a persisted `game` TypeID resolves a runtime name
- **THEN** its canonical playable or browse card links to `/games/:slug` using its persisted slug
- **AND** the name remains presentation only

#### Scenario: Runtime metadata is unavailable
- **WHEN** a selected persisted record has empty fallback metadata
- **THEN** its canonical card still links to `/games/:slug`
- **AND** it remains keyboard accessible

#### Scenario: Visual loop content is duplicated
- **WHEN** a carousel renders a sentinel or repeated visual representation for continuous looping
- **THEN** only the canonical card exposes the local detail link
- **AND** the repeated representation is absent from the accessibility and tab order

#### Scenario: BGG binding changes
- **WHEN** a later response resolves a different presentation name for a persisted `game` TypeID
- **THEN** its card link retains the same persisted slug
- **AND** local game identity remains unchanged

### Requirement: Catalog game tiles include previews
The system SHALL render each visible canonical catalog entry as a landscape game card with a preview area. Hero and compact variants SHALL use runtime metadata for title and preview image when metadata is available and SHALL render a non-provider fallback preview when metadata does not include an image.

#### Scenario: Catalog renders runtime title
- **WHEN** runtime metadata for a persisted game includes title `Qwinto`
- **THEN** its visible canonical card presents `Qwinto` as the game title

#### Scenario: Catalog renders runtime preview image
- **WHEN** runtime metadata for a persisted game includes a preview image URL
- **THEN** its visible canonical card presents that image in the preview area

#### Scenario: Catalog renders fallback preview
- **WHEN** runtime metadata for a persisted game does not include a preview image URL
- **THEN** its visible canonical card still renders a landscape preview area
- **AND** the preview area uses a fallback state that does not require a configured preview URL
