## MODIFIED Requirements

### Requirement: Home curates persisted catalog games
The system SHALL resolve both home collections from persisted `games` rows through `D20.Games.list_playable/1` and `D20.Games.list_browsable/1`, which construct Ecto queries inside the context and reuse `list/1`. Controllers SHALL pass ordinary limits and excluded ids without constructing Ecto queries or enumerating schema engine mappings. `Playable games` SHALL contain at most eight records accepted by the authoritative new-Session launch policy in catalog order. `Browse games` SHALL select at most 32 remaining environment-visible persisted records without requesting an order, and SHALL include each selected record exactly once in a flat array without group wrappers or synthetic group ids. `PageController` SHALL call the domain operations and serialize the resulting `playableGames` and `games` props without a dedicated `D20.Games.home/1`, `D20.Games.home_partition/2`, injected randomizer, or in-memory browse shuffle. Each entry SHALL expose stable local game identity as canonical string `game` TypeID, stable public `slug`, current `stage`, and runtime `game` metadata.

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
- **WHEN** a controller passes selected playable ids to `Games.list_browsable/1`
- **THEN** the context applies environment visibility and id exclusion before limiting and metadata enrichment
- **AND** the controller receives the selected catalog entries without constructing an Ecto expression
