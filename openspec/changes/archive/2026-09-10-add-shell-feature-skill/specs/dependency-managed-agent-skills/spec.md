## MODIFIED Requirements

### Requirement: Manual guidance ownership
The development toolchain SHALL preserve root `AGENTS.md`, `.agents/skills/implement-playable-game/`, and `.agents/skills/implement-shell-feature/` as manually owned guidance.

#### Scenario: Synchronize dependency-managed skills
- **WHEN** the agent skill synchronization command runs
- **THEN** it writes the configured `phoenix-framework` skill without adding a generated UsageRules section to `AGENTS.md` or changing either manually owned implementation skill
