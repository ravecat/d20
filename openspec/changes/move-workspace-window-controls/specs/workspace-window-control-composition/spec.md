## ADDED Requirements

### Requirement: Workspace derives one expanded session identifier

The shell SHALL derive one optional expanded session identifier from the authoritative workspace sessions and browser-local layout, and each rendered window MUST derive its expanded class by comparing its session identifier with that value.

#### Scenario: Auto layout selects the first session

- **WHEN** the workspace layout is Auto and one or more sessions are present
- **THEN** `expandedId` identifies the first authoritative session
- **AND** only that session window receives the expanded class

#### Scenario: Focused layout retains an available session

- **WHEN** the focused session remains in the authoritative collection
- **THEN** `expandedId` identifies that focused session
- **AND** only that session window receives the expanded class

#### Scenario: Missing focused session falls back

- **WHEN** the focused session is absent from the authoritative collection
- **THEN** `expandedId` identifies the first remaining session
- **AND** the fallback window receives the expanded class

#### Scenario: Compact layout expands no session

- **WHEN** the workspace layout is Compact
- **THEN** `expandedId` is absent
- **AND** no session window receives the expanded class

### Requirement: Workspace owns complete window-control composition

`Workspace` SHALL render Close, the applicable Compact or Expand action, and fullscreen in one named control block supplied through the required dialog children snippet.

#### Scenario: Workspace renders normal window controls

- **WHEN** a workspace session window renders outside browser fullscreen
- **THEN** one named block contains Close first, the applicable Compact or Expand action second, and Enter fullscreen last
- **AND** every accessible name identifies that rendered session and describes the action result
- **AND** activating Close forwards the existing workspace close operation for that session
- **AND** activating Compact or Expand updates only browser-local workspace layout
- **AND** activating Enter fullscreen invokes the dialog-provided fullscreen action
- **AND** the session remains visible until an authoritative snapshot removes it

#### Scenario: Workspace renders fullscreen window controls

- **WHEN** the dialog surface enters browser fullscreen
- **THEN** the same named block contains Close first and Exit fullscreen last
- **AND** Compact or Expand is absent until browser fullscreen ends
- **AND** activating Exit fullscreen invokes the dialog-provided fullscreen action without changing the underlying workspace layout

### Requirement: Dialog exposes fullscreen capability through children

`Dialog` SHALL provide its synchronized fullscreen state and fullscreen toggle action to the required children snippet while retaining ownership of the fullscreen surface reference and Fullscreen API implementation.

#### Scenario: Browser fullscreen state changes

- **WHEN** the dialog surface enters or exits browser fullscreen through a button, Escape, or another supported browser action
- **THEN** the children snippet receives the current fullscreen boolean
- **AND** the workspace control block updates its fullscreen accessible name and icon
- **AND** the dialog surface remains the Fullscreen API target

### Requirement: Unified controls preserve interaction and presentation

The workspace-owned control block MUST preserve native button semantics, decorative icon hiding, result-oriented accessible names, visible focus, existing pointer and disabled states, `2rem` button geometry, `0.4rem` padding, `0.3rem` inter-control gap, and `0.4rem` logical top-end offsets.

#### Scenario: Player uses unified controls

- **WHEN** the player closes, compacts, expands, enters fullscreen, or exits fullscreen through the unified block
- **THEN** the existing action behavior remains unchanged
- **AND** layout and fullscreen transitions preserve the mounted iframe node and SDK bridge
