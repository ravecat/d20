## Why

Phoenix and its companion packages already publish version-specific usage rules, but D20 does not expose them as a repository-local skill or detect when a dependency update makes the generated guidance stale.

## What Changes

- Add UsageRules as development-only Mix tooling.
- Generate one universal `phoenix-framework` skill from the `phoenix` package and every rule-bearing package whose name starts with `phoenix_`.
- Commit the generated skill and check its synchronization through the repository's Just workflow.
- Document that root repository guidance and the existing playable-game skill remain manually owned.

## Capabilities

### New Capabilities

- `dependency-managed-agent-skills`: Generate and validate explicitly configured repository-local skills from locked Mix dependency usage rules.

### Modified Capabilities

None.

## Impact

- Affects `mix.exs`, `mix.lock`, `.agents/skills/phoenix-framework/`, `justfile`, `README.md`, and `AGENTS.md`.
- Adds development-only dependencies and generated documentation files; production runtime, database state, public APIs, sessions, and iframe module contracts are unchanged.
