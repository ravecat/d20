## MODIFIED Requirements

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
