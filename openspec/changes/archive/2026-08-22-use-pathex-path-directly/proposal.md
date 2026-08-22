## Why

Game aggregates currently mix direct struct updates, map rebuilds, `put_in/2`, a project-specific `lens/1` proxy, and Pathex paths. One explicit Pathex mutation vocabulary makes state-machine transitions easier to read while removing indirection and tests that only re-check Pathex or Elixir mechanics.

## What Changes

- Remove the private `lens/1` helper injected by `D20.Game.__using__/1` while retaining shared Pathex map configuration and `all/0`.
- Replace Koala Rescue Club aggregate `lens/1` calls with direct `path/1` calls.
- Express Next Station: London aggregate state-machine mutations with direct Pathex field, keyed-player, and collection paths.
- Remove `D20.GameTest` fixtures and assertions that test Pathex map, struct, bang, and collection behavior rather than D20-owned contracts.
- Preserve the rule-aligned Next Station phase graph delivered by issue #220 and all existing game behavior and public contracts.

## Capabilities

### New Capabilities

- `next-station-london-pathex-state-mutations`: Define the behavior-preserving Pathex mutation vocabulary for Next Station aggregate commands and automatic transitions.

### Modified Capabilities

- `game-engine-lens-dsl`: Supply direct Pathex `path/1` and `all/0` usage without a private `lens/1` proxy.
- `koala-pathex-state-mutations`: Describe Koala aggregate mutation through direct Pathex paths instead of the removed shared helper.

## Impact

- Affected code: `lib/d20/game.ex`, `lib/d20/koala_rescue_club/game.ex`, `lib/d20/next_station_london/game.ex`, and focused tests.
- Affected specifications: the shared Game path DSL, Koala Pathex mutation contract, and a new Next Station Pathex mutation contract.
- No command, error, projection, AsyncAPI, persistence, session/runtime, iframe, dependency, or database migration change.
- Rollback restores the private helper and the prior aggregate mutation expressions while retaining the phase model from #220.
- Tracked by [ravecat/d20#221](https://github.com/ravecat/d20/issues/221).
