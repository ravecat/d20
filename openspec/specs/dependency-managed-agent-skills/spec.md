# dependency-managed-agent-skills Specification

## Purpose
TBD - created by archiving change add-phoenix-framework-skill. Update Purpose after archive.
## Requirements
### Requirement: Phoenix framework skill generation
The development toolchain SHALL generate one repository-local skill named `phoenix-framework` from UsageRules published by the `phoenix` package and rule-bearing packages whose names start with `phoenix_`.

#### Scenario: Synchronize the configured skill
- **WHEN** a developer runs the documented agent skill synchronization command with development dependencies available
- **THEN** `.agents/skills/phoenix-framework/` contains a UsageRules-managed `SKILL.md` and the references available from `:phoenix` and `~r/^phoenix_/`

#### Scenario: Ignore unrelated packages
- **WHEN** synchronization scans the locked Mix dependency set
- **THEN** packages outside `:phoenix` and `~r/^phoenix_/` do not contribute rules to `phoenix-framework`

### Requirement: Manual guidance ownership
The development toolchain SHALL preserve root `AGENTS.md` and `.agents/skills/implement-playable-game/` as manually owned guidance.

#### Scenario: Synchronize dependency-managed skills
- **WHEN** the agent skill synchronization command runs
- **THEN** it writes the configured `phoenix-framework` skill without adding a generated UsageRules section to `AGENTS.md` or changing the playable-game skill

### Requirement: Generated skill drift detection
The repository SHALL provide a read-only check that fails when committed dependency-managed skill content differs from the configured locked dependency rules.

#### Scenario: Generated skill is current
- **WHEN** `phoenix-framework` matches the configured locked dependency rules
- **THEN** the focused agent skill check exits successfully

#### Scenario: Generated skill is stale
- **WHEN** a generated skill file differs from the configured locked dependency rules
- **THEN** the focused agent skill check exits unsuccessfully without rewriting files

### Requirement: Runtime isolation
UsageRules generation tooling SHALL remain development-only and SHALL NOT become part of the production runtime dependency tree.

#### Scenario: Inspect production dependencies
- **WHEN** the production dependency tree is resolved
- **THEN** UsageRules and its tooling-only dependencies are absent
