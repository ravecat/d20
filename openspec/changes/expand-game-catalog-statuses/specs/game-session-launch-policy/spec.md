## ADDED Requirements

### Requirement: Session launch follows status and environment
The system SHALL allow new session launch only when the game status is `active` or `in_progress` and application session launch is enabled. Application session launch MUST be disabled in production and enabled in development and test.

#### Scenario: Active game outside production
- **WHEN** an active game detail page is requested outside production
- **THEN** new session launch is available

#### Scenario: In-progress game outside production
- **WHEN** an in-progress game detail page is requested outside production
- **THEN** new session launch is available for development and testing

#### Scenario: Inactive game outside production
- **WHEN** an inactive game detail page is requested outside production
- **THEN** new session launch is unavailable

#### Scenario: Any game in production
- **WHEN** any game detail page is requested in production
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
The session-creation endpoint MUST independently enforce the launch policy before resolving an engine or creating a session.

#### Scenario: Direct inactive launch request
- **WHEN** a client posts to `/games/:slug/sessions` for an inactive game
- **THEN** the endpoint returns `403 Forbidden` and creates no session

#### Scenario: Direct production launch request
- **WHEN** a client posts to `/games/:slug/sessions` while session launch is disabled
- **THEN** the endpoint returns `403 Forbidden` and creates no session

#### Scenario: Allowed launch request
- **WHEN** a client posts valid creation attributes for an active or in-progress game outside production
- **THEN** the existing session creation and redirect behavior is preserved
