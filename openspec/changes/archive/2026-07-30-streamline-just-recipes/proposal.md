## Why

The root `justfile` currently duplicates many single Mix tasks and shell commands without adding orchestration, defaults, or policy. This makes the project command surface larger than the workflows it actually owns and requires routine commands to be maintained in both `justfile` and their native tool manifests.

## What Changes

- Add generic `just mix ...` and `just assets ...` dispatchers that preserve argument boundaries and run commands in the correct project directory.
- Define named `just` recipes as project-level workflows that compose multiple actions, rather than aliases for one native Mix, Bun, or Docker command.
- Keep the default recipe as command discovery infrastructure and keep the two generic dispatchers as explicit exceptions to the composition rule.
- **BREAKING** Remove single-action recipes including `setup`, `start`, `down`, `test`, `build`, `typecheck`, `agent-skills-sync`, `agent-skills-check`, and the database wrappers. Their native equivalents remain available directly or through `just mix ...` and `just assets ...`.
- Update retained workflows so they invoke their underlying commands without depending on removed wrapper recipes.
- Update repository guidance and command documentation to describe the smaller command surface and native-command escape hatches.

## Capabilities

### New Capabilities

- `project-command-interface`: Defines generic command dispatch, the eligibility rule for named project recipes, and the retained composite workflows.

### Modified Capabilities

None.

## Impact

- Affected files: `justfile`, `README.md`, and root `AGENTS.md` command guidance.
- Developer-facing command names are intentionally removed, but their underlying Mix, Bun, and Docker behavior is unchanged.
- No dependency, production runtime, database schema, route, session, persistence, or iframe module contract changes are required.
- Rollback consists of restoring the removed one-step wrappers and their documentation.
