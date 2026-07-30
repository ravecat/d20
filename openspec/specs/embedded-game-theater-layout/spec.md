# embedded-game-theater-layout Specification

## Purpose
TBD - created by archiving change maximize-theater-game-view. Update Purpose after archive.
## Requirements
### Requirement: Theater mode fills the safe dynamic viewport

The shell SHALL size the Theater dialog from all four edges of the current dynamic viewport, SHALL keep at least `0.5rem` of outer separation at each edge, and SHALL increase an edge's separation when the corresponding safe-area inset is larger. The shell SHALL NOT impose an additional desktop maximum inline size, maximum block size, or aspect ratio on the Theater dialog.

#### Scenario: Desktop Theater uses the available canvas

- **WHEN** Theater mode is active on a viewport wider than `34rem`
- **THEN** the dialog fills the rectangle remaining between the four minimum edge separations
- **AND** the former `72rem` inline-size and `42rem` block-size caps do not limit the dialog

#### Scenario: Narrow Theater uses the same layout contract

- **WHEN** Theater mode is active on a viewport at or below `34rem`
- **THEN** the dialog fills the rectangle remaining between the four minimum edge separations
- **AND** no narrow-viewport rule changes the Theater sizing contract

#### Scenario: Theater respects a larger safe area

- **WHEN** a viewport reports a safe-area inset larger than `0.5rem` for any edge
- **THEN** the dialog remains outside that unsafe region on the corresponding edge
- **AND** the other edges retain their own independently resolved minimum separations

#### Scenario: Dynamic viewport dimensions change

- **WHEN** browser chrome, orientation, window size, or another viewport condition changes the dynamic viewport dimensions while Theater mode is active
- **THEN** the dialog recomputes its available rectangle from the new dynamic viewport
- **AND** it remains within the safe viewport bounds

### Requirement: Theater layout is independent of game format

The shell SHALL expose the complete Theater dialog content box to the embedded game player without deriving the dialog dimensions from game content and without imposing a game-specific aspect ratio. The embedded game SHALL remain responsible for arranging its own portrait, landscape, square, or responsive content within that surface.

#### Scenario: Portrait game opens in Theater mode

- **WHEN** a portrait-oriented embedded game is presented in Theater mode
- **THEN** the shell provides the complete viewport-filling player surface
- **AND** the shell does not narrow the dialog to the game's intrinsic or preferred width

#### Scenario: Landscape game opens in Theater mode

- **WHEN** a landscape-oriented embedded game is presented in Theater mode
- **THEN** the shell provides the same viewport-filling player surface contract
- **AND** the shell does not reduce the dialog to a predefined landscape maximum

#### Scenario: Embedded game fills the player wrapper

- **WHEN** any embedded game is mounted in Theater mode
- **THEN** the shell-owned player wrapper occupies the complete dialog content box in both axes
- **AND** the game can use or internally letterbox that available surface without changing the dialog geometry

### Requirement: Maximized Theater preserves existing presentation behavior

The shell MUST apply the viewport-filling Theater layout without changing Compact mode geometry, native fullscreen behavior, display controls, modal and close-request behavior, iframe identity, SDK bridge lifetime, or iframe module inputs.

#### Scenario: User transitions between maximized Theater and Compact

- **WHEN** a user changes from Theater mode to Compact mode and back to Theater mode
- **THEN** each mode uses its existing interaction semantics
- **AND** the same iframe DOM node and SDK bridge remain mounted
- **AND** returning to Theater restores the viewport-filling layout

#### Scenario: User enters fullscreen from maximized Theater

- **WHEN** a user requests native fullscreen from Theater mode
- **THEN** the existing Fullscreen API behavior remains unchanged
- **AND** exiting fullscreen returns the player to the viewport-filling Theater layout

#### Scenario: Compact mode remains bounded

- **WHEN** Compact mode is active on a desktop or narrow viewport
- **THEN** its existing bounded bottom-end geometry remains unchanged
- **AND** only Theater mode uses the viewport-filling layout
