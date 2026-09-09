## MODIFIED Requirements

### Requirement: Catalog listing supports composable query options
`D20.Games.list/1` SHALL accept an optional keyword list and SHALL return at most 32 persisted games by default without restricting launchability or requesting an order. It SHALL support native Ecto `where` keyword conditions or dynamic expressions, native `order_by` values, and a `limit` normalized to 0 through 100. Integer limits SHALL be clamped to that range; missing, nil, or non-integer limits SHALL use 32. Unknown option keys SHALL be ignored. Filtering SHALL be expressed through schema fields in `where`, not a named `filter: :playable` alias. Listing SHALL NOT add implicit launch eligibility or environment policy. Options SHALL be normalized directly into a keyword list using defaults, without an intermediate tuple or custom validation errors; metadata fallback SHALL remain local to enrichment. Local public listing functions SHALL keep their option shapes inline in their typespecs, without a separate list-option type. Query assembly and normalization SHALL be shared in one private query-and-options implementation reused by the general and scoped listing functions, without single-use query helpers. Filtering, caller ordering, and the limit SHALL compose before `Repo.all` and before metadata enrichment. Local query selection SHALL NOT use an inline SQL fragment or in-memory shuffle. The batch response, metadata schema validation, fallback, and entry assembly SHALL remain together in the shared private listing implementation, without single-use catalog metadata helpers or artificial availability-status arguments; metadata assembly reused by local and provider listing MAY share a helper. Returned records SHALL retain the existing `{:ok, entries}` shape and runtime metadata/fallback behavior.

#### Scenario: List is called without options
- **WHEN** `D20.Games.list()` or `D20.Games.list([])` is called
- **THEN** at most 32 persisted records are returned, including playable or non-playable candidates
- **AND** no order, randomness, or newest-first behavior is guaranteed
- **AND** runtime metadata or local fallback metadata is attached only for the selected records

#### Scenario: Launchable records are limited
- **WHEN** home calls `Games.list_playable(limit: 8, order_by: [desc: :stage, asc: :id])`
- **THEN** at most eight records accepted by authoritative new-Session launch policy are returned
- **AND** released entries precede in-development entries, with local id breaking ties
- **AND** the context owns mandatory launch predicates and applies the caller-selected order before limiting

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

### Requirement: Home curates local and provider catalog games
The system SHALL select home Playable from persisted rows through `Games.list_playable(limit: 8, order_by: [desc: :stage, asc: :id])` and Games from BGG Hot through `Games.list_by_provider()` with default limit 32. The context SHALL own local launch policy. The controller SHALL call both operations directly and serialize flat initial-response `playableGames` and `games` arrays, without a home-partition helper, provider query expressions, or playable-ID exclusion. A game independently selected by both sources SHALL appear once in each collection. Each entry SHALL expose numeric BGG `id`, non-null internal route `slug` and nullable local `stage`, and runtime `game` metadata, without local TypeID. Discovery errors SHALL produce an empty Games array and a provider-discovery warning while preserving the locally selected playable collection.

#### Scenario: Launchable persisted game is selected
- **WHEN** a local row passes launch policy and is among the first eight in the requested order
- **THEN** Playable includes its BGG-keyed entry with local stage and slug
- **AND** provider selection does not change this membership

#### Scenario: Provider-only game is selected
- **WHEN** Hot selects a BGG game absent from local persistence
- **THEN** Games includes that identity with runtime metadata, null stage, and its decimal BGG ID as slug
- **AND** no local record is created

#### Scenario: The two selections overlap
- **WHEN** Hot selects a game already present in Playable
- **THEN** it remains present once in each collection
- **AND** neither controller nor client excludes it from Games

#### Scenario: Home props are serialized
- **WHEN** the controller receives both successful results
- **THEN** it serializes both flat arrays inline with numeric BGG identity and the existing metadata object
- **AND** all carousel content is present in the initial response

#### Scenario: Provider discovery fails
- **WHEN** Hot cannot provide source membership
- **THEN** home succeeds with an empty games array and the locally selected playable entries
- **AND** a warning records discovery failure without credentials

### Requirement: Catalog entries link by stable persisted slug
The system SHALL expose exactly one canonical accessible detail link per delivered game in its owning home section. Every entry SHALL link to `/games/:slug` using the non-null route slug supplied by the Games context. A visible local match SHALL use its immutable operator-assigned slug; otherwise the context SHALL use the BGG ID as a decimal string. Every canonical link SHALL use the existing internal Inertia navigation pattern without frontend provider/local URL selection or conditional attachments. Runtime BGG names SHALL NOT determine either route. A slug SHALL indicate an internal detail address and SHALL NOT be interpreted as proof of a local record, implemented engine, or launch eligibility. Visual loop sentinels or repeated presentation MUST NOT add another accessible link for the same entry.

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
- **THEN** only the canonical card exposes the selected detail link
- **AND** the repeated representation is absent from the accessibility and tab order

#### Scenario: BGG binding changes
- **WHEN** a later response resolves a different presentation name for a persisted `game` TypeID
- **THEN** its card link retains the same persisted slug
- **AND** local game identity remains unchanged

#### Scenario: No local slug is available
- **WHEN** a delivered catalog entry has a positive BGG ID and no visible local association
- **THEN** its canonical card links internally to `/games/{id}` through the same Inertia behavior as local cards
- **AND** it remains keyboard accessible without creating a local game record

#### Scenario: A non-launchable local game has a slug
- **WHEN** a delivered entry has a local slug but its game has no engine or is disabled
- **THEN** its card still links to the local detail route
- **AND** the slug does not grant or imply new-Session launch eligibility

