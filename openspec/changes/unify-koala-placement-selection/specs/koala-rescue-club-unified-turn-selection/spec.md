## ADDED Requirements

### Requirement: Turn options expose mark choices instead of primary actions

For every adjusted die value reachable with the pending player's available volunteers, the system SHALL project `tree` and `koala` mark choices with their legal initial cells. The projection MUST NOT expose `plant_trees`, `rehome_koalas`, `circle_tree`, or `circle_koala` as primary action identifiers.

#### Scenario: Tree targets are available

- **WHEN** a pending player can legally mark at least one tree cell for a reachable adjusted die value
- **THEN** that option contains `marks.tree.available_cells`
- **AND** every projected cell is a legal one-cell tree fallback
- **AND** every legal full-tree-shape starting cell is included

#### Scenario: Koala targets are available

- **WHEN** a pending player can legally mark at least one koala cell for a reachable adjusted die value
- **THEN** that option contains `marks.koala.available_cells`
- **AND** every projected cell contains a tree without a koala in an accessible area
- **AND** every legal full-koala-shape starting cell is included

#### Scenario: A mark has no legal target

- **WHEN** a pending player has no legal initial target for one mark at a reachable adjusted die value
- **THEN** that mark is absent from the option
- **AND** the other mark remains available when it has a legal target

#### Scenario: Caller cannot act

- **WHEN** the caller is not the pending player, has already submitted, lacks a roll, or the game is outside the submit phase
- **THEN** caller-specific turn options are empty

### Requirement: A pending player builds one authoritative mark selection

The system SHALL store at most one private primary selection per pending player. The canonical selection MUST contain only the selected mark, adjusted die value, and ordered unique cells. The system SHALL derive volunteer cost and all other guidance from current authoritative state and immutable rules.

#### Scenario: First cell starts a selection

- **WHEN** a pending player sends `select` with a valid `mark`, reachable `die_value`, and legal `target_cell`
- **THEN** the server stores a one-cell selection for that player
- **AND** the command does not change the committed sheet, volunteer slots, bonus resolutions, turn history, or player status

#### Scenario: Full context replaces an existing selection

- **WHEN** a pending player with an existing selection sends `select` with a valid full context and target
- **THEN** the server atomically replaces the old selection with the new one-cell selection
- **AND** no part of the old selection remains authoritative

#### Scenario: Target-only select continues a selection

- **WHEN** a pending player sends `select` with only `target_cell`
- **THEN** the server uses the stored mark and adjusted die value
- **AND** accepts the cell only when the resulting multi-cell set remains a subset of at least one legal full-shape placement

#### Scenario: Target-only select has no context

- **WHEN** a pending player without a selection sends target-only `select`
- **THEN** the command is rejected with `missing_turn_selection`
- **AND** the game state is unchanged

#### Scenario: Existing cell is selected again

- **WHEN** a pending player selects a cell already present in the current selection
- **THEN** the command is idempotently accepted
- **AND** the selection and committed state remain unchanged

#### Scenario: Invalid continuation is selected

- **WHEN** a pending player selects a second or later cell that cannot continue any legal full-shape placement
- **THEN** the command is rejected with `invalid_target`
- **AND** the prior selection remains unchanged

#### Scenario: Volunteer count is derived

- **WHEN** a selection is started for an adjusted die value
- **THEN** the server derives the required volunteer count from the shared roll and adjusted value
- **AND** `select` does not accept `volunteers_used` as authoritative input
- **AND** the canonical selection does not store the derived count

### Requirement: Selection classification supports fallback and shape completion

The system SHALL classify a valid selection from its cell count and the adjusted die shape size. Every supported die shape MUST contain at least two cells so one selected cell is unambiguously a fallback.

#### Scenario: One selected cell can be submitted and extended

- **WHEN** a valid one-cell selection belongs to at least one legal full-shape placement
- **THEN** the selection is submit-ready with resolution `single`
- **AND** its available cells contain every legal continuation from compatible full-shape placements
- **AND** the player may either submit the fallback or continue selecting

