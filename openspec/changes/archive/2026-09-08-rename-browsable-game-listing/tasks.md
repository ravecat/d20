## 1. Rename the catalog operation

- [x] 1.1 Rename `list_browse/1` to `list_browsable/1` in the context typespec/definition, home controller, and existing catalog tests without changing behavior or adding an alias.

## 2. Verify the renamed API

- [x] 2.1 Format/check touched Elixir files and run `mix test test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs`.
- [x] 2.2 Review the diff and search live code/tests for the old name; validate the change with `openspec validate rename-browsable-game-listing --strict --no-interactive`.

After implementation verification, synchronize the catalog delta through native archival, run `openspec validate --all --strict --no-interactive` and `mix openspec.check`, verify active-list removal, and include reconciled artifacts in the same local completion commit. Keep #272 open for provider discovery.

## Verification

- Baseline and final `mix test test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs` passed all 79 tests.
- `MIX_ENV=test mix format lib/d20/games.ex lib/d20_web/controllers/page_controller.ex test/d20/games_test.exs` and the same command with `--check-formatted` passed.
- `MIX_ENV=test mix credo --strict lib/d20/games.ex lib/d20_web/controllers/page_controller.ex test/d20/games_test.exs` checked exactly three files and passed. An earlier broader invocation exposed three existing nesting findings in unchanged Koala game code; no unrelated fixes were made.
- `git diff --check` passed. No old `list_browse` identifier remains in live code or tests. The code diff contains only the requested rename.
- `openspec validate rename-browsable-game-listing --strict --no-interactive` passed.
- Native `openspec archive rename-browsable-game-listing --yes` synchronized the catalog requirement and archived this step. Post-archive `openspec validate --all --strict --no-interactive` passed all 82 items; `MIX_ENV=test mix openspec.check` passed for nine active changes. `openspec list --json` no longer lists this change. Issue #272 remains open for provider discovery; the owning local worktree is retained.
