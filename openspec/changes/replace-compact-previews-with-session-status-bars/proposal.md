## Why

The current Compact workspace layout reduces an embedded game to a quarter-height preview that is too small to play or meaningfully inspect while still occupying substantial screen space. Compact mode should instead preserve the live module runtime while presenting only the session state and the controls that remain useful at that size. A newly mounted workspace also expands the first discovered session automatically, so opening the site in another tab or device can cover the surrounding interface without an explicit player action.

## What Changes

- Publish each discoverable session's authoritative `in_progress` or `finished` phase in workspace snapshots.
- Return workspace descriptors and runtime PIDs separately from the internal workspace boundary, leaving the channel to construct the public snapshot envelope.
- Initialize every mounted workspace in Compact and require an explicit Expand action before showing a Theater window.
- Replace compact game previews with centered 4rem status bars whose badges match the 1.5rem controls.
- Derive the visible status from the shared workspace transport and authoritative session phase: Live, Finished, Reconnecting, or Failed.
- Present the status as an uppercase outlined badge whose text remains authoritative while the dot pulses green for Live, pulses yellow more quickly for Reconnecting, remains red and static for Failed, and remains neutral and static for Finished.
- Move an overflowing session identifier back and forth within its clipped lane while respecting reduced-motion preferences.
- Increase the overflowing identifier's oscillation speed by 20% relative to its original 7-second iteration.
- Keep the iframe and SDK bridge mounted while making compact game content unavailable visually, by pointer, by keyboard, and to assistive technology.
- Show Expand, Enter fullscreen, and Close in that horizontal order so Close is at the logical end.
- Show Close, Compact, and Enter fullscreen from top to bottom in Theater, using a lower horizontal line for the Compact icon.
- Normalize every window-control icon to one square geometry and use an unfilled outline square for Expand.
- Reduce window-control icons to 0.75rem while keeping their matching controls and status badges at 1.5rem.
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
