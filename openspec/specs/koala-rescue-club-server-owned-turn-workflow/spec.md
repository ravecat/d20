# koala-rescue-club-server-owned-turn-workflow Specification

## Purpose
TBD - created by archiving change restore-koala-server-owned-turn-selection. Update Purpose after archive.
## Requirements
### Requirement: Game owns each pending player's unfinished selection
The Koala Rescue Club game aggregate SHALL store at most one private unfinished shape selection for each player, containing exactly `action`, adjusted `value`, volunteer count `volunteers`, and selected `cells`. Storing or editing the selection SHALL NOT change the committed sheet, spend volunteers, or mark the player submitted.

#### Scenario: Player starts a selection
- **WHEN** a pending player sends a valid `select` event with complete selection context and a legal target cell
- **THEN** the game stores normalized `action`, `value`, `volunteers`, and `cells` containing that target
- **AND** the player's committed sheet, volunteers, and pending status remain unchanged

#### Scenario: Selection survives projection refresh
- **WHEN** the selection owner reconnects or receives a later regular session projection before submitting
- **THEN** the projection is derived from the selection retained by the session process

#### Scenario: Invalid edit preserves the selection
- **WHEN** a selection event would produce a draft incompatible with every legal placement
- **THEN** the server returns an error
- **AND** the previously stored selection and committed player state remain unchanged

### Requirement: Select incrementally adds a legal target
The `select` event SHALL add one target cell to the pending player's stored selection through the ordinary game command path. It SHALL accept complete selection context when establishing or replacing a selection and SHALL accept only a target cell when continuing a compatible stored selection.

#### Scenario: First select establishes context
- **WHEN** a player without a selection sends `select` with action, adjusted die value, volunteer count, and target cell
- **THEN** the server validates the complete context and stores the target as the first selected cell

#### Scenario: Later select reuses context
- **WHEN** a player with a selection sends `select` with only a legal unselected target cell
- **THEN** the server appends that target to `cells` while preserving the existing `action`, `value`, and `volunteers`

#### Scenario: Complete context replaces an incompatible context
- **WHEN** a player sends `select` with a valid complete context different from the stored context
- **THEN** the server replaces the previous `cells` with a new selection containing only the submitted target

#### Scenario: Repeated select is idempotent
- **WHEN** a player selects a cell already present in the stored selection
- **THEN** the command succeeds without duplicating the cell or changing other selection state

#### Scenario: Missing initial context is rejected
- **WHEN** a player without a stored selection sends `select` without action, adjusted die value, or volunteer count
- **THEN** the server rejects the command and stores no selection

### Requirement: Deselect and reset edit stored selection state
The `deselect` event SHALL remove one target cell from an existing selection, while `reset` SHALL clear the complete selection context. Both events SHALL use the ordinary game command path and SHALL leave committed player state unchanged.

#### Scenario: Selected cell is removed
- **WHEN** a pending player sends `deselect` for a selected target cell
- **THEN** the server removes that cell and retains the remaining selection context and cells

#### Scenario: Final selected cell is removed
- **WHEN** a pending player deselects the only selected cell
- **THEN** the stored selection retains `action`, `value`, and `volunteers` with an empty `cells` list

#### Scenario: Missing selected cell is unchanged
- **WHEN** a pending player sends `deselect` for a cell absent from the stored selection
- **THEN** the command succeeds without changing the selection

#### Scenario: Selection is reset
- **WHEN** a pending player sends `reset` with an empty payload
- **THEN** the server clears the player's complete stored selection

### Requirement: Selection events preserve the generic session channel
The generic session channel SHALL route `select`, `deselect`, and `reset` through the same `Sessions.dispatch` path as other game commands and SHALL NOT contain Koala-specific input clauses or projection-event routing.

#### Scenario: Selection event is accepted
- **WHEN** a client sends a valid selection event through the session channel
- **THEN** the session process applies the event and publishes the resulting regular caller-specific session projection

#### Scenario: Another game uses the session channel
- **WHEN** a non-Koala game receives an input event
- **THEN** the generic session channel delegates it without evaluating Koala event names or Koala projection functions

