## ADDED Requirements

### Requirement: Game stores only committed player state
The Koala Rescue Club game aggregate SHALL store shared committed player facts and SHALL NOT store an unfinished turn selection.

#### Scenario: Player joins a game
- **WHEN** a player is added to a Koala Rescue Club game
- **THEN** the player state contains sheet, status, badge, and round facts without a turn selection field

#### Scenario: Shape draft is projected
- **WHEN** a pending player requests a projection for an unfinished shape draft
- **THEN** the game aggregate remains unchanged
- **AND** no session projection is broadcast to other clients

### Requirement: Turn options are caller-specific projections
The server SHALL derive turn options in the Koala projection from the current committed game, caller identity, rules, and ruleset data.

#### Scenario: Pending player receives options
- **WHEN** a pending player receives a session projection during the submit phase
- **THEN** `options` contains affordable die values, legal primary actions, volunteer costs, and available target cells for that player

#### Scenario: Non-actionable caller receives no options
- **WHEN** the caller cannot submit a turn
- **THEN** the session projection contains an empty `options` object

### Requirement: Client submits the complete draft for stateless projection
The client SHALL keep the unfinished shape draft locally and SHALL send its complete action, die value, volunteer count, and selected cell list in each `project_turn_selection` request.

#### Scenario: Player adds a shape cell
- **WHEN** the player adds a cell to the local shape draft
- **THEN** the client sends all currently selected cells in one `project_turn_selection` request

#### Scenario: Player removes a shape cell
- **WHEN** the player removes a cell from the local shape draft
- **THEN** the client sends the complete remaining selected cell list in one `project_turn_selection` request

#### Scenario: Player resets the shape draft
- **WHEN** the player resets an unfinished shape selection
- **THEN** the client clears its local draft without dispatching a game mutation

### Requirement: Server projects selection details without mutation
The server SHALL validate a `project_turn_selection` request against the current game and SHALL reply with derived selection details without dispatching a game command or broadcasting a session update.

#### Scenario: Partial legal shape
- **WHEN** a pending player projects a draft whose selected cells are a subset of at least one legal placement
- **THEN** the reply contains the normalized selected cells, compatible available cells, required cell count, `complete: false`, and no committed game change

#### Scenario: Complete legal shape
- **WHEN** a pending player projects a draft that exactly matches a legal placement
- **THEN** the reply contains `complete: true`, an empty available cell list, and bonus options derived from the simulated committed action

#### Scenario: Invalid draft
- **WHEN** the projected draft has invalid context, unaffordable volunteers, or cells incompatible with every legal placement
- **THEN** the server returns an error reply
- **AND** the game aggregate remains unchanged

### Requirement: Regular session projections omit unfinished selection
The regular Koala Rescue Club session projection SHALL NOT contain an active selection field because unfinished selection is client-owned state.

#### Scenario: Join and broadcast projections
- **WHEN** a client joins a session or receives a pushed session projection
- **THEN** the payload contains caller-specific `options`
- **AND** the payload does not contain `selection`

### Requirement: Full selection is submitted atomically
The `submit_turn_selection` command SHALL contain the complete shape selection and bonus actions, and the server SHALL validate and apply them atomically against the current committed game.

#### Scenario: Valid complete submission
- **WHEN** a pending player submits a complete legal selection with a valid bonus sequence
- **THEN** the server commits the sheet changes and marks the player submitted

#### Scenario: Incomplete or stale submission
- **WHEN** a player submits an incomplete selection or a selection that is no longer legal against the current game
- **THEN** the server returns an error
- **AND** the player's committed sheet and status remain unchanged

#### Scenario: Submission does not depend on a prior projection
- **WHEN** a pending player submits a complete valid selection without first requesting `project_turn_selection`
- **THEN** the server validates and commits the command successfully

### Requirement: Projection code owns turn read-model shapes
The Koala projection module SHALL define and assemble the public `options` and `selection` read models while rule modules SHALL expose domain legality primitives rather than projection-specific maps.

#### Scenario: Projection builds options and selection
- **WHEN** caller-specific turn data is rendered
- **THEN** the projection combines game facts, ruleset values, and rule legality results into the public wire shape
- **AND** the game and rules modules do not define turn option or turn selection projection types
