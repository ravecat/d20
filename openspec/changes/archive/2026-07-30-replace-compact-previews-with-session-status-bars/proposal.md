## Why

The current Compact workspace layout reduces an embedded game to a quarter-height preview that is too small to play or meaningfully inspect while still occupying substantial screen space. Compact mode should instead preserve the live module runtime while presenting only the session state and the controls that remain useful at that size. A newly mounted workspace also expands the first discovered session automatically, so opening the site in another tab or device can cover the surrounding interface without an explicit player action.

## What Changes

- Publish each discoverable session's authoritative `in_progress` or `finished` phase in workspace snapshots.
- Return workspace descriptors and runtime PIDs separately from the internal workspace boundary, leaving the channel to construct the public snapshot envelope.
- Initialize every mounted workspace in Compact and require explicit activation of a Compact session surface before showing a Theater window.
- Replace compact game previews with centered content-sized status bars whose badges match the 1.875rem window controls.
- Derive the visible status from the shared workspace transport and authoritative session phase: Live, Finished, Reconnecting, or Failed.
- Present the status as an uppercase white badge with theme-content text whose text remains authoritative while the dot pulses green for Live, pulses yellow more quickly for Reconnecting, remains red and static for Failed, and remains neutral and static for Finished.
- Move an overflowing session identifier back and forth within its clipped lane while respecting reduced-motion preferences.
- Increase the overflowing identifier's oscillation speed by 20% relative to its original 7-second iteration.
- Keep the iframe and SDK bridge mounted while making compact game content unavailable visually, by pointer, by keyboard, and to assistive technology.
- Keep the Compact status, identifier, and named control group as direct flex siblings, with a separate native restore button spanning the row behind them.
- Remove the dedicated Compact Expand icon and show Enter fullscreen followed by Close at the logical end of the row without drawing a restore-button box around the status and identifier.
- Keep one Close, fullscreen, Layout source and sequential keyboard order in Theater while CSS determines its visual arrangement.
- Show Close, Compact, and Enter fullscreen from top to bottom in Theater, using a lower horizontal line for the Compact icon.
- Use 1.875rem window controls and 0.9375rem control icons in Compact, Theater, and fullscreen while keeping Compact status badges at the same 1.875rem block size.
- Use 0.5rem padding on both axes in Compact chrome and derive the row height from its contents instead of imposing a fixed 4rem height.
- Invert Compact surfaces against the page by using the theme content color as their background, pure white for session identifiers, white status badges with theme-content text, and base-colored controls with content-colored icons.
- Give the status badge a 5.25rem minimum inline size, approximately 50% wider than the original Live badge, while allowing longer status labels to grow.
- Keep the Live and Reconnecting pulse cadences distinct and below accessibility flash limits.
- Reveal the mounted game when fullscreen is entered directly from Compact and return to Compact when fullscreen exits.
- Stack multiple compact bars within the available viewport while preserving the existing Theater and fullscreen behavior.
- Remove compact-surface shadows from the space between stacked bars and halve their gap from 0.75rem to 0.375rem.

## Capabilities

### New Capabilities

- `workspace-session-status-bars`: Actor workspace snapshots expose session phase and compact sessions render as reachable status bars without restarting their embedded modules.

### Modified Capabilities

None.

## Impact

- Backend workspace snapshot construction and channel tests under `lib/d20_web/` and `test/d20_web/`.
- The internal `D20Web.Workspace` API changes without changing the workspace channel payload.
- Frontend workspace wire types, Svelte presentation, unit tests, and browser layout tests under `assets/`.
- Browser-local layout initialization changes from Auto to Compact without synchronizing presentation state across tabs or devices.
- The workspace channel payload gains a required `phase` field for each returned session descriptor.
- Compact identifier motion uses CSS container-query units without adding JavaScript or a dependency.
- No database migration, dependency change, game iframe contract change, or session runtime change is required.
- Rollback requires reverting backend and frontend together because the frontend will rely on the new descriptor field.
- Tracking issues:
  - https://github.com/ravecat/d20/issues/156
  - https://github.com/ravecat/d20/issues/157
  - https://github.com/ravecat/d20/issues/161
  - https://github.com/ravecat/d20/issues/162
