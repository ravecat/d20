## RENAMED Requirements

- FROM: `Session launch follows status and environment`
- TO: `Session launch follows stage, environment, and enabled state`

## MODIFIED Requirements

### Requirement: Session launch follows stage, environment, and enabled state
The system SHALL allow new Session launch only when enabled is true and the persisted game is released in any environment or in development outside production. It SHALL deny launch for planned games, in-development games in production, and every disabled game.

#### Scenario: Enabled released game in any environment
- **WHEN** an enabled released game detail is requested
- **THEN** new Session launch is available

#### Scenario: Enabled in-development game outside production
- **WHEN** an enabled in-development game detail is requested outside production
- **THEN** launch is available

#### Scenario: Enabled in-development game in production
- **WHEN** an enabled in-development game detail is requested in production
- **THEN** launch is unavailable

#### Scenario: Planned game in any environment
- **WHEN** a planned game detail is requested
- **THEN** launch is unavailable

#### Scenario: Disabled game in any stage or environment
- **WHEN** a persisted game has enabled false
- **THEN** launch is unavailable
- **AND** the game remains discoverable

### Requirement: Detail UI reflects launch policy
The game detail data contract SHALL expose whether new Session launch is allowed. The detail page SHALL render session-creation attributes and Play only when the complete stage, environment, enabled, and engine predicate allows launch.

#### Scenario: Launch is allowed
- **WHEN** the detail page receives `can_launch_game` true
- **THEN** it renders the game-owned creation fields and Play control

#### Scenario: Launch is denied
- **WHEN** the detail page receives `can_launch_game` false
- **THEN** it renders game metadata and description without an actionable Session-creation control

#### Scenario: Disabled released game is rendered
- **WHEN** a released game is disabled
- **THEN** its detail remains available with `can_launch_game` false and schema null

### Requirement: Session launch policy is enforced server-side
The id-based page and standalone-module Session-creation endpoints MUST independently enforce the complete launch policy before resolving an engine or creating a process. The standalone-module endpoint MAY return bootstrap data for an existing matching Session regardless of current stage, enabled, BGG, or engine edits.

#### Scenario: Direct planned launch request
- **WHEN** a client posts to `/games/:game_id/sessions` for a planned game
- **THEN** the endpoint returns `403 Forbidden`
- **AND** creates no Session

#### Scenario: Direct disabled launch request
- **WHEN** a client posts to `/games/:game_id/sessions` for a disabled game
- **THEN** the endpoint returns `403 Forbidden`
- **AND** creates no Session

#### Scenario: Disabled standalone launch request
- **WHEN** a client posts to `/modules/:game_id` without a Session id for a disabled game
- **THEN** the endpoint returns `403 Forbidden`
- **AND** creates no Session

#### Scenario: In-development production launch request
- **WHEN** a client posts to either id-based creation endpoint for an in-development game in production
- **THEN** the endpoint returns `403 Forbidden`
- **AND** creates no Session

#### Scenario: Existing standalone Session bootstrap
- **WHEN** a client posts a matching existing Session id to `/modules/:game_id`
- **THEN** the endpoint returns bootstrap independently of current launch availability

#### Scenario: Allowed launch request
- **WHEN** a client posts valid attrs for an enabled released game or enabled in-development game outside production
- **THEN** the existing Session creation and response behavior is preserved

#### Scenario: Game is disabled after Session creation
- **WHEN** an operator disables a game with a running Session
- **THEN** no channel, ModuleSocket, Workspace, or network path disconnects or reauthorizes that Session
