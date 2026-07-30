## 1. Backend Game Mode

- [x] 1.1 Add nullable `:solo | :multiplayer` mode state and type information to `D20.KoalaRescueClub.Game`, and set it atomically in the validated start transition from the accepted player count
- [x] 1.2 Replace player-order cardinality checks in badge awarding and solo-rank calculation with branches on the stored mode while preserving existing score and award values
- [x] 1.3 Extend `test/d20/koala_rescue_club/game_test.exs` for unset pre-start mode, one-player solo start, multi-player start, stable active mode, mode-specific badges and ranks, and JSON encoding
- [x] 1.4 Update focused session and custom-server assertions to verify that started Koala games carry the captured mode through automatic rolls and ignored in-progress roster events
- [x] 1.5 Derive start mode from `game.players`, remove pre-start leavers from the current roster and temporary order compatibility field, recalculate readiness, and cover the corrected lifecycle with focused aggregate and session tests

## 2. Projection And Public Contract

- [x] 2.1 Add `game.mode` to the Koala projection type and rendered game map without adding a duplicate top-level session field
- [x] 2.2 Extend `test/d20_web/projection_test.exs` for `null` pre-start mode and caller-independent solo and multiplayer values in active or finished projections
- [x] 2.3 Require nullable `mode` with only `solo` and `multiplayer` non-null values in the `game` schema of `priv/specs/koala-rescue-club.yaml`
- [x] 2.4 Validate the updated contract with `npx -y @asyncapi/cli@latest validate priv/specs/koala-rescue-club.yaml`

## 3. Dependent Client

- [x] 3.1 Add `GameMode` and required nullable `Game.mode` typing in `/home/max/apps/koala-rescue-club/src/types/session.ts`, then add explicit mode values to complete session fixtures in the store and browser tests
- [x] 3.2 Update `/home/max/apps/koala-rescue-club/src/components/results.svelte` to select the solo score card or multiplayer standings only from `game.mode` while preserving score sorting, content, popover controls, and accessibility
- [x] 3.3 Update `/home/max/apps/koala-rescue-club/tests/components/app.browser.test.ts` to cover solo and multiplayer results and prove explicit mode wins over score cardinality without adding a collection-count fallback
- [x] 3.4 Run `just check`, `just test`, and `just build` in `/home/max/apps/koala-rescue-club`

## 4. Validation And Review

- [x] 4.1 Format-check the touched Elixir files with `mix format --check-formatted` and run the focused game, server, session, and projection tests with `mix test`
- [x] 4.2 Run `just check` in `/home/max/apps/d20` because the change spans aggregate behavior, a public protocol, and a separately built client
- [x] 4.3 Search both codebases to confirm no Koala mode-specific backend rule or final-results branch still infers mode from player, order, score, or standings cardinality
- [x] 4.4 Review both worktrees to preserve unrelated dirty changes and confirm the release handoff specifies backend-first deployment and client-first rollback
- [x] 4.5 Run `openspec validate make-koala-game-mode-explicit --strict`
- [x] 4.6 Re-run focused backend validation and `openspec validate make-koala-game-mode-explicit --strict` after the roster-source correction
