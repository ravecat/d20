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
