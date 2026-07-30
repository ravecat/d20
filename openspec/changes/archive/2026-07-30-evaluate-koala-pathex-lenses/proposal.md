## Why

Koala Rescue Club aggregate transitions currently mix direct struct updates with command-specific mutation helpers, so the reducer has no common vocabulary for reading and changing authoritative fields. A focused Pathex experiment can show whether explicit field lenses make the `join` transition more uniform without changing game behavior or prematurely migrating every reducer.

## What Changes

- Define one private Pathex lens macro for `D20.KoalaRescueClub.Game` field references without duplicating the embedded-schema field list.
- Rewrite every `apply_command/2` clause so `join`, `start`, and `roll` aggregate reads and mutations are expressed directly with Pathex lenses.
- Remove the join-only mutation helper while preserving duplicate-join idempotency and complete player initialization.
- Use Pathex's collection lens to reset every player on `start` and set every player pending on `roll` without command-specific map-rebuild helpers.
- Add focused regression coverage for rejoining an existing player without replacing any committed player state.
- Keep every other game transition, public command, projection, protocol, and dependency version unchanged.

## Capabilities

### New Capabilities

- `koala-pathex-state-mutations`: Defines the schema-backed lens mechanism and behavior-preserving lens-based `apply_command/2` experiment for the Koala Rescue Club aggregate.

### Modified Capabilities

None.

## Impact

- Affects `lib/d20/koala_rescue_club/game.ex` and focused tests in `test/d20/koala_rescue_club/game_test.exs`.
- Uses the existing locked Pathex 2.6 dependency and does not change dependency manifests.
- Does not change persistence, session runtime behavior, iframe contracts, public projections, command payloads, or error reasons.
- Rollback consists of restoring the direct helper-based reducer and its focused test; no data migration or compatibility sequence is required.
- Tracked by GitHub issue [#163](https://github.com/ravecat/d20/issues/163).
