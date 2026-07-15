## ADDED Requirements

### Requirement: Caller-specific turn fields are top-level session fields
The system SHALL expose the current caller's derived turn options as top-level `options` and the caller's staged turn selection as top-level `selection` on every Koala Rescue Club session projection. The system SHALL NOT expose a `turn` envelope or the former `turn_options` and `turn_selection` fields.

#### Scenario: Pending player receives flattened turn data
- **WHEN** a pending player receives a session projection for an actionable shared roll
- **THEN** the projection contains top-level `options` for that caller
- **AND** the projection contains top-level `selection` with that caller's current staged selection or `null`
- **AND** the projection does not contain a `turn`, `turn_options`, or `turn_selection` field

#### Scenario: Non-actionable caller receives stable empty values
- **WHEN** a caller cannot submit because there is no active roll or that caller is not pending
- **THEN** the projection contains top-level `options` as an empty object
- **AND** the projection contains top-level `selection` as `null`
- **AND** the projection does not contain a `turn` envelope

### Requirement: Flattening preserves caller-specific option semantics
The system SHALL preserve the existing turn-option map and recompute it from the current game state and caller when rendering top-level `options`.

#### Scenario: Active options preserve their value shape
- **WHEN** a pending player receives options for an actionable roll
- **THEN** top-level `options` contains the same six die-value entries, volunteer costs, available action membership, and legal cell lists that the server derives for that caller
- **AND** no option data is stored in the game aggregate as a result of flattening the projection

#### Scenario: Different callers retain independent options
- **WHEN** two pending players with different sheets or volunteer counts receive projections of the same game
- **THEN** each projection's top-level `options` is independently derived for its caller

### Requirement: Flattening preserves staged-selection privacy and recovery
The system SHALL expose only the current caller's rendered staged selection through top-level `selection` and SHALL preserve the stored selection needed to continue after a projection refresh.

#### Scenario: Selection owner receives the draft
- **WHEN** a player with an active staged selection receives a session projection
- **THEN** top-level `selection` contains that player's action, die value, volunteer use, required cells, selected cells, available cells, completion state, and bonus options

#### Scenario: Another player cannot see the draft
- **WHEN** another player receives a projection while the first player has an active staged selection
- **THEN** the other player's top-level `selection` is `null`
- **AND** no staged selection is exposed inside rendered player data or a nested `turn` object

#### Scenario: Projection refresh restores the same interaction
- **WHEN** the selection owner reconnects or receives a later projection before submitting
- **THEN** top-level `selection` contains the server-owned draft and derived continuation data needed to resume the interaction

### Requirement: The dependent module consumes only the flattened contract
The Koala Rescue Club module MUST type and read turn projection data from top-level `options` and `selection` without requiring the removed session `turn` envelope.

#### Scenario: Client initializes turn controls from a flattened projection
- **WHEN** the module receives a session projection containing top-level `options` and `selection`
- **THEN** its turn controls initialize available die values, actions, selected cells, and continuation cells from those fields
- **AND** the module does not require `session.turn` to render or continue the turn

#### Scenario: Existing command payloads remain unchanged
- **WHEN** the module submits an action selected from top-level `options` or completes top-level `selection`
- **THEN** it sends the existing command event and payload fields, including `volunteers_used`
- **AND** server command validation remains authoritative
