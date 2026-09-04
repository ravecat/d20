## MODIFIED Requirements

### Requirement: Activation CTA reflects the session state
The system SHALL render a page-level `Play` CTA only before a Session exists and the persisted game is launchable. After a Session exists, the page SHALL render the existing Session surface without changing ownership of Session state.

#### Scenario: Launchable game with no Session renders Play
- **WHEN** a user opens `/games/qwinto` without a Session query and `can_launch_game` is true
- **THEN** the activation CTA label is `Play`
- **AND** activating it posts to `/games/qwinto/sessions`
- **AND** the CTA stretches across the available activation panel width

#### Scenario: Unlaunchable game with no Session hides Play
- **WHEN** a planned, environment-blocked, or disabled game detail has no Session
- **THEN** the activation panel renders no Play control

#### Scenario: Existing Session renders existing SessionPanel
- **WHEN** the page has a Session with module connection data
- **THEN** the activation panel renders `SessionPanel`
- **AND** the page does not pass a server Session snapshot into a second state owner

#### Scenario: Waiting Session behavior remains owned by SessionPanel
- **WHEN** the existing `SessionPanel` renders a waiting Session
- **THEN** start permissions, processing state, errors, and joined-player presence remain driven by the Session store created from the connection topic
- **AND** the panel-owned `Start` action uses the same primary button treatment as the page-level activation CTA

#### Scenario: In-progress Session behavior remains owned by SessionPanel
- **WHEN** the existing `SessionPanel` renders an in-progress Session
- **THEN** module frame behavior remains owned by the established Session surface without a second page-level realtime owner

### Requirement: Existing game page contracts are preserved
The system SHALL preserve existing slug-based game navigation, Session state ownership, module framing, and presentation behavior while using persisted TypeID for runtime authority.

#### Scenario: Detail route uses persisted slug
- **WHEN** a user opens a persisted game detail
- **THEN** lookup uses `/games/:slug`
- **AND** no environment-local TypeID is placed in the public URL

#### Scenario: Session creation route uses persisted slug
- **WHEN** the activation CTA creates a Session
- **THEN** the request target is `/games/:slug/sessions`
- **AND** the controller resolves that slug to the persisted game before creating a TypeID-associated Session

#### Scenario: Module connection props retain their purpose
- **WHEN** a Session has module connection data
- **THEN** the page passes the existing endpoint, topic, and token bootstrap to the module frame
- **AND** authority inside the token uses `game_id` TypeID rather than slug

#### Scenario: SessionPanel ownership is unchanged
- **WHEN** the game page renders the Session surface
- **THEN** it retains one realtime Session-state owner
