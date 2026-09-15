# workspace-window-controls Specification

## Purpose

Define the shell-owned actions, ordering, accessibility, and runtime continuity of workspace window controls.

## Requirements

### Requirement: Workspace windows expose presentation-appropriate actions

The shell SHALL expose Close and fullscreen actions for every mounted workspace window, SHALL expose a Compact action for the Theater window outside browser fullscreen, and SHALL expose a separate native restore surface for each Compact session without closing or remounting its game.

#### Scenario: Theater window exposes Compact

- **WHEN** a workspace window is in Theater mode outside browser fullscreen
- **THEN** its named control group contains Close, Enter fullscreen, and Compact
- **AND** activating Compact changes the workspace layout to Compact
- **AND** the iframe DOM node and SDK bridge remain mounted

#### Scenario: Compact window exposes a restore surface

- **WHEN** a workspace window is Compact outside browser fullscreen
- **THEN** its named control group contains Close and Enter fullscreen
- **AND** a separate native surface exposes the accessible action `Expand`
- **AND** activating that surface focuses the same session in Theater mode
- **AND** the iframe DOM node and SDK bridge remain mounted

#### Scenario: Browser fullscreen preserves workspace layout

- **WHEN** a Theater or Compact workspace window enters browser fullscreen
- **THEN** its named control group contains Close and Exit fullscreen
- **AND** no Compact action or Compact restore surface is exposed until browser fullscreen ends
- **AND** exiting fullscreen restores the presentation implied by the unchanged workspace layout

### Requirement: Window controls keep stable semantic source order

The named window-control group MUST render Close first and fullscreen second in the DOM. Theater SHALL render Compact last in that group. CSS MAY arrange the controls independently from sequential keyboard order.

#### Scenario: Theater control order

- **WHEN** a workspace window is in Theater mode outside browser fullscreen
- **THEN** the named group is visually arranged as Close, Compact, Enter fullscreen
- **AND** its DOM and sequential keyboard order is Close, Enter fullscreen, Compact

#### Scenario: Compact action order

- **WHEN** a workspace window is Compact outside browser fullscreen
- **THEN** sequential keyboard order reaches the restore surface, Close, and Enter fullscreen
- **AND** the named control group is visually arranged as Enter fullscreen, Close

#### Scenario: Fullscreen control order

- **WHEN** a workspace window is browser fullscreen
- **THEN** the named group is visually arranged as Close, Exit fullscreen
- **AND** its DOM and sequential keyboard order is Close, Exit fullscreen

### Requirement: Window controls preserve accessibility and shared geometry

The shell MUST retain native button semantics, result-oriented accessible names, decorative icon hiding, visible focus, pointer and disabled states, shared fluid square control and icon geometry, bounded internal button padding, a `0.3rem` inter-control gap, and the Theater group's `0.4rem` logical top-end offsets.

#### Scenario: Keyboard user traverses actions

- **WHEN** a keyboard user navigates a workspace window
- **THEN** every enabled restore or window-control action can receive visible focus
- **AND** Enter or Space activates only the focused native button
- **AND** sequential keyboard order MAY differ from CSS visual order

#### Scenario: Assistive technology identifies controls

- **WHEN** assistive technology reaches a workspace window
- **THEN** the named control group identifies the associated session
- **AND** every button has an accessible name describing its result
- **AND** every decorative SVG is hidden from assistive technology

#### Scenario: Shared control geometry is rendered

- **WHEN** controls render in Compact, Theater, or browser fullscreen
- **THEN** every control uses `clamp(1.25rem, 0.9375rem + 1.25vw, 1.875rem)` for both dimensions
- **AND** every control SVG uses `clamp(0.75rem, 0.65625rem + 0.375vw, 0.9375rem)` for both dimensions
- **AND** every control uses `clamp(0.125rem, 0.0625rem + 0.25vw, 0.25rem)` for internal padding
- **AND** adjacent controls retain a `0.3rem` gap

#### Scenario: Narrow viewport reaches the lower bounds

- **WHEN** the viewport is 400px wide or narrower with a 16px root font size
- **THEN** controls are 20px squares, icons are 12px squares, and button padding is 2px
- **AND** control contents and visible focus remain unclipped

#### Scenario: Intermediate viewport interpolates independently

- **WHEN** the viewport is 800px wide with a 16px root font size
- **THEN** controls are 25px squares, icons are 13.5px squares, and button padding is 3px
- **AND** viewport resizing updates all dimensions continuously within their bounds

#### Scenario: Wide viewport retains existing maximum dimensions

- **WHEN** the viewport is 1200px wide or wider with a 16px root font size
- **THEN** controls are 30px squares, icons are 15px squares, and button padding is 4px
- **AND** increasing viewport width does not enlarge them further

### Requirement: Active sessions have no duplicate workspace panel

The shell SHALL represent every active session through its mounted game window and SHALL NOT render a separate dock, session-summary strip, or other passive panel that duplicates those windows.

#### Scenario: Workspace has active sessions

- **WHEN** one or more active sessions are discovered
- **THEN** every active session has a mounted game window
- **AND** no duplicate session-summary panel is rendered
- **AND** the window actions remain available for restoring, compacting, fullscreening, or closing a session

#### Scenario: Workspace layout uses only safe-area reservation

- **WHEN** active game windows are positioned at the workspace block-end edge
- **THEN** the layout retains its safe-area offset
- **AND** it reserves no additional space for a removed workspace dock
