## ADDED Requirements

### Requirement: Normal projection exposes initial mark choices

For every adjusted die value reachable with the pending player's volunteers, the system SHALL project `tree` and `koala` mark choices with legal initial cells. The normal session projection MUST NOT contain an uncommitted primary selection.

#### Scenario: Pending player receives initial choices

- **WHEN** a pending player receives a submit-phase projection
- **THEN** each reachable die option contains only marks with legal initial cells
- **AND** the client can start a draft without deriving placement legality

#### Scenario: Caller cannot act

- **WHEN** the caller is not pending or the game is outside the submit phase
- **THEN** caller-specific turn options are empty

#### Scenario: Normal projection is rendered

- **WHEN** any caller receives a session projection
- **THEN** the projection does not contain `selection`

### Requirement: Draft evaluates a complete candidate without mutation

The system SHALL accept a synchronous `draft` request from a pending player with `mark`, `die_value`, and non-empty ordered unique `selected_cells`. It SHALL validate the complete candidate against the latest committed game and return caller-specific derived guidance without changing or publishing the session.

#### Scenario: One-cell draft is evaluated

- **WHEN** a pending player requests a legal one-cell draft
- **THEN** the reply echoes normalized mark, die value, and selected cells
- **AND** contains legal `available_cells`, `required_cells`, derived `volunteers_used`, `submit_ready`, `resolution`, and `bonus_options`
- **AND** the game state is byte-for-byte unchanged
- **AND** no session projection is broadcast

#### Scenario: Partial shape draft is evaluated

- **WHEN** selected cells are a legal multi-cell prefix smaller than the adjusted die shape
- **THEN** the reply has `submit_ready: false`
- **AND** `resolution` is absent
- **AND** available cells contain only legal continuations

#### Scenario: Complete shape draft is evaluated

- **WHEN** selected cells exactly match a legal adjusted die shape
- **THEN** the reply has `submit_ready: true`
- **AND** `resolution` is `shape`
- **AND** bonus options are derived from the complete primary result

#### Scenario: Draft is invalid or stale

- **WHEN** the caller, die value, cells, placement, or current player status makes a draft illegal
- **THEN** the request returns the applicable stable error
- **AND** the complete game and session state remain unchanged
- **AND** no session projection is broadcast

#### Scenario: Another caller observes the session

- **WHEN** one player receives a successful draft reply
- **THEN** no other player or spectator receives that candidate or reply

### Requirement: Candidate classification supports fallback and shape completion

The system SHALL classify a legal candidate from its selected cell count and adjusted die shape. Every supported die shape MUST contain at least two cells.

#### Scenario: One cell is a fallback and can be extended

- **WHEN** a legal one-cell candidate belongs to at least one legal full placement
- **THEN** it is submit-ready with resolution `single`
- **AND** its available cells contain every legal continuation

#### Scenario: One cell has no continuation

- **WHEN** a legal one-cell candidate belongs to no legal full placement
- **THEN** it remains submit-ready with resolution `single`
- **AND** available cells are empty

#### Scenario: Candidate exceeds shape size

- **WHEN** selected cells exceed the adjusted shape size
- **THEN** draft and submit reject the candidate

#### Scenario: Duplicate cells are supplied

- **WHEN** a draft or submit repeats the same cell
- **THEN** structural validation rejects the payload instead of silently changing candidate cardinality

### Requirement: Submit carries and commits the complete draft

The system SHALL use `submit` as the only public primary placement mutation. The payload MUST contain `mark`, `die_value`, `selected_cells`, and ordered `bonus_actions`. The system MUST revalidate the complete candidate and apply volunteers, the primary result, bonuses, omitted-bonus forfeiture, history, and player status atomically.

#### Scenario: One-cell tree or koala is submitted

- **WHEN** a pending player submits a legal one-cell candidate
- **THEN** exactly that tree or koala result is committed
- **AND** volunteer cost, bonuses, history, and player submission are committed in the same transition

#### Scenario: Full tree or koala shape is submitted

- **WHEN** a pending player submits a legal complete-shape candidate
- **THEN** every selected mark is committed atomically with the remaining turn effects

#### Scenario: Partial shape is submitted

- **WHEN** a pending player submits a multi-cell legal prefix that is not a complete shape
- **THEN** the command is rejected with `incomplete_turn_selection`
- **AND** the complete source aggregate remains unchanged

#### Scenario: Preview became stale

- **WHEN** a previously previewed candidate is no longer legal at submit time
- **THEN** submit rejects it using current committed state
- **AND** no primary, volunteer, bonus, history, or status change is committed

#### Scenario: Bonus validation fails

- **WHEN** any ordered bonus action is illegal
- **THEN** the whole submit is rejected
- **AND** no partial primary or bonus effect is committed

### Requirement: Structural failures identify draft or submit

Command normalization SHALL tag malformed payloads with the concrete attempted action.

#### Scenario: Draft payload is malformed

- **WHEN** draft candidate casting or normalization fails
- **THEN** the returned changeset action is `draft`

#### Scenario: Submit payload is malformed

- **WHEN** submit candidate or bonus normalization fails
- **THEN** the returned changeset action is `submit`

### Requirement: Staged and direct primary commands are unsupported

The public contract SHALL NOT contain `select`, `deselect`, `reset`, `plant_trees`, `rehome_koalas`, `circle_tree`, or `circle_koala`.

#### Scenario: Removed staged edit is sent

- **WHEN** a client sends `select`, `deselect`, or `reset`
- **THEN** the event is rejected as unsupported
- **AND** game state is unchanged

#### Scenario: Removed direct action is sent

- **WHEN** a client sends any removed direct primary action
- **THEN** the event is rejected as unsupported
- **AND** game state is unchanged

### Requirement: Selected sheet ruleset owns hospital identifiers

The system SHALL validate a hospital identifier structurally as a non-empty string and SHALL resolve it only against the pending player's selected rulesheet without creating atoms from transport input.

#### Scenario: Hospital belongs to selected sheet

- **WHEN** submit contains an unlocked hospital bonus with an identifier defined by that sheet
- **THEN** the existing ruleset key is resolved safely and the bonus is applied

#### Scenario: Hospital belongs only to another sheet

- **WHEN** the string is structurally valid but absent from the selected sheet
- **THEN** submit is rejected with `invalid_hospital`
- **AND** the aggregate remains unchanged

### Requirement: Separate client uses local draft with server guidance

The coordinated Koala client SHALL own only ephemeral candidate facts and bonus ordering. It SHALL request authoritative preview after each primary edit, use only returned legal continuations, and send the full candidate on submit.

#### Scenario: Player edits primary cells

- **WHEN** the player selects or deselects a target
- **THEN** the client updates its local candidate and requests `draft` with the complete current candidate
- **AND** it does not compute legal continuations from board structure

#### Scenario: Draft request fails

- **WHEN** draft is rejected or times out
- **THEN** the client returns to the last accepted preview

#### Scenario: Player reconnects

- **WHEN** the channel reconnects or a new session snapshot is established
- **THEN** the client clears unsubmitted primary and bonus draft state
- **AND** starts from normal projected initial options

#### Scenario: Player confirms

- **WHEN** the current preview is submit-ready and bonuses are valid
- **THEN** the client sends complete mark, die value, selected cells, and ordered bonus actions through `submit`
