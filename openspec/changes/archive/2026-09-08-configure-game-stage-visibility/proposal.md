## Why

Game selection and launch currently infer policy from the application environment name. The approved step of [#272](https://github.com/ravecat/d20/issues/272) makes permitted stages explicit configuration so the catalog context does not depend on Mix or environment identity.

## What Changes

- Set `:visible_game_stages` to `[:released]` by default and `[:released, :in_development]` in development configuration.
- Read the configured stages inline when constructing visibility queries, checking detail visibility, and authorizing new Sessions; remove `Games.visible_stages/0` and `:d20, :env`.
- Keep `Games.list/1` policy-neutral and preserve enabled/engine checks, current ordering, metadata fallback, and existing-Session access.
- Test stage policy by changing the stage list instead of simulating environment names.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `game-catalog-availability`: Configured stages govern visibility, with dev/default values preserving current behavior.
- `game-session-launch-policy`: New Sessions require a configured visible stage, enablement, and a valid engine.

## Impact

Changes affect `config/config.exs`, `config/dev.exs`, `D20.Games`, `D20Web.PageController`, and focused context/page/module tests. No persistence migration, frontend or iframe contract change, dependency update, or Session runtime change is required. Reverting the code and configuration restores the previous environment-derived policy.

This bounded configuration step shares issue #272 and its existing worktree. Provider discovery and the replacement of home list wrappers remain under that issue because the external discovery pool still requires a decision. They are not acceptance gates for this approved step.
