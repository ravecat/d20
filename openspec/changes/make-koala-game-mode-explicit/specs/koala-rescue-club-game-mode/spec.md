## ADDED Requirements

### Requirement: Game mode is captured from the accepted start roster
The Koala Rescue Club game aggregate SHALL store `mode` as `solo`, `multiplayer`, or an unset pre-start value. Before start, `game.players` SHALL contain exactly the currently accepted players. The validated start transition SHALL determine mode from the number of entries in `game.players`, SHALL NOT use player order as its roster source, and SHALL set `solo` for exactly one accepted player or `multiplayer` for two or more accepted players in the same transition that starts gameplay.

#### Scenario: Mode is unset while the roster is open
- **WHEN** a Koala Rescue Club game is initialized or is waiting to start
- **THEN** its mode is unset
- **AND** joining a player does not freeze a provisional mode

#### Scenario: One-player game starts in solo mode
- **WHEN** the owner starts a valid game whose accepted roster contains exactly one player
- **THEN** the game enters the roll phase with mode `solo`

#### Scenario: Multi-player game starts in multiplayer mode
- **WHEN** the owner starts a valid game whose accepted roster contains two or more players
- **THEN** the game enters the roll phase with mode `multiplayer`

#### Scenario: A pre-start `left` event updates the accepted roster
- **WHEN** an accepted player leaves while the game is in setup or ready phase
- **THEN** that player is removed from `game.players`
- **AND** readiness is recalculated from the remaining accepted players
- **AND** a later start derives mode without counting the departed player

#### Scenario: Mode remains stable after start
- **WHEN** an active player disconnects, reconnects, or an in-progress `join` or `left` event is processed
- **THEN** the game mode remains the value captured at start
- **AND** the accepted gameplay roster remains unchanged

### Requirement: Mode is authoritative for mode-specific rules
The Koala Rescue Club engine SHALL use the stored game mode, rather than recounting players, order entries, or scores, whenever badge awarding or final rank behavior differs between solo and multiplayer games.

#### Scenario: Solo mode uses solo badge timing
- **WHEN** a solo game first satisfies a badge condition during round 1 or round 2
- **THEN** the engine awards the badge using the existing solo round-based large or small award rule

#### Scenario: Multiplayer mode uses achievement order
- **WHEN** a multiplayer game satisfies a badge condition
- **THEN** the engine applies the existing multiplayer first-achiever and later-achiever award rules

#### Scenario: Solo mode receives a rating rank
- **WHEN** a solo game finishes and final scores are calculated
- **THEN** its single final score includes the rank selected from the sheet's solo rating bands

#### Scenario: Multiplayer mode has no solo rating rank
- **WHEN** a multiplayer game finishes and final scores are calculated
- **THEN** every final score contains `rank: null`

### Requirement: Projections expose a stable game mode field
Every caller-specific Koala Rescue Club session projection SHALL include `game.mode`. The public AsyncAPI contract SHALL require the property and SHALL allow only `null`, `solo`, or `multiplayer` according to the game lifecycle.

#### Scenario: Pre-start projection has an unset mode
- **WHEN** any caller receives a projection before the game starts
- **THEN** `game.mode` is `null`

#### Scenario: Active solo projection exposes solo mode
- **WHEN** any player or spectator receives a projection for a started solo game
- **THEN** `game.mode` is `solo`

#### Scenario: Active multiplayer projection exposes multiplayer mode
- **WHEN** any player or spectator receives a projection for a started multiplayer game
- **THEN** `game.mode` is `multiplayer`

#### Scenario: Reconnection preserves projected mode
- **WHEN** a caller reconnects to an active or finished game
- **THEN** the newly rendered projection contains the same mode captured when that game started

### Requirement: The dependent client selects final results from game mode
The dependent Koala Rescue Club client MUST type and read `game.mode` and MUST use it as the only selector between the solo score card and multiplayer standings. It MUST NOT infer the result variant from the size of players, order, standings, or scores.

#### Scenario: Solo result renders from explicit mode
- **WHEN** the client receives a finished projection with `game.mode` equal to `solo`
- **THEN** it renders the existing solo score and solo rank presentation
- **AND** it does not render the multiplayer standings list

#### Scenario: Multiplayer result renders from explicit mode
- **WHEN** the client receives a finished projection with `game.mode` equal to `multiplayer`
- **THEN** it renders the existing ordered multiplayer standings presentation
- **AND** it does not render the solo score card

#### Scenario: Mode wins over score cardinality
- **WHEN** a client test projection has a result collection size that does not imply its explicit game mode
- **THEN** the rendered result variant follows `game.mode`
- **AND** the client does not fall back to collection-size inference

#### Scenario: Result content and activation remain unchanged
- **WHEN** a valid solo or multiplayer game reaches the finished session phase
- **THEN** the results popover retains its current activation, controls, copy, score values, rank labels, ordering, and accessibility behavior
