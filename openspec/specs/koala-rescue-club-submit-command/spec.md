# koala-rescue-club-submit-command Specification

## Purpose
TBD - created by archiving change rename-koala-submit-command. Update Purpose after archive.
## Requirements
### Requirement: Submit commits the caller's stored selection
The Koala Rescue Club session protocol SHALL accept `submit` as the only event for committing a caller's stored complete shape selection. The event SHALL require ordered `bonus_actions` and SHALL preserve the existing atomic validation and transition behavior.

#### Scenario: Complete stored selection is submitted
- **WHEN** a pending player with a complete legal stored selection sends `submit` with valid ordered `bonus_actions`
- **THEN** the server commits the primary action and bonuses, spends required volunteers, records the adjusted die value, marks the player submitted, and clears the selection atomically

#### Scenario: Submission payload omits bonus decisions
- **WHEN** a pending player sends `submit` without `bonus_actions`
- **THEN** the server rejects the payload as an invalid command and leaves the game unchanged

#### Scenario: Submission fails rule validation
- **WHEN** a pending player sends `submit` for a missing or incomplete selection or with an invalid bonus decision
- **THEN** the server returns the existing specific rule error and leaves the sheet, volunteers, status, turn history, and stored selection unchanged

### Requirement: Legacy submission event is unsupported
The Koala Rescue Club session protocol SHALL NOT accept `submit_turn_selection` as an alias for `submit`.

#### Scenario: Client sends the legacy event
- **WHEN** a client sends `submit_turn_selection`
- **THEN** the server rejects the event without changing the game

### Requirement: Public contract documents submit
The Koala Rescue Club AsyncAPI document SHALL expose a `submit` message and operation with the existing submission payload shape and SHALL NOT advertise `submit_turn_selection`.

#### Scenario: Client reads the AsyncAPI contract
- **WHEN** a client inspects the Koala Rescue Club session commands
- **THEN** it finds `submit` requiring `bonus_actions` and finds no `submit_turn_selection` event

### Requirement: Dependent client sends submit
The dependent Koala Rescue Club client SHALL send the `submit` event through its session transport when confirming a stored complete selection. The client SHALL preserve the existing ordered `bonus_actions` payload and SHALL NOT send `submit_turn_selection`.

#### Scenario: Player confirms a stored shape selection
- **WHEN** the client confirms a complete stored shape selection with ordered bonus decisions
- **THEN** its session transport sends `submit` with those decisions in `bonus_actions`

#### Scenario: Client action API remains stable
- **WHEN** the turn workflow invokes its existing typed submission action
- **THEN** the transport maps that action to `submit` without requiring component or turn-store callers to use the wire event name
