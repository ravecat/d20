## MODIFIED Requirements

### Requirement: Session launch follows stage, environment, and enabled state
The system SHALL allow new Session launch only when enabled is true and the persisted game is released in any environment or in development in the dev application environment. It SHALL derive this from application environment identity without a separate allow-launch flag. It SHALL deny launch for in-development games outside dev, every disabled game, and every game without a supported engine.

#### Scenario: Enabled released game in any environment
- **WHEN** an enabled released game with a supported engine is resolved
- **THEN** new Session launch is available

#### Scenario: Enabled in-development game in development
- **WHEN** an enabled in-development game with a supported engine is resolved in development
- **THEN** launch is available

#### Scenario: Enabled in-development game in production
- **WHEN** an enabled in-development game is resolved in production
- **THEN** launch is unavailable

#### Scenario: Disabled game in any stage or environment
- **WHEN** a persisted game has enabled false
- **THEN** launch is unavailable
- **AND** an environment-visible detail route remains available

#### Scenario: Game has no supported engine
- **WHEN** a persisted game has no engine or engine validation fails
- **THEN** launch is unavailable

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
The slug-based page and id-based standalone-module Session-creation endpoints MUST independently enforce the complete launch policy before resolving an engine or creating a process. The standalone-module endpoint MAY return bootstrap data for an existing matching Session regardless of current stage, enabled, BGG, or engine edits.

#### Scenario: Direct engine-less launch request
- **WHEN** a client posts to `/games/:slug/sessions` for an in-development game without an engine
- **THEN** the endpoint returns `403 Forbidden`
- **AND** creates no Session

#### Scenario: Direct disabled launch request
- **WHEN** a client posts to `/games/:slug/sessions` for a disabled game
- **THEN** the endpoint returns `403 Forbidden`
- **AND** creates no Session

#### Scenario: Disabled standalone launch request
- **WHEN** a client posts to `/modules/:game_id` without a Session id for a disabled game
- **THEN** the endpoint returns `403 Forbidden`
- **AND** creates no Session

#### Scenario: In-development production launch request
- **WHEN** a client posts to either Session-creation endpoint for an in-development game in production
- **THEN** the endpoint returns `403 Forbidden`
- **AND** creates no Session

#### Scenario: Existing standalone Session bootstrap
- **WHEN** a client posts a matching existing Session id to `/modules/:game_id`
- **THEN** the endpoint returns bootstrap independently of current launch availability

#### Scenario: Allowed launch request
- **WHEN** a client posts valid attrs for an enabled released game or enabled in-development game in development
- **THEN** the existing Session creation and response behavior is preserved

#### Scenario: Game is disabled after Session creation
- **WHEN** an operator disables a game with a running Session
- **THEN** no channel, ModuleSocket, Workspace, or network path disconnects or reauthorizes that Session
