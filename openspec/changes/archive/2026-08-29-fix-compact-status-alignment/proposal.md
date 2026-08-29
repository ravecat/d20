## Why

Compact workspace status badges grow to fit longer labels, so the session title shifts horizontally when status changes from Live or Finished to Reconnecting. Status and title alignment should remain stable while players scan or monitor session rows.

## What Changes

- Reserve one consistent status-badge inline size for Live, Finished, Reconnecting, and Failed.
- Keep status contents and the adjacent session title vertically centered on the same row.
- Preserve the existing Compact controls, responsive reachability, status colors, motion, and accessible text.
- Extend focused visual coverage across ready, finished, reconnecting, and failed Compact states.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `workspace-session-status-bars`: Compact status badges use one stable inline size so status changes do not move the session-title lane.

## Impact

- Frontend Compact workspace presentation in `assets/js/widgets/workspace/ui/workspace.svelte`.
- Storybook status fixtures and visual references under `assets/stories/` and `assets/__screenshots__/`.
- No backend, database, public API, iframe contract, dependency, or session-runtime changes.
- Rollback restores the previous intrinsic status width and its associated title movement.
- Tracking issue: https://github.com/ravecat/d20/issues/256
