# workspace-window-control-composition Specification

## Purpose

Define Workspace ownership of session layout and window-control composition while Dialog owns only browser-fullscreen mechanics.

## Requirements

### Requirement: Workspace derives one expanded session identifier

The shell SHALL derive one optional expanded session identifier from authoritative workspace sessions and browser-local layout, and each rendered window MUST derive its expanded state by comparing its session identifier with that value.

#### Scenario: Focused layout retains an available session

- **WHEN** the focused session remains in the authoritative collection
- **THEN** the expanded identifier names that session
- **AND** only that session window is presented in Theater mode

#### Scenario: Missing focused session falls back

- **WHEN** the focused session is absent from the authoritative collection
- **THEN** the expanded identifier names the first remaining session
- **AND** only the fallback window is presented in Theater mode

#### Scenario: Compact layout expands no session

- **WHEN** the workspace layout is Compact
- **THEN** the expanded identifier is absent
- **AND** every session window is presented as a Compact status bar

### Requirement: Workspace owns complete window-action composition

`Workspace` SHALL render the Compact restore surface and the named Close, fullscreen, and Theater Compact controls through the required dialog children snippet.

#### Scenario: Workspace renders Compact actions

- **WHEN** a session window is Compact outside browser fullscreen
- **THEN** a separate native restore surface expands that session
- **AND** one named control group contains Close and Enter fullscreen
- **AND** activating any action performs only that action

#### Scenario: Workspace renders Theater actions

- **WHEN** a session window is in Theater mode outside browser fullscreen
- **THEN** one named control group contains Close, Enter fullscreen, and Compact in source order
- **AND** activating Compact updates only browser-local workspace layout

#### Scenario: Workspace renders fullscreen actions

- **WHEN** the dialog surface enters browser fullscreen
- **THEN** the named control group contains Close and Exit fullscreen
- **AND** layout actions are absent until browser fullscreen ends
- **AND** exiting fullscreen does not change the underlying workspace layout

### Requirement: Dialog exposes fullscreen capability through children

`Dialog` SHALL provide its synchronized fullscreen state and fullscreen toggle action to the required children snippet while retaining ownership of the fullscreen surface reference and Fullscreen API implementation.

#### Scenario: Browser fullscreen state changes

- **WHEN** the dialog surface enters or exits browser fullscreen through a button, browser UI, or system UI
- **THEN** the children snippet receives the current fullscreen boolean
- **AND** Workspace updates the fullscreen accessible name and icon
- **AND** the dialog surface remains the Fullscreen API target

### Requirement: Composed actions preserve interaction and runtime continuity

Workspace-owned actions MUST preserve native button semantics, decorative icon hiding, result-oriented accessible names, visible focus, pointer and disabled states, and iframe and SDK bridge continuity.

#### Scenario: Player uses a workspace window action

- **WHEN** the player restores, closes, compacts, enters fullscreen, or exits fullscreen
- **THEN** only the selected action is performed
- **AND** presentation transitions retain the same mounted iframe node and SDK bridge
