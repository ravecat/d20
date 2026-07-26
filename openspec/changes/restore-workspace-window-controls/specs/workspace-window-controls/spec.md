## ADDED Requirements

### Requirement: Workspace windows expose mode-appropriate controls

The shell SHALL expose Close and fullscreen actions for every mounted workspace window, SHALL expose exactly one applicable Theater or Compact mode action outside browser fullscreen, and SHALL use the existing browser-local workspace transition without closing or remounting the game.

#### Scenario: Theater window exposes Compact

- **WHEN** a workspace window is in Theater mode outside browser fullscreen
- **THEN** its controls are Close, Compact, and Enter fullscreen
- **AND** activating Compact changes the same workspace entry to Compact mode
- **AND** the iframe DOM node and SDK bridge remain mounted

#### Scenario: Compact window exposes Expand

- **WHEN** a workspace window is in Compact mode outside browser fullscreen
- **THEN** its controls are Close, Expand, and Enter fullscreen
- **AND** activating Expand changes the same workspace entry to Theater mode
- **AND** the iframe DOM node and SDK bridge remain mounted

#### Scenario: Browser fullscreen preserves the underlying workspace mode

- **WHEN** a Theater or Compact workspace window is browser fullscreen
- **THEN** its controls are Close and Exit fullscreen
- **AND** no Compact or Expand action is exposed until browser fullscreen ends
- **AND** exiting fullscreen restores the action applicable to the preserved workspace mode

### Requirement: Workspace window controls use one semantic vertical order

The shell SHALL render the workspace window controls as one named vertical group and MUST keep DOM, keyboard, and visual order aligned as Close first, the applicable mode action second when present, and the fullscreen action last.

#### Scenario: Theater control order

- **WHEN** a workspace window is in Theater mode outside browser fullscreen
- **THEN** the named control group is arranged in one vertical column
- **AND** Close is first
- **AND** Compact is second
- **AND** Enter fullscreen is last

#### Scenario: Compact control order

- **WHEN** a workspace window is in Compact mode outside browser fullscreen
- **THEN** the named control group is arranged in one vertical column
- **AND** Close is first
- **AND** Expand is second
- **AND** Enter fullscreen is last

#### Scenario: Fullscreen control order

- **WHEN** a workspace window is browser fullscreen
- **THEN** the named control group is arranged in one vertical column
- **AND** Close is first
- **AND** Exit fullscreen is last

### Requirement: Reorganized controls preserve accessibility and geometry

The shell MUST retain native button semantics, result-oriented accessible names, decorative icon hiding, visible focus, current pointer and disabled states, `2rem` button geometry, `0.3rem` inter-control gap, and `0.4rem` logical top-end offsets while reorganizing the controls.

#### Scenario: Keyboard user traverses the control group

- **WHEN** a keyboard user navigates a workspace window's enabled controls
- **THEN** focus follows the same Close, mode action, fullscreen action order that is presented visually
- **AND** every focused control has a visible focus indicator
- **AND** every action can be activated from the keyboard

#### Scenario: Assistive technology identifies the controls

- **WHEN** assistive technology reaches a workspace window's controls
- **THEN** the control group identifies the associated game window
- **AND** every button has an accessible name that describes its result
- **AND** every decorative SVG is hidden from assistive technology

#### Scenario: Existing overlay footprint is retained

- **WHEN** the reorganized controls render in Theater, Compact, or browser fullscreen
- **THEN** every control retains its existing `2rem` border-box dimensions and `0.4rem` padding
- **AND** adjacent controls retain a `0.3rem` gap
- **AND** the group retains its `0.4rem` logical block-start and inline-end offsets

### Requirement: Active sessions are represented without a duplicate workspace panel

The shell SHALL represent every active session through its mounted game window and SHALL NOT render a separate workspace dock, session-summary strip, or other passive panel that duplicates the active windows.

#### Scenario: Workspace has active sessions

- **WHEN** one or more active sessions are discovered
- **THEN** every active session has its mounted game window
- **AND** no separate Workspace sessions region or duplicate session-summary strip is rendered
- **AND** the window controls remain the available interface for changing or closing each window

#### Scenario: Multiple active sessions remain reachable

- **WHEN** multiple active sessions are mounted in Compact or Theater modes
- **THEN** removing the duplicate panel does not unmount or hide any active game window
- **AND** each window retains its existing accessible name and mode-appropriate controls

#### Scenario: Workspace layout no longer reserves dock space

- **WHEN** active game windows are positioned at the workspace block-end edge
- **THEN** the layout retains its safe-area edge offset
- **AND** it does not reserve additional block-end space for a removed workspace dock

### Requirement: Compact previews use a bounded lower-right footprint

The shell SHALL anchor the Compact preview region at the viewport's logical block-end and inline-end edges and, on viewports wider than `48rem`, SHALL target an inline size of `50vw` and a block size of `25dvh`. This target footprint is approximately one eighth of the viewport area and MUST replace the nearly full-width bottom strip.

#### Scenario: Compact preview on a wide viewport

- **WHEN** a workspace window is in Compact mode and the viewport is wider than `48rem`
- **THEN** the Compact preview region is anchored at the lower-right safe-area edge
- **AND** its target dimensions are `50vw` by `25dvh`
- **AND** its block size MAY grow to the minimum required to keep the vertical control stack reachable on an unusually short viewport
- **AND** it occupies approximately one eighth of the viewport area
- **AND** it does not stretch across the full viewport width

#### Scenario: Compact preview leaves the page visible

- **WHEN** a Compact preview is displayed on a wide viewport
- **THEN** the underlying page remains visible above and to the inline-start side of the preview
- **AND** the preview does not create a full-width overlay along the viewport block-end edge

#### Scenario: Multiple Compact windows remain bounded

- **WHEN** multiple workspace windows are in Compact mode
- **THEN** they remain contained within the same lower-right Compact preview region
- **AND** the region does not expand beyond its viewport footprint to expose additional windows
- **AND** existing overflow behavior keeps every Compact window reachable

#### Scenario: Narrow viewport preserves usability

- **WHEN** the viewport is `48rem` wide or narrower
- **THEN** the Compact preview MAY use more than half of the viewport inline size
- **AND** it remains aligned to the logical block-end and inline-end safe-area edges
- **AND** game content and all window controls remain reachable without horizontal viewport overflow
