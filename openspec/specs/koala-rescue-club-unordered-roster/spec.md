# koala-rescue-club-unordered-roster Specification

## Purpose
TBD - created by archiving change remove-koala-player-order. Update Purpose after archive.
## Requirements
### Requirement: The players map is the sole game roster
The Koala Rescue Club aggregate SHALL represent accepted gameplay membership only through `game.players` keyed by participant id. It SHALL NOT store a parallel player-order field or derive membership from session member metadata.

#### Scenario: A player joins before start
- **WHEN** a valid participant joins during setup or ready phase
- **THEN** the aggregate adds exactly one entry for that participant to `game.players`
- **AND** readiness is calculated from the number of player entries

#### Scenario: A player leaves before start
- **WHEN** an accepted participant leaves during setup or ready phase
- **THEN** the aggregate removes that participant from `game.players`
- **AND** readiness is recalculated from the remaining player entries

#### Scenario: Start freezes the accepted roster
- **WHEN** a valid game starts
- **THEN** its mode is derived from the number of entries in `game.players`
- **AND** later `join`, `left`, disconnect, or reconnect activity does not mutate the gameplay roster or mode

### Requirement: Game rules do not depend on player order
Koala Rescue Club rules SHALL count, inspect, update, and score players directly through `game.players`. They SHALL NOT sort players or create a replacement roster sequence by join time, participant id, display name, or map enumeration position.

#### Scenario: Turn completion considers every player
- **WHEN** a shared turn is in progress
- **THEN** the turn completes only after every player entry has submitted
- **AND** no player receives priority based on traversal position

#### Scenario: Multiple players first satisfy a badge together
- **WHEN** two or more multiplayer entries first satisfy the same badge during one resolution
- **THEN** every satisfying player receives the existing large badge award
- **AND** traversal position does not change the award

#### Scenario: Players satisfy a badge after its large award
- **WHEN** one or more previously unawarded multiplayer entries later satisfy that badge
- **THEN** every newly satisfying player receives the existing small badge award
- **AND** traversal position does not change the award

#### Scenario: Final scoring covers the roster
- **WHEN** the game finishes
- **THEN** `game.scores` contains one result keyed by id for every entry in `game.players`
- **AND** no score calculation depends on roster position

### Requirement: Public projections omit player order
Every caller-specific Koala Rescue Club projection SHALL expose the accepted roster through `game.players` and SHALL omit `game.order`. The public AsyncAPI game schema SHALL require the players map and SHALL NOT define an order property.

#### Scenario: A caller receives a pre-start projection
- **WHEN** an owner, player, or spectator receives a projection before start
- **THEN** `game.players` contains the currently accepted gameplay participants
- **AND** the game object has no `order` property

#### Scenario: A caller receives an active or finished projection
- **WHEN** any caller receives or reconnects to an active or finished game
- **THEN** `game.players` contains the frozen gameplay roster
- **AND** the game object has no `order` property

### Requirement: The dependent client consumes an unordered roster
The dependent Koala Rescue Club client MUST type and render participants from `game.players` and MUST NOT require `game.order`. It MUST NOT sort or number roster entries to reconstruct a player order.

#### Scenario: Participant controls render from the players map
- **WHEN** the client receives a projection containing multiple player entries
- **THEN** it renders one keyed participant control for every entry in `game.players`
- **AND** each control selects that player's sheet by stable participant id
- **AND** the client does not assert or communicate a roster position

#### Scenario: A participant has no display name
- **WHEN** a player entry has no corresponding member display name or the name is blank
- **THEN** the client uses the stable participant id as the visible and accessible label
- **AND** it does not generate a positional label such as `Player 1`

#### Scenario: Final standings rank scores independently
- **WHEN** a multiplayer game finishes
- **THEN** the client continues to rank result rows by total score descending
- **AND** that score ranking does not create or imply a gameplay roster order
- **AND** a result row without member display metadata uses its participant id as the label
