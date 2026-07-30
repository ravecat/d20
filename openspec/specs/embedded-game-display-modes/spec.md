# embedded-game-display-modes Specification

## Purpose

Define Compact, Theater, and browser-fullscreen presentation without changing embedded-game runtime identity.

## Requirements

### Requirement: Eligible sessions mount independently of presentation

The shell SHALL mount one embedded game player for each discoverable in-progress or finished session and SHALL derive Compact or Theater presentation from browser-local workspace layout.

#### Scenario: Session mounts in Compact

- **WHEN** a newly mounted workspace discovers an eligible session without an explicit focus selection
- **THEN** the session is presented as a Compact status bar
- **AND** its embedded game frame remains mounted

#### Scenario: Session is focused

- **WHEN** the player activates a Compact restore surface
- **THEN** that session is presented in Theater mode
- **AND** every other eligible session remains Compact

#### Scenario: Session is ineligible

- **WHEN** a session is no longer discoverable by the workspace
- **THEN** its embedded player is removed with its authoritative workspace entry

### Requirement: Theater transitions to Compact explicitly

The shell SHALL expose a native Compact action in Theater mode and SHALL change only browser-local workspace layout when that action is activated.

#### Scenario: Player compacts Theater

- **WHEN** Theater mode is active outside browser fullscreen and the player activates Compact
- **THEN** every session is presented in Compact mode
- **AND** the focused game is not closed or remounted

#### Scenario: Embedded game owns keyboard input

- **WHEN** keyboard input is handled inside the embedded game document
- **THEN** the parent workspace does not depend on an Escape handler to compact Theater
- **AND** the explicit Compact action remains keyboard reachable

### Requirement: Compact mode preserves runtime without exposing game interaction

The shell SHALL present Compact sessions as viewport-bounded status bars while keeping their embedded game frames mounted, hidden, inert, and unavailable to assistive technology outside browser fullscreen.

#### Scenario: Compact session coexists with the page

- **WHEN** Compact mode is active
- **THEN** the underlying page remains interactive
- **AND** the Compact status bar remains within the dynamic viewport and safe-area offsets

#### Scenario: Compact session enters fullscreen

- **WHEN** the player activates Enter fullscreen from a Compact status bar
- **THEN** the same embedded game becomes visible and interactive in browser fullscreen
- **AND** exiting fullscreen returns the session to its Compact status bar

### Requirement: Browser fullscreen is progressive enhancement

The shell SHALL offer browser-native fullscreen for the complete game surface, SHALL handle request failure at the boundary, and SHALL treat browser fullscreen state as authoritative.

#### Scenario: User enters native fullscreen

- **WHEN** the Fullscreen API is available and the user activates Enter fullscreen
- **THEN** the shell requests fullscreen on the surface containing the iframe and controls
- **AND** the action becomes Exit fullscreen after success

#### Scenario: Browser exits fullscreen independently

- **WHEN** the browser exits fullscreen through browser or system UI
- **THEN** the shell synchronizes from `fullscreenchange`
- **AND** Enter fullscreen becomes available again
- **AND** browser-local workspace layout remains unchanged

#### Scenario: Fullscreen request is unavailable or fails

- **WHEN** the browser cannot complete a fullscreen request
- **THEN** the window remains in its existing workspace presentation
- **AND** the shell does not present an application error

### Requirement: Presentation transitions preserve iframe and bridge continuity

The shell MUST preserve the same iframe DOM node and D20 SDK bridge while changing between Compact, Theater, and browser-fullscreen presentation.

#### Scenario: Workspace presentation changes

- **WHEN** the player compacts, restores, enters fullscreen, or exits fullscreen
- **THEN** the iframe DOM node remains the same node
- **AND** its document is not reloaded solely because of the presentation transition
- **AND** the SDK bridge is not initialized again solely because of the transition

#### Scenario: Module bootstrap remains stable

- **WHEN** the shell mounts the embedded game player
- **THEN** it passes configured embed, origin, sandbox, endpoint, topic, and token values unchanged

### Requirement: Display actions are accessible and responsive

The shell SHALL expose semantic, keyboard-operable actions with result-oriented accessible names and SHALL keep them usable across supported desktop and narrow dynamic viewports.

#### Scenario: Assistive technology identifies actions

- **WHEN** an embedded game player is mounted
- **THEN** its dialog and named control group identify the session
- **AND** every enabled action has an accessible name describing its result
- **AND** decorative icons are hidden from assistive technology

#### Scenario: Keyboard user changes presentation

- **WHEN** a keyboard user navigates shell-owned window actions
- **THEN** every enabled action can receive visible focus
- **AND** Enter or Space activates the focused native button
