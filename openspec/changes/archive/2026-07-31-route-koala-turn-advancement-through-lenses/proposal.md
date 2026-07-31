## Why

Koala command reducers now use Pathex consistently, but automatic completion still mixes direct struct updates with the one-use `set_player_statuses/2` map-rebuild helper. Moving that transition to the same field and collection lens vocabulary removes mutation-only indirection without changing turn or scoring rules.

## What Changes

- Read the current turn through the aggregate turn lens in `maybe_finish/1`.
- Set final phase and scores through field lenses on the final turn.
- Set the next phase, round, turn, cleared roll, and every player status through field and collection lenses on a non-final turn.
- Remove the superseded `set_player_statuses/2` helper.
- Preserve all existing automatic advancement, finalization, score, projection, and protocol behavior.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `koala-pathex-state-mutations`: Extend lens-based aggregate mutation to automatic turn advancement and finalization after a completed turn.

## Impact

- Affected code: `D20.KoalaRescueClub.Game.maybe_finish/1` and the removed private status helper.
- Affected validation: existing Koala aggregate tests for multiplayer turn advancement and final scoring.
- APIs and runtime: no command, payload, projection, persistence, session, or iframe contract changes.
- Dependencies and migrations: none.
- Rollback: restore the direct struct updates and `set_player_statuses/2` helper.
