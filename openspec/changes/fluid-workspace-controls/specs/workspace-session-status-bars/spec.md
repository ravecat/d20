## MODIFIED Requirements

### Requirement: Compact mode renders a status bar instead of a game preview

Each non-expanded workspace session SHALL render as a centered content-sized compact status bar and SHALL NOT present its embedded game as an interactive preview. Its status badge SHALL have a 1.875rem block size, every workspace window control and its SVG SHALL use the fluid square dimensions and bounded internal padding defined by the workspace-window-controls specification in Compact, Theater, and fullscreen, and Compact chrome SHALL use 0.5rem padding on both axes. The Compact grid row and window MUST derive their block size from their contents instead of imposing a fixed block size.

The Compact status badge, identifier lane, and named window-control group MUST be direct flex children of the Compact chrome. A separate native restore button MUST be their sibling, MUST span the row behind the visible content without wrapping it, and MUST NOT draw a button box around the status and identifier. Its keyboard focus MUST remain visible on the whole Compact chrome. The named window-control group MUST contain only Close and fullscreen in Compact. Theater MUST keep the Close, fullscreen, Layout DOM and sequential keyboard order. CSS SHALL determine mode-specific visual direction and order independently, and sequential keyboard order MAY differ from that visual order.

The Compact dialog surface MUST use the theme content color as its background. Its session identifier MUST use pure white. Its status badge MUST use a pure-white background with theme-content text and one fixed inline size sufficient for Live, Finished, Reconnecting, and Failed. Every supported status MUST remain centered and unclipped within that shared size, and changing status MUST NOT move the identifier lane. Compact controls MUST invert against the surface with a theme base background and theme content foreground. Theater and fullscreen surface and control colors MUST remain unchanged.

#### Scenario: Session becomes compact

- **WHEN** the player compacts an expanded session
- **THEN** the session dialog presents its session identity and visible status text
- **AND** its block size is derived from the 1.875rem contents, equal chrome padding, and dialog border
- **AND** its status badge has a computed block size of 1.875rem while its controls follow the shared fluid geometry
- **AND** its chrome has 0.5rem padding on both axes
- **AND** its status, identifier, and controls are centered on the bar's block axis
- **AND** its status, identifier, and controls participate in one flex row with equal gaps around the flexible identifier lane
- **AND** its controls do not use absolute positioning while Compact
- **AND** the status badge, identifier lane, and named control group share one direct flex hierarchy
- **AND** a separate row-spanning native restore button activates the non-control surface without enclosing the visible status and identifier
- **AND** keyboard focus on the restore button is indicated on the whole Compact chrome rather than by a box around only the status and identifier
- **AND** its named control group visually presents Enter fullscreen first and Close last in horizontal order
- **AND** the row's DOM and sequential keyboard order remains restore surface, Close, and Enter fullscreen
- **AND** every Compact window-control SVG uses the shared fluid square rendered size
- **AND** the surface background uses the theme content color and the session identifier uses pure white
- **AND** the status badge uses a white background, theme-content text, and one fixed inline size shared by every supported status
- **AND** Compact controls invert those colors again for their background and icon

#### Scenario: Compact status changes

- **WHEN** a Compact session changes among Live, Finished, Reconnecting, and Failed
- **THEN** the status text and dot remain centered and unclipped
- **AND** the status badge retains the same inline size
- **AND** the adjacent session identifier retains the same inline start position
- **AND** status and identifier remain centered on the row's block axis

#### Scenario: Session expands again

- **WHEN** the player activates the Compact restore surface
- **THEN** that session becomes the Theater window
- **AND** its named control group visually presents Close first, Compact second, and Enter fullscreen last in top-to-bottom order
- **AND** its DOM and sequential keyboard order remains Close, Enter fullscreen, and Compact
- **AND** its controls use absolute positioning over the Theater game surface
- **AND** the Compact control uses a lower horizontal line as its visible icon
- **AND** its controls each retain the same computed fluid square size used in Compact at that viewport
- **AND** every window-control SVG retains the same fluid square rendered size used in Compact at that viewport

#### Scenario: Compact session enters fullscreen

- **WHEN** the player activates Enter fullscreen from a compact bar
- **THEN** the same mounted game surface becomes visible and interactive in browser fullscreen
- **AND** the fullscreen controls contain Close and Exit fullscreen
- **AND** the fullscreen controls and their SVGs retain the same sizes used in Compact and Theater
- **AND** exiting fullscreen restores the same Compact status bar without changing the saved workspace layout

#### Scenario: Player activates Compact actions from the keyboard

- **WHEN** a player focuses the Compact restore surface or an enabled window control
- **THEN** the focused native button has a visible focus indicator
- **AND** Enter or Space activates only that button's action
- **AND** no custom focus reordering is required to match the CSS visual order

#### Scenario: Compact controls shrink with the viewport

- **WHEN** a Compact session renders at a viewport width of 400px or less with a 16px root font size
- **THEN** its controls are 20px squares and its icons are 12px squares
- **AND** its status badge remains 30px high and its chrome retains 8px padding on both axes
- **AND** the controls remain centered within the content-derived bar without shrinking the status badge or bar height
