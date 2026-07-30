## ADDED Requirements

### Requirement: Embedded game overlay controls use a reduced proportional footprint

The shell SHALL render every embedded-game display control as a border-box `2rem` square surface, exactly 80% of the current `2.5rem` inline and block dimensions. The shell SHALL use `0.4rem` control padding, SHALL keep the `1px` border crisp, and SHALL let the unchanged SVG fill the resulting `calc(1.2rem - 2px)` content box.

#### Scenario: Desktop player shows reduced controls

- **WHEN** an embedded game player is visible in Theater or Compact mode on a desktop viewport
- **THEN** every shell-owned display control has computed inline and block dimensions of `2rem`
- **AND** those dimensions use `border-box` sizing
- **AND** every control has computed padding of `0.4rem`
- **AND** its SVG fills the resulting `calc(1.2rem - 2px)` content box without clipping

#### Scenario: Mobile player keeps the proportional reduction

- **WHEN** an embedded game player is visible at or below the existing `34rem` narrow-viewport breakpoint
- **THEN** every shell-owned display control retains the `2rem` square surface and `0.4rem` padding
- **AND** no mobile rule restores the former `2.5rem` control or `0.5rem` padding

### Requirement: The complete control group scales with its controls

The shell SHALL reduce the gap between adjacent display controls from `0.375rem` to `0.3rem` and SHALL reduce the group's logical block-start and inline-end offsets from `0.5rem` to `0.4rem`. A visible two-control group SHALL therefore occupy `4.3rem` in the inline axis, exactly 80% of its former `5.375rem` width, while retaining its top-end placement over the player.

#### Scenario: Two controls are visible

- **WHEN** Theater or Compact mode exposes a mode action and a fullscreen action together
- **THEN** the two `2rem` controls are separated by a `0.3rem` gap
- **AND** the visible group occupies `4.3rem` in the inline axis
- **AND** the group is offset `0.4rem` from the player's logical block-start and inline-end edges

#### Scenario: Fullscreen exposes one control

- **WHEN** browser fullscreen hides the mode action and exposes only Exit fullscreen
- **THEN** the visible group occupies one `2rem` control surface
- **AND** it retains the same `0.4rem` logical edge offsets used outside fullscreen

#### Scenario: Narrow viewport preserves reduced group geometry

- **WHEN** the two-control group is rendered on a viewport at or below `34rem`
- **THEN** its control sizes, padding, gap, and logical offsets remain the same reduced values
- **AND** the group covers no more game content than the corresponding desktop control group

### Requirement: Reduced controls preserve display behavior and accessibility

The shell MUST apply the reduced geometry without changing the semantic buttons, accessible names, keyboard operation, visible focus, pointer states, display-mode transitions, fullscreen synchronization, safe-area behavior, or iframe and SDK bridge continuity defined by the embedded game player.

#### Scenario: Player changes display mode with reduced controls

- **WHEN** a user activates Compact game view or Theater game view by pointer or keyboard
- **THEN** the existing display transition completes
- **AND** the same iframe DOM node and SDK bridge remain mounted
- **AND** the activated control uses the reduced geometry

#### Scenario: Player enters or exits fullscreen with reduced controls

- **WHEN** a user activates Enter fullscreen or Exit fullscreen
- **THEN** the existing Fullscreen API behavior and state synchronization remain unchanged
- **AND** the visible fullscreen control uses the same reduced geometry as the mode controls

#### Scenario: Assistive technology reaches reduced controls

- **WHEN** assistive technology or keyboard focus reaches a display control
- **THEN** the native button retains an accessible action name and keyboard activation
- **AND** its decorative SVG remains hidden from assistive technology
- **AND** visible focus is not reduced below the existing `2px` outline

#### Scenario: Visual control states remain distinguishable

- **WHEN** a reduced control is hovered, focused, or disabled
- **THEN** its existing background, outline, cursor, and opacity state remains perceivable
- **AND** its `1px` border and SVG stroke width are not scaled down
