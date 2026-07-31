## Why

The accepted Koala `left` transition still delegates aggregate mutation to `leave_player/2` and `refresh_setup_phase/1`, both of which use direct struct updates. This leaves one public state-changing command outside the reducer and lens conventions already adopted by the aggregate.

## What Changes

- Route an accepted pre-start `left` command through an `apply_command` reducer clause.
- Remove the departing actor through a Pathex players path and set the refreshed setup phase through the aggregate field lens.
- Remove the now-unused `leave_player/2` and `refresh_setup_phase/1` helpers.
- Preserve the existing no-op behavior for an absent actor, roster-derived readiness, return shape, public projection, and protocol contracts.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `koala-pathex-state-mutations`: Extend the lens-based command mutation requirement and behavior-preservation scenarios to the accepted pre-start `left` transition.

## Impact

- Affected code: `D20.KoalaRescueClub.Game` command dispatch and reducer internals.
- Affected validation: existing Koala aggregate tests for leaving setup and ready games.
- APIs and runtime: no command, payload, projection, persistence, session, or iframe contract changes.
- Dependencies and migrations: none.
- Rollback: restore the two private helpers and the previous `left` dispatch pipeline.
