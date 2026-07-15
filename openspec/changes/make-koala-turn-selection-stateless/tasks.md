## 1. Game State And Rules

- [x] 1.1 Remove `turn_selection` from the Koala player type, constructors, resets, and game transitions, and update focused state assertions
- [x] 1.2 Replace stored-draft resolution with atomic full-selection submission in `Command` and `Rules`
- [x] 1.3 Expose only the rule-level legality primitives needed by projection and remove projection-specific option and selection types and functions from `Rules`

## 2. Stateless Projection Transport

- [x] 2.1 Move option and selection type definitions and assembly into `D20.KoalaRescueClub.Projection`
- [x] 2.2 Add `project_turn_selection` request routing through `D20Web.SessionChannel` and `D20Web.Projection` without game dispatch or broadcast
- [x] 2.3 Remove `selection` from regular session projections and add focused projection and channel coverage for valid, invalid, and non-mutating requests

## 3. Public Contract

- [x] 3.1 Replace draft mutation messages with `project_turn_selection`, expand `submit_turn_selection`, and remove regular session `selection` in `priv/specs/koala-rescue-club.yaml`
- [x] 3.2 Validate the AsyncAPI document with the repository-compatible AsyncAPI CLI command

## 4. Dependent Client

- [x] 4.1 Update `/home/max/apps/koala-rescue-club` transport types and calls for stateless projection and full selection submission
- [x] 4.2 Keep shape selection in the Svelte turn store, project each complete local draft, and reset locally while preserving the in-progress bonus feature
- [x] 4.3 Update client fixtures and browser tests for request replies, local selection state, submission payloads, and the absence of regular session `selection`

## 5. Validation And Review

- [x] 5.1 Run targeted formatting and backend tests for Koala game, command, rules, projection, server, and session channel behavior
- [x] 5.2 Run `just check`, `just test`, and `just build` in `/home/max/apps/koala-rescue-club`
- [x] 5.3 Run `openspec validate make-koala-turn-selection-stateless --strict` and review both dirty worktrees for unrelated-change preservation