#### Scenario: One selected cell cannot be extended

- **WHEN** a valid one-cell selection belongs to no legal full-shape placement
- **THEN** the selection is submit-ready with resolution `single`
- **AND** its available cells are empty

#### Scenario: Multi-cell selection is incomplete

- **WHEN** the selected cell count is greater than one and less than the adjusted die shape size
- **THEN** the selection is not submit-ready
- **AND** resolution is absent
- **AND** available cells contain only legal full-shape continuations

#### Scenario: Full shape is complete

- **WHEN** the selected cells exactly match one legal transformed placement of the adjusted die shape
- **THEN** the selection is submit-ready with resolution `shape`
- **AND** no additional primary cells are available

#### Scenario: Selection exceeds the shape size

- **WHEN** a select command would produce more cells than the adjusted die shape size
- **THEN** the command is rejected
- **AND** the prior selection remains unchanged

### Requirement: Deselect and reset edit only the authoritative selection

The system SHALL let the pending player remove selected cells individually with `deselect` and clear the complete selection with `reset`. Neither edit SHALL mutate committed turn facts.

#### Scenario: Selected cell is removed

- **WHEN** a pending player deselects a cell in the current selection
- **THEN** the server removes that cell
- **AND** reclassifies the remaining cells and legal continuations

#### Scenario: Last cell is removed

- **WHEN** a pending player deselects the only selected cell
- **THEN** the server normalizes the selection to `nil`
- **AND** the player returns to an empty pending draft

#### Scenario: Unselected cell is deselected

- **WHEN** a pending player deselects a valid cell absent from the current selection
- **THEN** the command is idempotently accepted
- **AND** the selection remains unchanged

#### Scenario: Selection is reset

- **WHEN** a pending player sends `reset` with an empty payload
- **THEN** the complete selection is cleared
- **AND** the committed sheet, volunteers, bonuses, history, and player status remain unchanged

### Requirement: Submit atomically resolves either selected placement form

The system SHALL use `submit` as the only public command that commits a player-selected primary placement. It MUST revalidate the current selection and apply volunteer spending, the derived primary result, ordered bonus actions, omitted-bonus forfeiture, turn history, selection clearing, and player submission atomically.

#### Scenario: One tree cell is submitted

- **WHEN** a pending player submits a valid one-cell `tree` selection
- **THEN** the server marks exactly that tree cell
- **AND** applies the derived volunteer cost and valid ordered bonuses
- **AND** clears the selection and marks the player submitted

#### Scenario: One koala cell is submitted

- **WHEN** a pending player submits a valid one-cell `koala` selection
- **THEN** the server marks exactly that koala on an existing tree
- **AND** applies the derived volunteer cost and valid ordered bonuses
- **AND** clears the selection and marks the player submitted

#### Scenario: Full tree shape is submitted

- **WHEN** a pending player submits a valid shape-ready `tree` selection
- **THEN** the server marks every selected tree cell in one complete adjusted die shape
- **AND** commits the remaining turn effects atomically

#### Scenario: Full koala shape is submitted

- **WHEN** a pending player submits a valid shape-ready `koala` selection
- **THEN** the server marks every selected koala cell in one complete adjusted die shape
- **AND** commits the remaining turn effects atomically

#### Scenario: Partial shape is submitted

- **WHEN** a pending player submits a multi-cell selection smaller than the adjusted die shape
- **THEN** the command is rejected with `incomplete_turn_selection`
- **AND** the committed state and authoritative selection remain unchanged

#### Scenario: Selection is missing

- **WHEN** a pending player submits without an authoritative selection
- **THEN** the command is rejected with `missing_turn_selection`
- **AND** the game state remains unchanged

#### Scenario: Primary or bonus validation fails

- **WHEN** the current selection or any ordered bonus action is no longer legal at submission
- **THEN** the entire command is rejected with the applicable stable reason
- **AND** no primary mark, volunteer, bonus, history, status, or selection change is committed

