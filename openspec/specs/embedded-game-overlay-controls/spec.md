# embedded-game-overlay-controls Specification

## Purpose

Define the compact, consistent geometry and accessibility of shell-owned embedded-game controls.

## Requirements

### Requirement: Embedded game controls use shared compact geometry

The shell SHALL render every workspace window control as a `1.875rem` square with a `0.9375rem` square SVG icon in Compact, Theater, and browser fullscreen.

#### Scenario: Controls render in any presentation

- **WHEN** a workspace window renders its enabled controls
- **THEN** every control has computed inline and block dimensions of `1.875rem`
- **AND** every control SVG has computed inline and block dimensions of `0.9375rem`
- **AND** the icon remains centered without clipping

### Requirement: Control groups retain stable spacing

The shell SHALL use a `0.3rem` gap between adjacent controls and SHALL retain `0.4rem` logical top-end offsets for the absolutely positioned Theater and fullscreen group.

#### Scenario: Theater controls overlay the game

- **WHEN** Theater or browser fullscreen presents its named control group
- **THEN** adjacent controls are separated by `0.3rem`
- **AND** the group remains at the `0.4rem` logical block-start and inline-end offsets

#### Scenario: Compact controls participate in the status row

- **WHEN** a session is Compact
- **THEN** its named control group uses the same control geometry and gap
- **AND** it participates in the Compact chrome flow instead of using overlay positioning

### Requirement: Compact controls preserve behavior and accessibility

The shell MUST apply the shared geometry without changing semantic buttons, accessible names, keyboard operation, visible focus, pointer states, workspace presentation transitions, fullscreen synchronization, safe-area behavior, or iframe and SDK bridge continuity.

#### Scenario: User activates a window action

- **WHEN** a user activates an enabled window action by pointer or keyboard
- **THEN** that action retains its defined behavior
- **AND** presentation-only transitions preserve the mounted iframe and SDK bridge
