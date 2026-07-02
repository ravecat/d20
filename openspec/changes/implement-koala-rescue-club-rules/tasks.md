## 1. Map Data

- [x] 1.1 Encode Koala Rescue Club map data structures for areas, cells, printed koalas, rows, columns, bonuses, hospitals, skybridges, and badges.
- [x] 1.2 Replace `sheet: :not_encoded` for implemented maps with reviewable machine-readable geometry data.
- [x] 1.3 Add map data validation helpers that reject missing cell ids, invalid area references, invalid line references, invalid bonus bindings, invalid hospital definitions, invalid skybridge edges, and badges without predicates.
- [x] 1.4 Add tests for Dharug and Yugambeh configuration, geometry integrity, die shapes, volunteer helpers, hospital scoring, and solo rating bands.
- [x] 1.5 Stop implementation of placement-dependent rules if any map geometry or badge predicate cannot be encoded from an authoritative source.

## 2. Command and Rule Validation

- [x] 2.1 Add `D20.KoalaRescueClub.Command` validation for `join`, `start`, `roll`, and turn action events with payload shapes.
- [x] 2.2 Add `D20.KoalaRescueClub.Rules` phase, identity, player membership, map selection, roll, and duplicate submission validation.
- [x] 2.3 Implement placement validation for shape actions, rotations, flips, accessible areas, occupied cells, and koala-on-circled-tree prerequisites.
- [x] 2.4 Implement fallback single-circle action validation.
- [x] 2.5 Implement bonus unlock and bonus resolution validation for tree, koala, volunteer, hospital, and skybridge bonuses.
- [x] 2.6 Add unit tests for valid and invalid commands, invalid phases, invalid maps, invalid die adjustments, inaccessible areas, occupied cells, invalid koala targets, and invalid bonuses.

## 3. Game Reducer

- [x] 3.1 Replace `D20.KoalaRescueClub.Game` placeholder with an Ecto embedded aggregate for phase, order, selected map, turn, roll, players, sheets, badge awards, round scores, and final scores.
- [x] 3.2 Implement join and start transitions without changing the generic session contract.
- [x] 3.3 Implement roll transition that records one shared die result per turn and marks all joined players pending.
- [x] 3.4 Implement submit transition that applies volunteer spending, primary action, bonus actions, turn log updates, and per-player submitted status.
- [x] 3.5 Implement turn advancement, round scoring after turns 15 and 30, final scoring, solo rank calculation, and multiplayer tie-breaker data.
- [x] 3.6 Add reducer tests for setup, full representative turns, all phase transitions, scoring turns, finish behavior, and error reasons.

## 4. Projection, Permissions, and Session Integration

- [x] 4.1 Add `D20.KoalaRescueClub.Permission` with caller-specific `can_start_game`, `can_roll`, and `can_submit_turn` permissions.
- [x] 4.2 Add `D20.KoalaRescueClub.Projection` for authoritative game state and permissions.
- [x] 4.3 Route Koala Rescue Club sessions through `D20Web.Projection` while preserving existing Qwinto projection behavior.
- [x] 4.4 Add session tests for creating, joining, starting, rolling, submitting, receiving projections, permission changes, and finishing a Koala Rescue Club session.

## 5. Validation

- [x] 5.1 Run `mix test test/d20/koala_rescue_club`.
- [x] 5.2 Run targeted affected tests for sessions and projection, including `mix test test/d20/sessions_test.exs test/d20/sessions/session_test.exs test/d20_web/projection_test.exs`.
- [ ] 5.3 Run `mix format.check`.
  - Blocked: `mix format.check` fails on pre-existing formatting in `test/d20/qwinto/game_test.exs`, which is outside this change.
- [x] 5.4 Run `mix typecheck` if projection or frontend-facing payload types are changed.
- [ ] 5.5 Run `just check` before completion unless blocked by unrelated pre-existing failures, and record any blocker with the failing command output.
  - Blocked: `just check` stops at `mix format.check` on the same pre-existing `test/d20/qwinto/game_test.exs` formatting issue.
