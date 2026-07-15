## 1. Command Rename

- [x] 1.1 Replace the exact `submit_turn_selection` event with `submit` in Koala command normalization, submit-phase dispatch, rule validation, turn resolution, and turn-value recording without renaming internal submit concepts
- [x] 1.2 Update focused command, game, server, and session-channel tests to exercise `submit`, preserve submission outcomes, and reject the legacy event

## 2. Public Contract

- [x] 2.1 Update `priv/specs/koala-rescue-club.yaml` to version 0.6.0 and expose only the `submit` channel message, operation, and observable event name while preserving the submission payload schema
- [x] 2.2 Validate the AsyncAPI document and confirm no implementation, test, or public-contract reference still accepts or advertises `submit_turn_selection`

## 3. Validation

- [x] 3.1 Format the touched Elixir files and run targeted Koala command, game, server, and session-channel tests
- [x] 3.2 Review the final diff for exact rename scope, unchanged payload and transition semantics, client coordination risk, and clean separation from unrelated worktree changes

## 4. Dependent Client

- [x] 4.1 Change `/home/max/apps/koala-rescue-club` to send the `submit` wire event through its existing typed `submitTurnSelection` action without changing the payload or UI-facing action API
- [x] 4.2 Extend the focused session store test to assert the exact `submit` SDK call and unchanged `bonus_actions` payload, then confirm no client runtime source sends `submit_turn_selection`

## 5. Client Validation

- [x] 5.1 Format and lint the touched client files, then run the client typecheck, browser tests, and production build with repository-native pnpm commands
- [x] 5.2 Validate the updated OpenSpec change and review both repository diffs without modifying unrelated client or D20 worktree changes
