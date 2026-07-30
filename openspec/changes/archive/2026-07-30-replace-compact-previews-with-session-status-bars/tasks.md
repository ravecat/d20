## 1. Authoritative Workspace Phase

- [x] 1.1 Add `phase` to backend workspace descriptors and preserve it in complete join and transition snapshots.
- [x] 1.2 Update workspace channel tests for in-progress and finished descriptor phases.
- [x] 1.3 Require the phase union in the frontend workspace descriptor and update model fixtures.

## 2. Compact Session Status Bars

- [x] 2.1 Derive Live, Finished, Reconnecting, and Failed compact labels with workspace transport precedence.
- [x] 2.2 Replace compact preview geometry with a viewport-bounded stack of status bars no taller than 8rem.
- [x] 2.3 Keep each game frame and SDK bridge mounted while making compact game content visually and interactively unavailable.
- [x] 2.4 Render compact Close and Expand controls horizontally while preserving expanded and fullscreen controls.

## 3. Verification

- [x] 3.1 Update focused Svelte component tests for status mapping, compact controls, hidden frame accessibility, and iframe/bridge continuity.
- [x] 3.2 Update browser tests for compact bar geometry, horizontal controls, responsive stacking, viewport reachability, and Theater coexistence.
- [x] 3.3 Run Svelte autofix twice, targeted backend and frontend tests, formatting, linting, type checking, and strict OpenSpec validation.

## 4. Compact Bar Refinement

- [x] 4.1 Set compact grid rows and windows to 4rem, center their contents, and size status badges to match the controls.
- [x] 4.2 Render one stable window-control group vertically when expanded and horizontally when Compact, and reveal the mounted game during Compact fullscreen without changing workspace layout.
- [x] 4.3 Restyle statuses as outlined badges with a reduced-motion-safe Live pulse, warning Reconnecting state, and neutral terminal states.
- [x] 4.4 Add container-relative CSS motion that pans only overflowing session identifiers, pauses for inspection, and respects reduced-motion preferences.
- [x] 4.5 Update component and browser tests, run Svelte autofix twice, and pass formatting, linting, type checking, focused tests, broad tests, and strict OpenSpec validation.
- [x] 4.6 Render Theater controls visually as Close, Compact, Enter fullscreen; normalize control icon geometry with outline-square Expand and lower-line Compact glyphs; and accelerate the Live pulse to 1.2 seconds.
- [x] 4.7 Reduce control icons to 0.75rem and matching controls and status badges to 1.5rem, update browser geometry coverage, and verify the result in the active browser tab.
- [x] 4.8 Inline one Close, fullscreen, Layout DOM sequence; use CSS direction and order for Compact and Theater visual arrangements; and keep Compact controls in the status-row flow with equal gaps while Theater and fullscreen controls remain absolute.
- [x] 4.9 Present compact status labels in uppercase without duplicating their state mapping.
- [x] 4.10 Increase the session-identifier oscillation speed by 20%, assert the computed duration in the browser test, and verify the motion in the active browser tab.
- [x] 4.11 Halve the stacked compact-window gap to 0.375rem, remove compact dialog shadows without changing Theater elevation, and cover both computed styles in the browser test.
- [x] 4.12 Render Expand with the shared stroked outline-square geometry, remove the unused solid-icon modifier, and verify the result with focused checks and in the active browser tab.

## 5. Default Compact Mounting

- [x] 5.1 Initialize each browser-local workspace layout in Compact while preserving explicit focus and focused-session fallback behavior.
- [x] 5.2 Update focused model, component, and browser tests for initial snapshots, replacement snapshots, explicit Expand, and remount isolation.
- [x] 5.3 Verify in a browser that Compact mounting and manual compaction produce one stable status bar, with continuous motion limited to the specified Live indicator and overflowing identifier.
- [x] 5.4 Run targeted frontend tests, formatting, linting, type checking, broad frontend tests, and strict OpenSpec validation.

## 6. Transport-aware Status Indicator

