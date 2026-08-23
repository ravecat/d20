## MODIFIED Requirements

### Requirement: Registry represents catalog availability
The system SHALL allow each configured game to declare optional availability status `active` or `in_progress`. The system SHALL treat a missing status as inactive. Active and in-progress entries MUST include a valid local engine binding; inactive entries MUST be valid with only a slug and BGG identifier. Registry availability validation SHALL NOT require or accept a per-entry iframe sandbox policy.

#### Scenario: Active game is operationally bound
- **WHEN** a registry entry declares status `active`
- **THEN** the registry requires its engine binding
- **AND** it does not require a sandbox binding

#### Scenario: In-progress game is operationally bound
- **WHEN** a registry entry declares status `in_progress`
- **THEN** the registry requires its engine binding
- **AND** it does not require a sandbox binding

#### Scenario: Missing status is inactive
- **WHEN** a registry entry omits status and engine
- **THEN** the registry accepts it as an inactive catalog entry with its slug and BGG identifier
