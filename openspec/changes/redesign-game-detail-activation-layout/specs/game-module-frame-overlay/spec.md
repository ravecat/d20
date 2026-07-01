## ADDED Requirements

### Requirement: In-progress game module renders as a fixed viewport overlay
The system SHALL render the game module frame as a fixed viewport overlay when a session is in progress.

This behavior is for keeping the playable game surface stable and centered after the session starts, independent of the game detail page's preview, metadata, activation panel, description panel, or scroll position.

#### Scenario: In-progress session shows the module above the page
- **WHEN** a user opens `/games/qwinto?session=<session-id>`
- **AND** the session phase is `in_progress`
- **THEN** the module iframe is rendered above the full page content
- **AND** the module iframe is not laid out as an in-flow child of the activation panel
- **AND** the game detail page content remains behind the overlay

#### Scenario: Module frame is centered in the viewport
- **WHEN** the module overlay is visible
- **THEN** the iframe is centered horizontally in the viewport
- **AND** the iframe is centered vertically in the viewport
- **AND** page scroll position does not change the iframe's viewport position

#### Scenario: Module frame uses bounded viewport sizing
- **WHEN** the module overlay is visible on a desktop viewport
- **THEN** the overlay container does not add padding around the iframe
- **AND** the iframe width does not exceed the viewport width
- **AND** the iframe height does not exceed the viewport height
- **AND** the iframe keeps a stable game-friendly aspect ratio

#### Scenario: Module frame remains usable on narrow viewports
- **WHEN** the module overlay is visible on a narrow viewport
- **THEN** the iframe remains inside the visible viewport
- **AND** the iframe does not overlap outside the viewport bounds
- **AND** the user can still interact with the game module content

#### Scenario: Detail layout no longer reserves inline frame space
- **WHEN** the session phase changes to `in_progress`
- **THEN** the activation panel does not reserve the previous fixed-height inline frame area
- **AND** the old in-panel frame margin and border treatment are not required for the in-progress game surface

#### Scenario: Embedded module is not inset by shell spacing
- **WHEN** the module overlay is visible
- **THEN** the shell frame container does not add padding around the iframe
- **AND** the embedded module is presented without extra spacing from the host page

### Requirement: Module frame contracts are preserved
The system SHALL preserve the existing module iframe and session connection contracts while changing only the frame placement.

#### Scenario: Module props are unchanged
- **WHEN** the game page renders the in-progress module frame
- **THEN** the existing module `embedUrl`, `allowedOrigins`, and `sandbox` values are passed to the iframe behavior unchanged
- **AND** the existing connection bootstrap data is passed unchanged

#### Scenario: Session ownership remains in SessionPanel
- **WHEN** the game page has a session with module connection data
- **THEN** `SessionPanel` remains the owner of realtime session state
- **AND** the page does not add a second session-state owner for deciding overlay visibility

#### Scenario: Waiting session still renders activation controls
- **WHEN** the session phase is `waiting_for_players`
- **THEN** the page renders the existing waiting-session start controls and joined-player area
- **AND** the fixed module overlay is not visible
