## MODIFIED Requirements

### Requirement: Detail UI reflects launch policy
The game detail contract SHALL expose new-Session launch eligibility as required boolean `playable`, replacing `can_launch_game` / `canLaunchGame` without an alias. Its value SHALL use the complete existing configured-stage, enabled, and supported-engine predicate and SHALL be false for provider-only details. It SHALL NOT be persisted or interpreted as proof of engine existence. Without an existing Session, the page SHALL render `SessionForm` with creation attributes and Play only when playable is true and a schema exists; playable false SHALL select `InterestForm`. Existing Sessions SHALL retain Lobby precedence regardless of current playability.

#### Scenario: Launch is allowed
- **WHEN** the detail page receives playable true and a creation schema without a Session
- **THEN** it renders `SessionForm` with the game-owned creation fields and Play control
- **AND** no `InterestForm` is shown

#### Scenario: Launch is denied
- **WHEN** the detail page receives playable false without a Session
- **THEN** it renders game metadata and description without a Session-creation control
- **AND** `InterestForm` presents `I want this game!` or the account's saved-interest state

#### Scenario: Disabled released game is rendered
- **WHEN** a released game is disabled
- **THEN** its detail remains available with playable false and schema null
- **AND** without a Session it offers interest without claiming that its engine is missing

#### Scenario: Provider-only detail renders metadata without Play
- **WHEN** the page receives provider-only details with playable false, schema null, and session null
- **THEN** it renders existing metadata and description with `InterestForm` and its request action or saved state
- **AND** it renders no `SessionForm`, Play control, disabled Play, or Lobby

#### Scenario: Existing Session remains accessible
- **WHEN** a validated matching Session is rendered after the game becomes disabled or hidden
- **THEN** the existing Lobby renders even with playable false
- **AND** the page does not replace it with `InterestForm`

#### Scenario: Playable page lacks a schema
- **WHEN** a page incorrectly receives playable true and schema null without a Session
- **THEN** the client does not interpret the absent schema as non-playability or show `InterestForm`

#### Scenario: Direct launch authorization remains authoritative
- **WHEN** a caller changes frontend playable state or sends a direct Session-creation request
- **THEN** the existing page and standalone-module endpoints still independently enforce their unchanged launch policy