### Requirement: Playable listing shares general query options
`Games.list_playable/0,1` SHALL accept the same optional native Ecto `where`, `order_by`, and `limit` keyword options as `list/0,1`. It SHALL inherit default limit 32, integer clamping to 0..100, non-integer fallback, ignored unknown options, native Ecto validation, and no implicit order. Its mandatory predicates SHALL restrict rows to enabled games with a configured visible stage and implemented engine. Caller keyword or dynamic conditions SHALL intersect with these predicates before ordering, limiting, loading, or enrichment. The former positional playable API and `list_browsable/0,1` SHALL be removed without aliases; provider discovery SHALL use `list_by_provider/0,1` instead.

#### Scenario: Playable uses common defaults
- **WHEN** playable is called with no argument or an empty options list
- **THEN** it returns at most 32 records satisfying mandatory predicates with no promised order

#### Scenario: Caller filters narrow the scope
- **WHEN** a caller supplies keyword or dynamic conditions, ordering, and a limit
- **THEN** both mandatory and caller predicates apply before caller order and the normalized limit
- **AND** only selected records are enriched

#### Scenario: Caller conditions conflict with mandatory predicates
- **WHEN** playable receives enabled false or a hidden stage condition
- **THEN** it returns an empty result without requesting metadata

#### Scenario: Permissive conditions cannot widen the scope
- **WHEN** playable receives a permissive dynamic OR expression
- **THEN** disabled, engine-less, and hidden-stage records remain excluded

#### Scenario: Scoped limits follow general normalization
- **WHEN** playable receives zero, negative, excessive, or non-integer limits
- **THEN** it uses the same clamping and fallback as list before metadata enrichment

### Requirement: Catalog entries represent runtime BGG identity and optional local association
Every successful catalog listing SHALL return `{:ok, entries}` with each entry represented by the map `%{id: pos_integer(), metadata: Metadata.t(), stage: :released | :in_development | nil, slug: String.t()}`. The four keys SHALL always be present. `id` SHALL identify the returned BGG game and metadata association even when metadata is empty; it SHALL NOT be duplicated in the embedded presentation schema. The map SHALL NOT contain local `Game.id`, a nested local game, or a derived availability flag, and SHALL NOT require a new entry struct. Local selected records SHALL supply their current BGG binding, stage, and slug. An entry without visible local association SHALL have null stage and the decimal BGG ID as its route slug without inventing local data. The context SHALL resolve the slug before controller serialization. Persisted local IDs SHALL remain the identity used by existing detail/session internals and explicit local ordering.

#### Scenario: A selected local record is enriched
- **WHEN** a listing returns a persisted game whose BGG ID is 183006
- **THEN** its catalog map contains `id: 183006`, runtime metadata, its persisted stage, and its persisted slug
- **AND** no local TypeID or nested game record appears in that map

#### Scenario: Metadata is empty
- **WHEN** selected-game metadata is absent, invalid, or unavailable
- **THEN** the map keeps the selected BGG ID, stage, and slug with `Metadata.empty()`
- **AND** identity does not depend on a provider display field

#### Scenario: Optional local association is absent
- **WHEN** provider discovery selects a BGG game without a visible local association
- **THEN** positive BGG identity and runtime metadata are sufficient with null stage and a decimal BGG route slug
- **AND** provider discovery retains that game without requiring a persisted record

#### Scenario: Catalog props are serialized
- **WHEN** the controller serializes a catalog map for Inertia
- **THEN** the client receives the positive BGG ID as `id`, nullable `stage`, non-null route `slug`, and the existing `game` metadata object
- **AND** it receives no catalog `bggId` compatibility field


### Requirement: Provider listing discovers games independently of persistence
`Games.list_by_provider(options \\ [])` SHALL call `BoardGameGeek.fetch_hot_games/0,1` and accept only the optional `limit` keyword. Missing, nonpositive, or non-integer limits SHALL use 32, positive integers SHALL cap at 100, and unknown options including Ecto where/order_by SHALL be ignored. Successful provider attrs SHALL define membership and order. The context SHALL join local rows by BGG ID only when their stages are configured visible, without requiring enabled state or an engine. Visible matches SHALL supply stage and stored slug; unmatched or hidden matches SHALL retain null stage and the decimal BGG ID as route slug without removing provider entries. It SHALL build the existing four-field catalog map and validate Metadata per entry with empty fallback. Provider Hot or detail-operation errors SHALL remain `{:error, reason}`. No local record SHALL be created or updated.

#### Scenario: Database is empty
- **WHEN** Hot supplies games and no local game exists
- **THEN** the selected provider identities are returned with metadata, null stage, and decimal BGG route slugs

#### Scenario: Visible local game matches
- **WHEN** a selected provider BGG ID matches a visible local row, including a disabled or engine-less row
- **THEN** its existing stage and slug are merged without changing provider membership or order

#### Scenario: Hidden local game matches
- **WHEN** a selected BGG ID matches a row whose stage is not visible
- **THEN** the provider entry remains with null stage and the decimal BGG ID as slug and its internal numeric detail link

#### Scenario: No local stages are visible
- **WHEN** visible_game_stages is empty and Hot selection succeeds
- **THEN** selected provider entries remain with null stage and decimal BGG route slugs

#### Scenario: Provider limits use a default for nonpositive and invalid values
- **WHEN** provider listing receives a negative, zero, excessive, or non-integer limit
- **THEN** nonpositive or non-integer limits use 32 and excessive positive limits cap at 100
- **AND** unsupported where and order_by values do not create Ecto or remote filtering

#### Scenario: Detail metadata is invalid
- **WHEN** a selected provider attrs map fails Metadata validation
- **THEN** that identity and optional local association remain with empty metadata
