## 1. Resolve Internal Transitions

- [x] 1.1 In `D20.KoalaRescueClub.Game`, define private data-only transition shapes and pure helpers that resolve initialized/retained rosters, setup phase, start mode, and the post-validation die value without returning a modified `Game.t()`.
- [x] 1.2 Refactor submit progression into pure decisions over explicit rulesheet, mode, round, turn, player, and players-map facts, preserving the order submit, badge award, optional round score, then advance or finish.
- [x] 1.3 Narrow badge, round-score, final-score, rank, and player-update helpers to return calculated players, scores, scalars, or transition data instead of accepting and returning the aggregate.

## 2. Establish the Application Seam

- [x] 2.1 Replace command-specific public `dispatch/2` clauses with one thin adapter, move their guards, validation order, no-op handling, `Rules.resolve_turn/2`, `Dice.roll!/1`, and transition decisions into private `execute/2` clauses, and make every successful execute return an ordered transition list.
- [x] 2.2 Add Pathex-based `apply/2` clauses for player join, pre-start leave, game start, die roll, and player submit while preserving idempotent roster behavior and exact field updates.
- [x] 2.3 Add Pathex-based `apply/2` clauses for badge award, round score, turn advance, and game finish, then remove `apply_command/*`, `maybe_*`, and every superseded helper that transforms `Game.t()`.
- [x] 2.4 Inspect the focused `game.ex` diff to confirm string command names, dispatch results and errors, aggregate fields, game rules, and Session/server/channel/projection interfaces are unchanged and no persistence, shared-engine, or protocol work entered the change.
- [x] 2.5 Collapse the forwarding `award_badges/4` clauses and their mode-specific proxy names into direct solo and multiplayer `award_badges/4` implementations without changing badge behavior.
- [x] 2.6 Inline one-use player initialization, roster readiness, game-mode selection, submit completion, and transition sequencing into `execute/2`, then flatten badge, round-score, and final-score calculations so retained local helpers are leaf functions that do not call other local helpers.
- [x] 2.7 Replace all `Rules` calls to `Game.fetch_player/2` with direct `Map.fetch/2`, remove the non-contractual public proxy from `Game`, and remove its obsolete dedicated unit test.

## 3. Requested Validation

- [x] 3.1 Run `mix format` for the touched Elixir and test files and confirm they remain formatted.
- [x] 3.2 Run `mix compile --warnings-as-errors` and resolve any warnings without widening the scoped implementation.
- [x] 3.3 Run `openspec validate separate-koala-dispatch-apply --strict --no-interactive` and confirm the only test diff is removal of the deleted proxy's obsolete test; do not run any test command.
