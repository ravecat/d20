## Context

`Games.visible_stages/0` converts `Application.fetch_env!(:d20, :env)` into a stage list. Home queries, detail visibility, and new-Session authorization share that helper. The existing stage policy is released-only outside development and both stages in development. The focused baseline passed 88 context/page/module tests at `f844175` in the existing `api-game-discovery` worktree using the isolated `_api_discovery` test database partition.

## Goals / Non-Goals

**Goals:** Make stage policy explicit configuration, preserve default behavior and existing Sessions, and keep generic listing independent of deployment policy.

**Non-Goals:** Select the BGG discovery pool, replace home list wrappers, alter frontend cards, migrate game records, or finish the broader #272 discovery fix.

## Decisions

- Define `config :d20, :visible_game_stages, [:released]` before the environment import in `config/config.exs`. Override it with `[:released, :in_development]` in `config/dev.exs`. Standard Elixir configuration resolves the environment-specific values.
- Read `Application.fetch_env!(:d20, :visible_game_stages)` directly at each existing visibility or launch decision. Home query builders pass the resulting native Ecto filters to `Games.list/1`; generic listing adds no implicit policy.
- Remove `:env` and `Games.visible_stages/0`. Do not replace them with `Mix.env/0`, `unquote`, a module attribute, or another helper. Runtime configuration access allows tests to exercise policies without rebuilding modules or pretending to run another environment.
- Keep disabled and invalid-engine rejection independent of the configured list. A matching existing Session remains accessible even when its stage is removed from the list; invalid Session identifiers retain current error semantics.
- Adapt the three existing test modules to save, change, and restore the stage list. Add focused coverage for an empty list and policy changes after Session creation.

## Risks / Trade-offs

- A deployment can explicitly include in-development games. This is intentional configuration policy; checked-in defaults remain released-only, with a dev override.
- Application configuration is global. Tests that modify it remain non-async and restore the original value.
- Repeating one direct configuration read at each policy boundary is intentional and avoids recreating the rejected helper.

## Validation and Rollback

Run the focused context/page/module tests, touched-file `mix format`, compilation with warnings as errors, strict Credo for touched files, and the full backend suite. Resolve `config/config.exs` through `Config.Reader` for dev, test, and prod to confirm defaults. Synchronize and archive this change and run strict OpenSpec and lifecycle validation. No UI markup or protocol changes require frontend checks. Revert this semantic change to restore the former configuration/helper; no database rollback is needed.

## Open Questions

None for this approved configuration step. The provider discovery pool remains an open question in issue #272.

## Verification Results

- Baseline: 88 focused context/page/module tests passed before edits. The adapted both-stage launch test then failed against the original implementation because it ignored the configured list and denied Next Station launch under the test environment.
- `MIX_TEST_PARTITION=_api_discovery mix test test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs test/d20_web/controllers/module_controller_test.exs`: 90 tests passed after the implementation.
- `MIX_TEST_PARTITION=_api_discovery mix test`: 829 tests passed, including empty-policy behavior, generic-list neutrality, disabled/engine-less rejection, detail/session mismatch handling, and existing page/module Session access after policy changes.
- `MIX_ENV=test mix compile --warnings-as-errors` and touched-file formatting checks passed. `Config.Reader.read!` resolved dev to both stages and test/prod to released-only; all three configurations omitted `:d20, :env`.
- `MIX_ENV=test mix credo suggest --strict config/config.exs config/dev.exs lib/d20/games.ex lib/d20_web/controllers/page_controller.ex test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs test/d20_web/controllers/module_controller_test.exs`: seven files, no findings. The full-backend Credo run still reports three pre-existing nesting findings in unchanged `lib/d20/koala_rescue_club/game.ex` at lines 250, 345, and 383.
- No application-code `Mix.env/0`, `visible_stages/0`, or `:d20, :env` references remain. `Games.list/1`, frontend sources, provider calls, persistence, and Session runtime are unchanged by this step. Validation used only the isolated test partition; shared development data was not modified.

- Native `openspec archive configure-game-stage-visibility --yes` synchronized both capabilities and archived the change. `openspec validate --all --strict --no-interactive` passed all 82 items; `MIX_ENV=test mix openspec.check` passed for nine remaining active changes. The completed configuration change is absent from `openspec list --json`.
