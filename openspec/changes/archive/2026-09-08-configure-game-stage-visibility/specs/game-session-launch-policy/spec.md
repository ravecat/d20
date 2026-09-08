## MODIFIED Requirements

### Requirement: Session launch follows stage, environment, and enabled state
The system SHALL allow new Session launch only when enabled is true, the persisted stage belongs to `:visible_game_stages`, and the game has a supported engine. The checked-in default SHALL permit released games only; development configuration SHALL permit released and in-development games. The predicate SHALL read configured stages at runtime without inspecting environment identity. It SHALL deny every disabled game, every game without a supported engine, and every game whose stage is absent from the configured list.

#### Scenario: Enabled released game in any environment
- **WHEN** an enabled released game with a supported engine is resolved under the default stage policy
- **THEN** new Session launch is available

#### Scenario: Enabled in-development game in development
- **WHEN** an enabled in-development game with a supported engine is resolved with both stages configured
- **THEN** launch is available

#### Scenario: Enabled in-development game in production
- **WHEN** an enabled in-development game is resolved under the default released-only policy
- **THEN** launch is unavailable

#### Scenario: Disabled game in any stage or environment
- **WHEN** a persisted game has enabled false
- **THEN** launch is unavailable
- **AND** an environment-visible detail route remains available

#### Scenario: Game has no supported engine
- **WHEN** a persisted game has no engine or engine validation fails
- **THEN** launch is unavailable

#### Scenario: No stage is configured as visible
- **WHEN** `:visible_game_stages` is empty
- **THEN** no game permits new Session launch, including enabled released games with supported engines

#### Scenario: Policy changes without recompilation
- **WHEN** the configured stage list changes in the running application
- **THEN** subsequent launch checks use the new list without changing an environment-name setting or recompiling modules

### Requirement: Detail UI reflects launch policy
The game detail data contract SHALL expose whether new Session launch is allowed. The detail page SHALL render session-creation attributes and Play only when the complete configured-stage, enabled, and engine predicate allows launch.

#### Scenario: Launch is allowed
- **WHEN** the detail page receives `can_launch_game` true
- **THEN** it renders the game-owned creation fields and Play control

#### Scenario: Launch is denied
- **WHEN** the detail page receives `can_launch_game` false
- **THEN** it renders game metadata and description without an actionable Session-creation control

#### Scenario: Disabled released game is rendered
- **WHEN** a released game is disabled
- **THEN** its detail remains available with `can_launch_game` false and schema null
