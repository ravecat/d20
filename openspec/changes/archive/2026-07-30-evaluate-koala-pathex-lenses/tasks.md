## 1. Regression Boundary

- [x] 1.1 Add a focused game test proving that a duplicate valid `join` preserves the complete existing player state.

## 2. Lens Experiment

- [x] 2.1 Configure Pathex map lenses in `D20.KoalaRescueClub.Game` with a private inline macro.
- [x] 2.2 Rewrite the `join` `apply_command/2` clause to read the rulesheet, insert a missing player idempotently, and refresh phase through lenses, then remove `join_player/2`.

## 3. Validation

- [x] 3.1 Format the touched Elixir files and run `mix test test/d20/koala_rescue_club/game_test.exs`.
- [x] 3.2 Run the complete `test/d20/koala_rescue_club/` namespace and compile with warnings treated as errors.
- [x] 3.3 Run `openspec validate evaluate-koala-pathex-lenses --strict` and inspect the focused diff for unintended contract or dependency changes.

## 4. Schema Metadata Simplification

- [x] 4.1 Remove the duplicated aggregate-field whitelist and let the private `lens/1` macro inline any literal field path.
- [x] 4.2 Format the aggregate, rerun focused and namespace Koala tests, compile with warnings as errors, and strictly validate the updated OpenSpec change.

## 5. Import Cleanup

- [x] 5.1 Import only `Function.identity/1`, use the local capture in the join lens mutation, and rerun focused validation.

## 6. Complete Command Application Migration

- [x] 6.1 Add focused coverage that `start` resets every accepted player while preserving actor-id keys.
- [x] 6.2 Rewrite the `start` and `roll` `apply_command/2` clauses with Pathex field and collection lenses, then remove `game_mode/1`.
- [x] 6.3 Format the touched files, run focused and namespace Koala tests, compile with warnings as errors, and strictly validate the expanded OpenSpec change.
