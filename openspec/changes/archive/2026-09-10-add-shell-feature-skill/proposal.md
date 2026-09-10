## Why

D20 has implementation guidance for playable games but no equivalent workflow for shell features. New persisted shell entities need an explicit gate for typed TypeID primary keys and creation changesets used by their real insertion paths.

## What Changes

- Add a concise, manually owned `implement-shell-feature` skill for accounts, actors, discovery and catalog, generic sessions, permissions, and Phoenix/Inertia/Svelte shell integration.
- Require scoped tracking and ready specifications, clear ownership and authorization boundaries, typed persistence identities, explicit creation changesets, contract updates, focused verification, and delivery reconciliation.
- Route gameplay implementation to `implement-playable-game` and register the shell skill in `AGENTS.md`, including protection from dependency-managed skill synchronization.

## Capabilities

### New Capabilities

- `shell-feature-implementation`: Repository-local workflow and mandatory gates for implementing shell functionality.

### Modified Capabilities

- `dependency-managed-agent-skills`: Extend manual guidance ownership to the new shell implementation skill.

## Impact

- Tracking: [GitHub issue #277](https://github.com/ravecat/d20/issues/277), included in the D20 Project.
- Authoring scope: `.agents/skills/implement-shell-feature/`, root `AGENTS.md`, and this change's OpenSpec artifacts and synchronized specifications.
- This is documentation-only delivery. No application code, database migration, dependency, public API, session/runtime behavior, or iframe contract changes are required. The persistence gate applies to future new entities and does not mandate retrofitting existing identifiers.
- Rollback consists of reverting the skill, routing guidance, and corresponding specification changes together.