- [x] 6.1 Make the compact status dot pulse green for Live, pulse yellow more quickly for Reconnecting, remain statically red for Failed, and remain statically neutral for Finished.
- [x] 6.2 Extend focused browser coverage for status-dot color, animation cadence, and terminal-state stability.
- [x] 6.3 Run Svelte autofix twice, focused frontend checks, formatting, type checking, and strict OpenSpec validation.
- [x] 6.4 Keep overflowing identifier motion running while compact controls hold focus, preserve the direct-hover pause, and verify both states in the browser.

## 7. Workspace Session Discovery Boundary

- [x] 7.1 Rename `D20Web.Workspace.snapshot/1` to `sessions/1`, return descriptors with a runtime PID set, and let `D20Web.WorkspaceChannel` construct the public snapshot envelope.
- [x] 7.2 Update focused channel coverage and pass backend formatting, targeted tests, and strict OpenSpec validation.

## 8. Keyboard Order Contract

- [x] 8.1 Reconcile the legacy workspace-control specification and tracking requirements with the stable Close, fullscreen, Layout source order and mode-specific CSS visual order.
- [x] 8.2 Add real-browser coverage for sequential keyboard order and native button activation without changing the production control markup.
- [x] 8.3 Run Svelte analysis, focused frontend checks, broad repository checks, and strict OpenSpec validation.

## 9. Compact Restore Surface and Sizing

- [x] 9.1 Reconcile the proposal, design, specification, and tracking requirements for 25% larger Compact status and controls and surface-based restoration.
- [x] 9.2 Convert the Compact summary into a native restore surface, remove the dedicated Compact Layout control, and preserve Theater compaction, fullscreen and Close isolation, and iframe continuity.
- [x] 9.3 Increase only Compact status badges, controls, and icons by 25%, halve Compact block-axis padding, and preserve 4rem rows, Theater and fullscreen sizes, and narrow-viewport reachability.
- [x] 9.4 Update focused component and browser tests for pointer and keyboard surface activation, action isolation, geometry, responsive layout, and mounted iframe continuity.
- [x] 9.5 Run Svelte analysis twice, focused frontend checks, formatting, linting, type checking, broad frontend tests, browser verification, and strict OpenSpec validation.

## 10. Balanced Compact Padding

- [x] 10.1 Reconcile the proposal, design, specification, and tracking requirements for equal Compact chrome padding.
- [x] 10.2 Set Compact chrome padding to 0.5rem on both axes, flatten its visible flex hierarchy, and move restoration to a row-spanning native button without changing row or control sizes.
- [x] 10.3 Update pointer, keyboard-focus, hierarchy, and geometry coverage, then run Svelte analysis, focused frontend checks, broad frontend tests, browser verification, and strict OpenSpec validation.

## 11. Shared Window-Control Geometry

- [x] 11.1 Reconcile the proposal, design, specification, and tracking requirements for identical window-control geometry in every presentation mode.
- [x] 11.2 Move the 1.875rem control and 0.9375rem icon sizes to the base window-control rules and update browser geometry coverage for Theater and fullscreen.
- [x] 11.3 Run Svelte analysis, focused frontend checks, broad frontend tests, browser verification, and strict OpenSpec validation.

## 12. Reduced Compact Vertical Whitespace

- [x] 12.1 Reconcile the proposal, design, specification, and tracking requirements with the visible whitespace caused by the fixed Compact row height.
- [x] 12.2 Remove fixed Compact row and window heights, retain equal 0.5rem chrome padding, and update browser geometry coverage for the content-sized result.
- [x] 12.3 Verify the reduced whitespace, shared control geometry, narrow-viewport reachability, and strict OpenSpec validity.

## 13. Inverted Compact Palette

- [x] 13.1 Reconcile the requested Compact background, text, and control inversion with the existing theme-token boundary.
- [x] 13.2 Add dialog surface color custom properties, invert only Compact surfaces and controls, and update browser style coverage.
- [x] 13.3 Verify Compact contrast and unchanged Theater colors in the active browser and focused checks.

## 14. Compact Status Palette and Width

- [x] 14.1 Reconcile the clarified Compact background, white identifier, white status surface, theme-content status text, and wider default badge with the existing palette.
- [x] 14.2 Apply the clarified colors, give the status badge a 5.25rem minimum inline size, center its contents, and update browser coverage.
- [x] 14.3 Verify the palette, approximately 50% wider Live badge, narrow-viewport reachability, and strict OpenSpec validity.
