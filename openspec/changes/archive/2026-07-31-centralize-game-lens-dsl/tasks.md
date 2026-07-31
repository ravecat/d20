## 1. Shared Game Lens DSL

- [x] 1.1 Add focused `D20.GameTest` coverage proving `use D20.Game` supplies field paths, composition, and `all/0`.
- [x] 1.2 Inject Pathex map setup, `all/0`, and private `lens/1` from `D20.Game.__using__/1`, then remove duplicate setup from Koala while keeping `identity/1` local.
- [x] 1.3 Update the Koala Pathex capability to consume the shared field lens without duplicating schema metadata.

## 2. Validation

- [x] 2.1 Format touched Elixir files and run `mix test test/d20/game_test.exs test/d20/koala_rescue_club/game_test.exs`.
- [x] 2.2 Compile with warnings as errors and run broader backend tests because `D20.Game` affects every engine consumer.
- [x] 2.3 Inspect the focused diff and run strict OpenSpec validation for `centralize-game-lens-dsl`.
