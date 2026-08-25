## MODIFIED Requirements

### Requirement: Started game module renders as a fixed viewport overlay
The system SHALL render the game module frame as a fixed viewport overlay when a Session is in progress or finished, using the Session's stable local game association.

This behavior keeps the playable surface stable and centered after start, including terminal state, independently of detail preview, metadata, activation panel, description panel, scroll position, enabled state, implementation stage, or later game-record edits.

#### Scenario: In-progress Session shows module above page
- **WHEN** a user opens `/games/:game_id?session=<session-id>` for a matching local game id
- **AND** Session phase is `in_progress`
- **THEN** the module iframe renders above full page content
- **AND** is not an in-flow child of the activation panel
- **AND** detail content remains behind the overlay

#### Scenario: Finished Session keeps module above page
- **WHEN** a user opens an id-based matching detail with a finished Session
- **THEN** the module iframe remains above full page content
- **AND** the embedded game can render final projection and results

#### Scenario: Module frame is centered in viewport
- **WHEN** the module overlay is visible
- **THEN** the iframe is centered horizontally and vertically
- **AND** page scroll does not change its viewport position

#### Scenario: Module frame uses bounded viewport sizing
- **WHEN** the overlay is visible on desktop
- **THEN** its container adds no iframe padding
- **AND** iframe width and height do not exceed viewport bounds
- **AND** it keeps a stable game-friendly aspect ratio

#### Scenario: Module frame remains usable on narrow viewports
- **WHEN** the overlay is visible on a narrow viewport
- **THEN** it remains within the visible viewport
- **AND** the user can interact with module content

#### Scenario: Detail layout no longer reserves inline frame space
- **WHEN** Session phase becomes `in_progress`
- **THEN** the activation panel reserves no previous fixed-height inline frame area
- **AND** old in-panel frame margin and border treatment are unnecessary

#### Scenario: Embedded module is not inset by shell spacing
- **WHEN** the overlay is visible
- **THEN** the shell frame container adds no iframe padding
- **AND** presents the module without extra host-page spacing

### Requirement: Module frame contracts are preserved
The system SHALL preserve module iframe framing and Session connection behavior while replacing slug authority with the full `game` TypeID in module routes, scope, and token claims and its DNS-safe suffix projection in module hosts.

#### Scenario: Module props retain their roles
- **WHEN** the page renders an in-progress or finished frame
- **THEN** `embedUrl`, `allowedOrigins`, and `sandbox` are passed to iframe behavior
- **AND** endpoint, topic, and token bootstrap are passed unchanged in purpose
- **AND** embed host and token authority use local game id

#### Scenario: Session ownership remains in SessionPanel
- **WHEN** the game page has a Session with module connection data
- **THEN** `SessionPanel` remains the owner of realtime state
- **AND** the page does not add a second Session-state owner for overlay visibility

#### Scenario: Waiting Session still renders activation controls
- **WHEN** Session phase is `waiting_for_players`
- **THEN** the page renders existing waiting controls and joined-player state
- **AND** the fixed module overlay is not visible

#### Scenario: Module frame waits for realtime phase
- **WHEN** realtime Session projection is loading and phase unavailable
- **THEN** the fixed overlay is not visible
- **AND** iframe is not mounted speculatively

#### Scenario: Game record changes after start
- **WHEN** an operator disables the game or edits BGG, stage, or engine after a Session starts
- **THEN** the existing frame remains associated with the same local game id
- **AND** the Session retains its captured engine