### Requirement: Direct primary action commands are unsupported

The public Koala Rescue Club command contract SHALL contain no `plant_trees`, `rehome_koalas`, `circle_tree`, or `circle_koala` event. Primary placement intent MUST enter through `select`, primary cell removal through `deselect`, and accepted placement through `submit`.

#### Scenario: Legacy one-cell tree command is sent

- **WHEN** a client sends `circle_tree`
- **THEN** the command is rejected as unsupported
- **AND** the game state is unchanged

#### Scenario: Legacy one-cell koala command is sent

- **WHEN** a client sends `circle_koala`
- **THEN** the command is rejected as unsupported
- **AND** the game state is unchanged

#### Scenario: Legacy full-shape command is sent

- **WHEN** a client sends `plant_trees` or `rehome_koalas`
- **THEN** the command is rejected as unsupported
- **AND** the game state is unchanged

### Requirement: Caller projection exposes a private resumable selection

The system SHALL expose the authoritative selection only to its pending player. The selection projection SHALL contain the stored mark, adjusted die value, selected cells, and derived volunteer cost, shape size, legal continuations, submission readiness, resolution form, and bonus options needed to render and resume the workflow.

#### Scenario: Acting player receives a one-cell selection

- **WHEN** the acting player has a one-cell authoritative selection
- **THEN** their projection contains that selected cell and mark
- **AND** exposes `submit_ready: true`, `resolution: single`, derived `volunteers_used`, compatible continuations, and current bonus options

#### Scenario: Acting player receives a partial shape

- **WHEN** the acting player has a multi-cell incomplete selection
- **THEN** their projection contains every selected cell and legal continuation
- **AND** exposes `submit_ready: false`, no resolution, and no primary bonus options

#### Scenario: Acting player receives a complete shape

- **WHEN** the acting player has a complete legal shape selection
- **THEN** their projection exposes `submit_ready: true`, `resolution: shape`, no additional primary cells, and bonuses unlocked by that candidate

#### Scenario: Acting player reconnects

- **WHEN** the pending player reconnects during the live session
- **THEN** the same authoritative primary selection and derived guidance are rendered from current game state
- **AND** the client does not reconstruct primary cells from local history

#### Scenario: Another caller receives the session

- **WHEN** another player or spectator receives a caller-specific projection
- **THEN** the acting player's selection is absent
- **AND** only committed sheet facts and permitted public status remain visible

### Requirement: Separate client consumes the unified server selection

The separately delivered Koala Rescue Club client SHALL treat projected primary selection as authoritative for both one-cell and full-shape placement. It MUST send every primary target edit through the staged commands and MUST NOT retain a client-owned primary selection or direct single-cell command path.

#### Scenario: Player selects a first primary cell

- **WHEN** the player activates a projected tree or koala target with no matching authoritative selection
- **THEN** the client sends full-context `select`
- **AND** renders the selected primary only after reconciling the server projection

#### Scenario: Player edits the primary selection

- **WHEN** the player activates a projected continuation or selected primary cell
- **THEN** the client sends `select` or `deselect` respectively
- **AND** reconciles the resulting selected and available cells from the next projection

#### Scenario: Player confirms either placement form

- **WHEN** the projected selection is submit-ready and the player confirms
- **THEN** the client sends `submit` with the ordered local bonus actions
- **AND** never sends `circle_tree` or `circle_koala`

#### Scenario: Command fails or times out

- **WHEN** a selection edit or submit fails without changing the turn
- **THEN** the client reconciles from the last authoritative selection
- **AND** preserves only valid client-local presentation and ordered bonus state permitted by that selection

#### Scenario: Client contract is migrated

- **WHEN** the unified backend contract is adopted
- **THEN** client public types, SDK command methods, centralized store transitions, turn reducer, controls, both map widgets, fixtures, and browser tests agree with the mark-based selection
- **AND** embedded and standalone startup boundaries remain unchanged
