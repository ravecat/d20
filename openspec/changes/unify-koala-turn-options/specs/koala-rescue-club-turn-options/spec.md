## ADDED Requirements

### Requirement: Caller-specific turn state has one projection envelope
The system SHALL expose the current caller's derived options and staged selection under a `turn` object and SHALL NOT expose the replaced top-level `turn_options` or `turn_selection` fields.

#### Scenario: Pending player receives one turn object
- **WHEN** a pending player receives a Koala Rescue Club session projection after the shared roll
- **THEN** the projection contains `turn.options` for that player
- **AND** `turn.selection` contains only that player's current staged selection or `null`

#### Scenario: Submitted player has no actionable options
- **WHEN** a player who already submitted receives a projection
- **THEN** `turn.options` is an empty object
- **AND** the projection does not expose another player's staged selection

### Requirement: Active turn options use a complete die-value map
The system SHALL project options as a JSON object keyed by every string die value from `"1"` through `"6"` while the caller can submit the current turn.

#### Scenario: All adjusted die values are projected
- **WHEN** a pending player receives options for an active roll
- **THEN** the options object contains exactly the keys `"1"`, `"2"`, `"3"`, `"4"`, `"5"`, and `"6"`
- **AND** each entry contains its computed `volunteer_cost` and an `actions` object
- **AND** no entry repeats its key as `die_value` or exposes `required_cells`

#### Scenario: Unaffordable die value remains visible but unavailable
- **WHEN** an adjusted die value requires more volunteers than the caller has available
- **THEN** its option reports the required `volunteer_cost`
- **AND** its `actions` object is empty

#### Scenario: Options do not exist outside an actionable roll
- **WHEN** the caller cannot submit because there is no active roll or the caller is not pending
- **THEN** `turn.options` is an empty object

### Requirement: Action membership represents server-derived availability
The system SHALL represent available primary actions as entries in each die option's `actions` object and SHALL omit an action when the caller cannot legally perform it for that die value.

#### Scenario: Legal actions expose target cells
- **WHEN** an affordable die value has one or more legal targets for a primary action
- **THEN** that action is present under the option's `actions` object
- **AND** the action contains the distinct sorted `available_cells` derived from the authoritative rulesheet and caller sheet

#### Scenario: Action without a legal target is absent
- **WHEN** an affordable die value has no legal target for a primary action
- **THEN** that action key is absent from the option's `actions` object

#### Scenario: Shape actions use legal initial placements
- **WHEN** `plant_trees` or `rehome_koalas` is available for a die value
- **THEN** its available cells are the cells occurring in at least one complete legal initial placement of that die shape

#### Scenario: Single-cell tree action uses accessible empty tree cells
- **WHEN** the server derives `circle_tree` availability
- **THEN** its available cells are exactly the caller's accessible cells without a circled tree

#### Scenario: Single-cell koala action uses eligible circled trees
- **WHEN** the server derives `circle_koala` availability
- **THEN** its available cells are exactly the caller's accessible cells with a circled tree and without a circled koala

### Requirement: Turn options are recomputed rather than persisted
The system SHALL derive the caller's turn options from current game state every time it renders that caller's projection and SHALL NOT store the options in the game aggregate.

#### Scenario: Relevant state change refreshes options
- **WHEN** the roll, phase, caller status, volunteers, accessible areas, trees, or koalas changes and a new projection is rendered
- **THEN** `turn.options` reflects the new authoritative state without a separate options update command

#### Scenario: Different callers receive different options
- **WHEN** two pending players with different sheets or volunteer counts receive projections of the same shared roll
- **THEN** each player's `turn.options` is independently derived for that player

### Requirement: Client commands retain their existing payload contract
The system SHALL keep existing Koala Rescue Club command field names while clients consume the renamed option fields from the projection.

#### Scenario: Projected cost is submitted through the existing command field
- **WHEN** a client submits an action selected from an option with `volunteer_cost`
- **THEN** it sends that cost using the existing `volunteers_used` command field
- **AND** existing command validation remains authoritative
