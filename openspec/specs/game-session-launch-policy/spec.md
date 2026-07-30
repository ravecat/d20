# game-session-launch-policy Specification

## Purpose
TBD - created by archiving change expand-game-catalog-statuses. Update Purpose after archive.
## Requirements
### Requirement: Session launch follows status and environment
The system SHALL allow new session launch for active games in every environment. It SHALL allow new session launch for in-progress games in development and test but not in production. It SHALL deny new session launch for inactive games in every environment.

#### Scenario: Active game in any environment
- **WHEN** an active game detail page is requested
- **THEN** new session launch is available

#### Scenario: In-progress game outside production
- **WHEN** an in-progress game detail page is requested outside production
- **THEN** new session launch is available for development and testing

#### Scenario: In-progress game in production
- **WHEN** an in-progress game detail page is requested in production
- **THEN** new session launch is unavailable

#### Scenario: Inactive game in any environment
- **WHEN** an inactive game detail page is requested
- **THEN** new session launch is unavailable

### Requirement: Detail UI reflects launch policy
The game detail data contract SHALL expose whether new session launch is allowed. The detail page SHALL render session-creation attributes and the Play control only when launch is allowed.

#### Scenario: Launch is allowed
- **WHEN** the detail page receives `can_launch_game` as true
- **THEN** it renders the game-owned creation fields and Play control

#### Scenario: Launch is denied
- **WHEN** the detail page receives `can_launch_game` as false
- **THEN** it renders game metadata and description without an actionable session-creation control

### Requirement: Session launch policy is enforced server-side
The page and standalone-module session-creation endpoints MUST independently enforce the launch policy before resolving an engine or creating a session. The standalone-module endpoint MAY return bootstrap data for an existing matching session even when creation is disabled.

#### Scenario: Direct inactive launch request
- **WHEN** a client posts to `/games/:slug/sessions` for an inactive game
- **THEN** the endpoint returns `403 Forbidden` and creates no session

#### Scenario: Direct in-progress production launch request
- **WHEN** a client posts to `/games/:slug/sessions` for an in-progress game in production
- **THEN** the endpoint returns `403 Forbidden` and creates no session

#### Scenario: Standalone in-progress production launch request
- **WHEN** a client posts to `/modules/:slug` without a session identifier for an in-progress game in production
- **THEN** the endpoint returns `403 Forbidden` and creates no session

#### Scenario: Existing standalone session bootstrap
- **WHEN** a client posts a matching existing session identifier to `/modules/:slug`
- **THEN** the endpoint returns bootstrap data independently of new-session launch availability

#### Scenario: Allowed launch request
- **WHEN** a client posts valid creation attributes to a public session-creation endpoint for an active game in any environment or an in-progress game outside production
- **THEN** the existing session creation and response behavior is preserved
