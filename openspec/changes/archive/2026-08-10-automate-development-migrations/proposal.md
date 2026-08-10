## Why

Development startup should always use the complete existing `serve` Mix alias so dependency, database, seed, and asset preparation cannot diverge between direct and watched launches. Editing a migration alone must not invoke that workflow, because a partially written migration is not a safe automatic trigger.

## What Changes

- Make the `serve` Mix alias run the full `setup` alias before `phx.server`.
- Keep the backward-compatible `start` alias delegated to `serve`.
- Make every initial or replacement child launched by `just serve` invoke the existing `mix serve` alias.
- Restrict automatic watcher inputs to environment and configuration directories; migration files MUST NOT trigger server replacement or migration execution on their own.
- Accept that a later environment or configuration event reruns full setup and can apply any migration pending at that time.
- Prevent Phoenix startup for a watched launch when setup fails and document the forward-only database boundary.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `development-runtime-restart`: Reuse the complete server alias for watched launches while excluding migration files from automatic watcher inputs.

## Impact

- Tracking: [GitHub issue #204](https://github.com/ravecat/d20/issues/204).
- Affected files: `justfile`, `mix.exs`, `README.md`, and the `development-runtime-restart` specification.
- Initial and replacement `just serve` children, direct `mix serve`, and compatibility `mix start` invocations run dependency resolution, database creation and migration, seeds, asset installation, and asset build before Phoenix starts.
- A migration-file change alone does not restart the watched process or execute the migration.
- A later environment or configuration event can apply a migration that was already pending because the replacement child runs full `mix serve`.
- Database reset, rollback, and production release migration behavior remain unchanged.
- No public routes, session/runtime contracts, persistence schemas, dependencies, iframe module contracts, or production startup commands change.
- Rollback restores the direct `phx.server` alias and previous watcher command; it does not require a reverse data migration.
