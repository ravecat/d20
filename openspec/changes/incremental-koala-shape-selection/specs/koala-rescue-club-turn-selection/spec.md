## ADDED Requirements

### Requirement: The first cell click starts a server-guided shape selection
The system SHALL expose initial legal cells after the roll and let a pending Koala Rescue Club player start one incremental `plant_trees` or `rehome_koalas` selection by selecting one cell for a die value reachable with the player's available volunteers.

#### Scenario: First tree click starts a legal selection
- **WHEN** a pending player selects a projected initial tree cell with a reachable die value and at least one legal tree placement exists
- **THEN** the system stores the selected action, die value, required volunteer count, and selected cell for that player
- **AND** the system does not circle a tree, spend a volunteer, or change the player's pending status

#### Scenario: First koala click starts a legal selection
- **WHEN** a pending player selects a projected initial koala cell with a reachable die value and at least one complete legal placement exists on circled trees without circled koalas
- **THEN** the system creates a koala selection containing that cell
- **AND** the selection can be continued one cell at a time

#### Scenario: Selection cannot start without a legal placement
- **WHEN** the chosen action and die value have no complete legal placement on the player's current accessible sheet
- **THEN** the system exposes no initial cell for that action and rejects a forged cell command
- **AND** the player's existing selection, sheet, volunteers, and status remain unchanged

#### Scenario: Clicking with another context replaces only draft state
- **WHEN** a pending player with an unfinished selection selects an initial cell for another legal action or reachable die value
- **THEN** the system replaces that player's previous selection with a new selection containing that cell
- **AND** no committed sheet or volunteer state changes

### Requirement: Available cells preserve at least one legal completion
The system SHALL derive each selection's available cells from complete legal placements of every allowed rotation and reflection of the chosen die shape.

#### Scenario: Initial cells are derived from all legal placements
- **WHEN** a pending player receives turn options after the roll
- **THEN** each legal shape action exposes the distinct cells that occur in at least one complete legal placement for its die value
- **AND** it does not expose cells in inaccessible areas or cells that violate the action prerequisites

#### Scenario: One selected cell narrows later choices
- **WHEN** a player selects an available cell
- **THEN** the system retains only complete legal placements containing every selected cell
- **AND** the system recalculates available cells as the unselected cells in those retained placements

#### Scenario: Legal growth is independent of selection order
- **WHEN** the same partial cell set is selected in a different order
- **THEN** the system exposes the same completion state and available-cell set

#### Scenario: Dead-end cell is rejected
- **WHEN** a player selects a cell that is not available for the current partial selection
- **THEN** the system rejects the command
- **AND** the existing selection remains unchanged

#### Scenario: Complete shape is recognized
- **WHEN** the selected cells exactly equal a complete legal placement for the chosen die shape
- **THEN** the system marks the selection complete
- **AND** no additional shape cell is available
- **AND** the committed player sheet remains unchanged until submission

### Requirement: Players can safely edit or reset a partial selection
The system SHALL support explicit, idempotent cell selection, cell deselection, and selection reset while the player remains pending.

#### Scenario: Repeated selection is idempotent
- **WHEN** a player selects a cell that is already selected in the current draft
- **THEN** the system returns the same selected and available cells without duplicating the cell

#### Scenario: Deselection restores alternatives
- **WHEN** a player deselects a selected cell
- **THEN** the system removes that cell from the partial selection
- **AND** the system recalculates all cells that can extend the remaining partial selection

#### Scenario: Repeated deselection is idempotent
- **WHEN** a player deselects a cell that is not selected
- **THEN** the system returns the selection unchanged

#### Scenario: Reset discards the draft
- **WHEN** a pending player resets the current selection
- **THEN** the system removes the selection
- **AND** the player's sheet, volunteers, and pending status remain unchanged

#### Scenario: Submitted player cannot edit a selection
- **WHEN** a player who already submitted for the current turn sends a selection edit command
- **THEN** the system rejects the command as already submitted

### Requirement: Complete selections submit atomically
The system SHALL commit a complete incremental selection, its volunteer cost, and its ordered bonus decisions as one turn submission.

#### Scenario: Complete selection is submitted
- **WHEN** a pending player submits a complete selection with valid bonus decisions
- **THEN** the system revalidates the complete shape against the current authoritative roll, map, sheet, and available volunteers
- **AND** the system spends the required volunteers
- **AND** the system applies every selected tree or koala cell
- **AND** the system resolves bonus decisions in submitted order
- **AND** the system clears the selection and marks the player submitted

#### Scenario: Incomplete selection cannot submit
- **WHEN** a player submits a selection with fewer cells than the chosen die shape requires
- **THEN** the system rejects the submission
- **AND** the partial selection remains available for further editing
- **AND** no sheet, volunteer, bonus, or player status changes

#### Scenario: Newly unlocked bonuses are previewed before submission
- **WHEN** a complete selection would finish a bonus-bearing koala line
- **THEN** the caller's selection projection exposes the bonus decisions unlocked by the simulated primary action
- **AND** the committed sheet still reports the bonus as unclaimed

#### Scenario: Invalid bonus preserves the complete selection
- **WHEN** a player submits a complete selection with an invalid, unavailable, previously resolved, or incorrectly ordered bonus decision
- **THEN** the system rejects the entire submission
- **AND** the complete selection remains available for correction
- **AND** no primary action, volunteer spending, or bonus effect is committed

#### Scenario: Turn advances through the existing simultaneous flow
- **WHEN** the last pending player successfully submits a complete selection
- **THEN** the system performs the existing badge, round, score, finish, or next-turn transitions
- **AND** partial selections never count as submitted turns

### Requirement: Selection projections are caller-specific
The system SHALL project the current player's incremental selection and legal options without exposing unfinished selections to other players.

#### Scenario: Owner receives active selection state
- **WHEN** a player with an active selection receives a session projection
- **THEN** the projection includes the action, die value, volunteer cost, required cell count, selected cells, available cells, completion state, and applicable bonus options for that player

#### Scenario: Projection refresh restores interaction state
- **WHEN** a player reconnects or receives a later projection before submitting
- **THEN** the projection contains the server-owned selection needed to continue the same interaction

#### Scenario: Other player cannot see the draft
- **WHEN** another player receives a projection while the first player has an unfinished selection
- **THEN** the other player's projection does not include the first player's selected cells, available cells, action, or adjusted die value
- **AND** the committed game sheet remains the only visible board state for the first player

#### Scenario: Turn options do not require client-side transforms
- **WHEN** a pending player receives turn options after the shared roll
- **THEN** each reachable die option identifies its volunteer cost, required cell count, and each shape action's initial available cells
- **AND** the client is not required to choose or submit a rotation or reflection identifier

### Requirement: Whole-shape submission is replaced without changing fallback actions
The system SHALL use incremental selection as the only mutation path for multi-cell `plant_trees` and `rehome_koalas` actions while preserving the existing single-cell fallback behavior.

#### Scenario: Legacy target cell list is rejected
- **WHEN** a client sends a direct `plant_trees` or `rehome_koalas` command containing the complete `target_cells` list
- **THEN** the system rejects the obsolete command contract
- **AND** no turn state changes

#### Scenario: Single tree fallback remains atomic
- **WHEN** a pending player submits a valid `circle_tree` command
- **THEN** the system applies the existing one-cell tree fallback without creating a shape selection

#### Scenario: Single koala fallback remains atomic
- **WHEN** a pending player submits a valid `circle_koala` command
- **THEN** the system applies the existing one-cell koala fallback without creating a shape selection