### Requirement: Regular projection derives caller-specific selection details
Regular Koala join and broadcast projections SHALL derive selection details from the current stored selection and rule primitives. Projection SHALL map stored `value`, `volunteers`, and `cells` to public `die_value`, `volunteers_used`, and `selected_cells`. The projection SHALL include top-level `selection` for its owner and SHALL NOT expose that selection to another caller or inside shared player data.

#### Scenario: Owner receives partial selection details
- **WHEN** a pending player owns an incomplete legal selection
- **THEN** that player's projection contains its context, normalized selected cells, required cell count, legal continuation cells, `complete: false`, and no bonus options

#### Scenario: Owner receives complete selection details
- **WHEN** a pending player's selected cells exactly match a legal placement
- **THEN** that player's projection contains `complete: true`, no continuation cells, and bonus options derived by simulating the primary action

#### Scenario: Other player cannot see selection
- **WHEN** another player receives a projection while the owner has an unfinished selection
- **THEN** the other player's top-level `selection` is `null`
- **AND** the shared rendered player entry contains no stored selection field

#### Scenario: Player has no selection
- **WHEN** the caller has no stored selection or cannot submit during the current phase
- **THEN** the regular projection contains `selection: null` while preserving the existing caller-specific options behavior

### Requirement: Stored complete selection is submitted atomically
The `submit` command SHALL consume the caller's stored complete selection and submitted ordered bonus decisions. The server SHALL revalidate and apply the primary action, volunteer spending, bonus actions, submitted status, and selection removal atomically.

#### Scenario: Complete stored selection is accepted
- **WHEN** a pending player submits valid bonus decisions for a complete legal stored selection
- **THEN** the server commits the primary action and bonuses, spends the required volunteers, marks the player submitted, and clears the selection

#### Scenario: Missing selection is rejected
- **WHEN** a pending player submits without a stored selection
- **THEN** the server returns a missing-selection error and leaves committed player state unchanged

#### Scenario: Incomplete selection is rejected
- **WHEN** a pending player submits an incomplete stored selection
- **THEN** the server returns an incomplete-selection error
- **AND** the committed player state and stored selection remain unchanged

#### Scenario: Invalid bonus decision preserves staged work
- **WHEN** a pending player submits an invalid bonus decision for a complete selection
- **THEN** the server rejects the command without changing the sheet, volunteers, status, or stored selection

### Requirement: Confirmed turn history stores only adjusted die values
Each Koala player SHALL have `turns` as an ordered list of accepted adjusted die values from 1 through 6. The game and public projection SHALL NOT store or expose a turn-result object, explicit turn number, or primary action in this history.

#### Scenario: Shape turn is accepted
- **WHEN** a player successfully submits a stored shape selection using an adjusted die value
- **THEN** the server appends that adjusted value to the player's `turns` list

#### Scenario: Single-cell turn is accepted
- **WHEN** a player successfully submits `circle_tree` or `circle_koala`
- **THEN** the server appends the accepted adjusted die value to the player's `turns` list

#### Scenario: Command is rejected
- **WHEN** a turn command fails validation or resolution
- **THEN** the player's `turns` list remains unchanged

#### Scenario: Turn history is projected
- **WHEN** a caller receives a regular session projection
- **THEN** each player's `turns` field is an array of accepted values in chronological order
- **AND** each item is an integer from 1 through 6 rather than an object

### Requirement: Ruleset owns static turn scalar domains
`D20.KoalaRescueClub.Ruleset` SHALL define the static round, active-turn, and die-value types. Game state, rules, and projections SHALL reference those ruleset-owned types instead of declaring duplicate literal ranges.

#### Scenario: Active game state is typed
- **WHEN** Koala game state types describe an active round, turn, roll, selection, or confirmed turn value
- **THEN** they reference the corresponding `Ruleset` round, turn, or die-value type

#### Scenario: Pre-start turn is typed
- **WHEN** the game state represents its pre-start turn sentinel
- **THEN** its type permits zero separately from the ruleset's active turn range
