## Why

Koala Rescue Club applies validated `submit` commands through `apply_submit/3` while `join`, `start`, and `roll` use the aggregate's `apply_command` reducer. Routing submit through the same reducer boundary makes command application uniform and extends the Pathex mutation experiment without changing game behavior.

## What Changes

- Route an accepted `submit` command from `dispatch/2` to an `apply_command` clause after resolving its legal player transition once.
- Replace `apply_submit/3` with lens-based aggregate mutation in the command reducer.
- Preserve atomic submit resolution, turn history, shared turn completion, scoring, phase changes, public projections, payloads, and error reasons.
- Add focused regression coverage that rejected submit commands leave the aggregate unchanged.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `koala-pathex-state-mutations`: Extend lens-based command application to the accepted Koala `submit` transition and remove the command-specific aggregate helper.

## Impact

- Affects `lib/d20/koala_rescue_club/game.ex`, focused tests in `test/d20/koala_rescue_club/game_test.exs`, and the existing Koala Pathex mutation specification.
- Uses the existing Pathex dependency without manifest changes.
- Does not change persistence, session runtime behavior, iframe contracts, public projections, command payloads, or error reasons.
- Rollback restores `apply_submit/3` and the prior dispatch call without data or protocol migration.
- Tracked by GitHub issue [#168](https://github.com/ravecat/d20/issues/168).
