## ADDED Requirements

### Requirement: Eligible sessions open the embedded game in Theater mode
The shell SHALL mount one embedded game player when the realtime session phase is `in_progress` or `finished`, and SHALL present that player in Theater mode by default for each component mount.

#### Scenario: In-progress session opens in Theater mode
- **WHEN** the realtime session phase becomes `in_progress`
- **THEN** the shell mounts the embedded game player once
- **AND** the player opens as a centered modal dialog
- **AND** a backdrop separates the game from the page

#### Scenario: Finished session opens in Theater mode
- **WHEN** the realtime session phase is `finished`
- **THEN** the shell mounts the embedded game player in Theater mode
- **AND** the iframe remains available to render the final session projection and results

#### Scenario: Ineligible session does not mount the game
- **WHEN** the realtime session phase is unavailable or `waiting_for_players`
- **THEN** the embedded game player is not mounted
- **AND** the module iframe is not loaded speculatively

### Requirement: Theater mode transitions to Compact mode without closing the game
The shell SHALL declare native `closedby="any"` light dismiss for Theater mode, SHALL interpret its close requests as transitions to Compact mode, and SHALL keep the embedded game available.

#### Scenario: Backdrop activation selects Compact mode
- **WHEN** the browser supports `closedby="any"`
- **AND** a user activates the backdrop outside the Theater player
- **THEN** the modal Theater presentation ends
- **AND** the same player opens in Compact mode
- **AND** the game is not closed or unmounted

#### Scenario: Escape selects Compact mode
- **WHEN** Theater mode is active outside browser fullscreen
- **AND** the host dialog receives an Escape or platform close request
- **THEN** the same player opens in Compact mode
- **AND** the game is not closed or unmounted

#### Scenario: Compact control selects Compact mode
- **WHEN** Theater mode is active and the user activates the Compact game view control
- **THEN** the same player opens in Compact mode
- **AND** the game is not closed or unmounted

#### Scenario: Browser owns Theater backdrop hit testing
- **WHEN** Theater mode is active
- **THEN** the modal dialog declares `closedby="any"`
- **AND** the shell does not classify pointer coordinates itself
- **AND** the shell prevents the resulting close request from closing or unmounting the game

#### Scenario: Native backdrop light dismiss is unsupported
- **WHEN** the browser does not support `closedby`
- **THEN** the Compact game view control remains available
- **AND** an Escape close request still transitions Theater mode to Compact mode

### Requirement: Compact mode is a non-modal corner player
The shell SHALL present Compact mode as a bounded, non-modal player anchored to the viewport's bottom-end corner so the game and the underlying page remain interactive.

#### Scenario: Compact mode does not block the page
- **WHEN** Compact mode is active
- **THEN** the player has no modal backdrop
- **AND** the user can interact with the underlying game detail page

#### Scenario: Compact mode restores Theater mode
- **WHEN** Compact mode is active and the user activates the Theater game view control
- **THEN** the same player opens as a centered modal dialog
- **AND** the modal backdrop is restored

#### Scenario: Compact mode respects viewport boundaries
- **WHEN** Compact mode is active on a desktop or narrow viewport
- **THEN** the player remains fully within the visible dynamic viewport
- **AND** its bottom-end offset respects available safe-area insets

### Requirement: The player supports native fullscreen as progressive enhancement
The shell SHALL offer a browser-native fullscreen action for the complete embedded game player, SHALL handle failure at the request boundary, and SHALL treat browser fullscreen state as authoritative.

#### Scenario: User enters native fullscreen
- **WHEN** the Fullscreen API is available and the user activates Enter fullscreen
- **THEN** the shell requests fullscreen on the player element that contains the iframe and its controls
- **AND** `document.fullscreenElement` identifies that player after a successful request
- **AND** the control is exposed as Exit fullscreen

#### Scenario: User exits native fullscreen from the control
- **WHEN** the embedded game player is fullscreen and the user activates Exit fullscreen
- **THEN** the shell requests exit from browser fullscreen
- **AND** the player returns to the Theater or Compact mode that was active before fullscreen

#### Scenario: Browser exits fullscreen independently
- **WHEN** the browser exits fullscreen through Escape, browser UI, or system UI
- **THEN** the shell synchronizes its control state from the `fullscreenchange` event
- **AND** Enter fullscreen becomes available again
- **AND** the prior Theater or Compact mode remains active

#### Scenario: Dialog close request does not change a fullscreen player's mode
- **WHEN** the host dialog receives a close request while its player is browser fullscreen
- **THEN** the shell prevents the dialog from closing
- **AND** the stored Theater or Compact mode remains unchanged

#### Scenario: Fullscreen is unavailable
- **WHEN** the user activates Enter fullscreen and the browser cannot perform the fullscreen request
- **THEN** the player remains in its current Theater or Compact mode
- **AND** the shell does not present an application error

#### Scenario: Fullscreen request fails
- **WHEN** the browser rejects a fullscreen request
- **THEN** the player remains in its current Theater or Compact mode
- **AND** the shell does not present an application error

### Requirement: Display transitions preserve iframe and bridge continuity
The shell MUST preserve the same iframe DOM node and D20 SDK bridge while changing between Theater, Compact, and fullscreen presentation.

#### Scenario: Theater and Compact transitions preserve the iframe
- **WHEN** the user changes from Theater to Compact and back to Theater
- **THEN** the iframe DOM node remains the same node
- **AND** its document is not reloaded solely because of the display transition
- **AND** the SDK bridge is not initialized again solely because of the display transition

#### Scenario: Fullscreen transitions preserve the iframe
- **WHEN** the user enters and exits fullscreen
- **THEN** the iframe DOM node remains the same node
- **AND** its document is not reloaded solely because of the fullscreen transition
- **AND** the SDK bridge is not initialized again solely because of the fullscreen transition

#### Scenario: Existing module contracts are preserved
- **WHEN** the shell mounts the embedded game player
- **THEN** it passes the configured `embedUrl`, `allowedOrigins`, and `sandbox` values unchanged
- **AND** it passes the existing connection endpoint, topic, and token bootstrap values unchanged

### Requirement: Display controls are accessible and responsive
The shell SHALL expose semantic, keyboard-operable controls and accessible names for the player and every display action, and SHALL keep the player usable within desktop and narrow dynamic viewports.

#### Scenario: Assistive technology identifies the player and controls
- **WHEN** the embedded game player is mounted
- **THEN** the dialog's accessible name identifies the module
- **AND** every mode and fullscreen action is a button with an accessible name describing its result
- **AND** decorative control icons are hidden from assistive technology

#### Scenario: Keyboard user changes presentation
- **WHEN** a keyboard user navigates the shell-owned player controls
- **THEN** each enabled control can receive visible focus and be activated from the keyboard
- **AND** an Escape close request transitions Theater to Compact without unmounting the game

#### Scenario: Theater mode fits a narrow viewport
- **WHEN** Theater mode is active on a narrow viewport
- **THEN** the player occupies nearly all available dynamic viewport space
- **AND** it remains within the visible viewport bounds
