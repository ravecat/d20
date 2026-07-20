## 1. Configure UsageRules

- [x] 1.1 Add development-only UsageRules and Igniter dependencies and lock their resolved versions
- [x] 1.2 Configure the single `phoenix-framework` skill from `:phoenix` and `~r/^phoenix_/` in skills-only mode

## 2. Generate And Document The Skill

- [x] 2.1 Synchronize and review the generated `.agents/skills/phoenix-framework/` files
- [x] 2.2 Add explicit Just commands for skill synchronization and drift checking
- [x] 2.3 Document manual and generated skill ownership in `README.md` and `AGENTS.md`

## 3. Validate The Change

- [x] 3.1 Verify clean synchronization, stale-file failure behavior, and production dependency isolation
- [x] 3.2 Run formatting, strict OpenSpec validation, generated-file drift checking, and the repository check suite (the full command stops on the unrelated unformatted `session_panel.svelte`; all remaining checks pass independently)
