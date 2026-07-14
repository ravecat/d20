## 1. Legal Placement Enumeration

- [x] 1.1 Add a `D20.KoalaRescueClub.Ruleset` helper that enumerates and deduplicates every translated rotation and reflection of a die shape within one map area.
- [x] 1.2 Add `D20.KoalaRescueClub.Rules` helpers that filter placements by accessible area, tree occupancy, and koala prerequisites, then derive compatible placements, available cells, and completion from a partial selection.
- [x] 1.3 Add ruleset and rules tests for irregular map boundaries, transformed placements, inaccessible areas, action prerequisites, order-independent partial selections, dead ends, and completed shapes.

## 2. Staged Command and Aggregate State

- [x] 2.1 Replace direct multi-cell command validation with payload validation for contextual `select_turn_cell`, `deselect_turn_cell`, `reset_turn_selection`, and `submit_turn_selection`, while retaining the single-cell fallback commands and session start-command compatibility.
- [x] 2.2 Extend the Koala player aggregate and types with an optional compact turn selection initialized to `nil` when players join and when a new turn begins.
- [x] 2.3 Implement creating and replacing a legal selection from the first cell click without spending volunteers or mutating the committed player sheet.
- [x] 2.4 Implement idempotent select and deselect transitions plus reset, rejecting dead-end cells and commands from players who are not pending.
- [x] 2.5 Add command and game tests for payload normalization, obsolete whole-shape rejection, legal first-click selection, invalid first-click rollback, replacement, retry idempotency, deselection, reset, and submitted-player errors.

## 3. Atomic Submission and Bonuses

- [x] 3.1 Simulate a complete primary action on a copy of the player sheet so newly unlocked bonus options can be derived without committing state.
- [x] 3.2 Implement `submit_turn_selection` revalidation and atomic application of volunteer spending, selected cells, ordered bonus decisions, selection clearing, and submitted status.
- [x] 3.3 Preserve the complete draft and all committed state when shape, volunteer, or bonus validation fails.
- [x] 3.4 Route successful staged submissions through the existing badge, round scoring, finish, and simultaneous next-turn transitions, clearing all new-turn drafts.
- [x] 3.5 Add game tests for incomplete submission, successful tree and koala submissions, bonus preview and resolution, invalid bonus rollback, volunteer accounting, multi-player advancement, round scoring, and finish behavior.

## 4. Caller-Specific Projection Contract

- [x] 4.1 Change `turn_options` to expose reachable die values, volunteer cost, required cell count, and each legal shape action's initial available cells without requiring client-side transform data.
- [x] 4.2 Add caller-specific `turn_selection` projection data for selected cells, available cells, completion, and simulated bonus options.
- [x] 4.3 Keep drafts out of rendered player state and add two-caller projection tests proving another player sees only committed sheet state.
- [x] 4.4 Update affected session and server tests to use the staged shape protocol while proving `circle_tree` and `circle_koala` remain atomic.

## 5. Validation

- [x] 5.1 Run `mix test test/d20/koala_rescue_club/ruleset_test.exs test/d20/koala_rescue_club/command_test.exs test/d20/koala_rescue_club/game_test.exs` during core implementation.
- [x] 5.2 Run `mix test test/d20/koala_rescue_club test/d20_web/projection_test.exs test/d20/sessions/session_test.exs` after integration changes.
- [x] 5.3 Run `mix format.check` and format only files changed by this work if needed.
- [x] 5.4 Run `mix typecheck` because caller-facing projection fields change.
- [x] 5.5 Run `just check` before completion, or record any unrelated pre-existing failure with the failing command and affected file.

## 6. Click-First Client Repair

- [x] 6.1 Let `select_turn_cell` create or replace a draft from a contextual first-cell click while retaining target-only continuation compatibility.
- [x] 6.2 Add initial action-specific `available_cells` to `turn_options` and document the staged commands and selection projection in AsyncAPI.
- [x] 6.3 Update the Koala iframe types and session adapter to use select, deselect, reset, and submit selection commands.
- [x] 6.4 Render server-projected individual cells, remove local rotation controls, and keep confirmation disabled until `turn_selection.complete`.
- [x] 6.5 Add backend and browser tests proving initial highlights, one-cell command payloads, projection-driven continuation, and complete-only confirmation.
- [x] 6.6 Run focused checks and both repositories' complete validation commands.
- [x] 6.7 Remove the obsolete explicit selection-start command and keep the contextual first cell click as the only draft creation path.
