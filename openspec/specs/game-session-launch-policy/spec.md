# game-session-launch-policy Specification

## Purpose
Define authoritative new-Session launch eligibility across persisted stage, environment, enabled state, engine availability, UI, and server boundaries.
## Requirements
### Requirement: Session launch follows stage, environment, and enabled state
The system SHALL allow new Session launch only when enabled is true, the persisted stage belongs to `:visible_game_stages`, and the game has a supported engine. The checked-in default SHALL permit released games only; development configuration SHALL permit released and in-development games. The predicate SHALL read configured stages at runtime without inspecting environment identity. It SHALL deny every disabled game, every game without a supported engine, every game whose stage is absent from the configured list, and every provider-only detail without a persisted local game. A route slug, including a numeric BGG slug, SHALL NOT establish launch eligibility.

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

#### Scenario: Provider-only game has no launch identity
- **WHEN** a detail resolves solely from BGG metadata without a persisted local game
- **THEN** launch is unavailable regardless of route slug or metadata fields

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

#### Scenario: Provider-only Session creation is requested directly
- **WHEN** a client posts to `/games/224517/sessions` and no exact persisted slug `224517` exists
- **THEN** the existing persisted-slug-only creation boundary returns 404 without invoking BGG fallback
- **AND** no Session process or Game record is created

#### Scenario: Provider-only detail is given a Session parameter
- **WHEN** a provider-only numeric detail request includes any Session id
- **THEN** no local Session is attached and the response uses the existing 303 Session-not-found error redirect to the bare numeric detail URL
- **AND** following that URL can render provider metadata without a Session
