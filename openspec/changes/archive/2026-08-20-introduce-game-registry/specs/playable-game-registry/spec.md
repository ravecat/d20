## ADDED Requirements

### Requirement: Implemented games are declared in a game registry
The system SHALL declare implemented playable games in a game registry keyed by internal game slug. Each game registry entry SHALL include exactly the stable operational fields needed to run and frame the game: `engine`, `bgg_id`, and `sandbox`.

#### Scenario: Registry entry declares a playable game
- **WHEN** the application loads a registry entry keyed by `qwinto`
- **THEN** the entry exposes `qwinto` as the internal game slug
- **AND** the entry includes an engine module
- **AND** the entry includes a BGG id
- **AND** the entry includes an iframe sandbox policy

#### Scenario: Registry entry excludes provider-derived metadata
- **WHEN** the application loads a registry entry
- **THEN** title, preview URL, description, player counts, and other BGG-derived display fields are not required stable registry fields

### Requirement: Game lookup uses the internal slug
The system SHALL resolve implemented games by internal slug from the game registry. The internal slug SHALL remain the route and application identity for game pages and sessions.

#### Scenario: Existing game slug is found
- **WHEN** a caller fetches game `qwinto`
- **THEN** the system returns the game registry entry for `qwinto`

#### Scenario: Unknown game slug is rejected
- **WHEN** a caller fetches a slug that is not present in the game registry
- **THEN** the system returns a game-not-found result

### Requirement: Session engine lookup uses the game registry
The system SHALL resolve the session engine for a game from the game registry entry associated with the internal slug.

#### Scenario: Session engine is resolved for a registered game
- **WHEN** a session is created for `qwinto`
- **THEN** the system uses the `engine` configured on the `qwinto` registry entry

#### Scenario: Invalid engine is rejected
- **WHEN** a registry entry references a module that does not satisfy the game engine contract
- **THEN** session creation fails with an engine validation error

### Requirement: Iframe sandbox policy uses the game registry
The system SHALL resolve iframe sandbox policy from the game registry entry associated with the internal slug.

#### Scenario: Sandbox is resolved for a registered game
- **WHEN** the page for `qwinto` needs iframe framing data
- **THEN** the system uses the `sandbox` configured on the `qwinto` registry entry

#### Scenario: Missing game has no iframe policy
- **WHEN** the page for an unknown game needs iframe framing data
- **THEN** the system returns a module-not-found or game-not-found result instead of using a default sandbox policy

### Requirement: BGG id is an external metadata binding
The system SHALL treat `bgg_id` as the external BGG metadata binding for a registered game. The system SHALL NOT use `bgg_id` as the primary application identity for routes, sessions, or engine lookup.

#### Scenario: Game route remains slug-based
- **WHEN** a registered game has `bgg_id` `183006`
- **THEN** its game page is still addressed by the internal route `/games/qwinto`

#### Scenario: Metadata lookup uses BGG id
- **WHEN** runtime metadata is requested for `qwinto`
- **THEN** the system uses the configured BGG id for the provider lookup
