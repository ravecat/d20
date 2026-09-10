## 1. Author shell implementation guidance

- [x] 1.1 Create `.agents/skills/implement-shell-feature/SKILL.md` with concise scope, readiness, ownership, authorization, contracts, validation, and completion gates; route gameplay to `implement-playable-game`.
- [x] 1.2 Add the mandatory new-entity TypeID and creation-changeset gate, including named types, string migration and foreign-key compatibility, Ecto autogeneration, actual insertion paths, trusted identity, immutable fields, and applicable constraint/concurrency/retry verification.
- [x] 1.3 Add `agents/openai.yaml` discovery metadata and update root `AGENTS.md` task routing and manual-ownership protection for the new skill.

## 2. Validate the documentation delivery

- [x] 2.1 Run the skill-creator `quick_validate.py` check for the new skill and verify linked repository references and metadata.
- [x] 2.2 Review the guidance against `D20.Games.Game`, its creation context and migration, the existing runtime identity boundary, and `mix.exs`/`justfile` validation commands; walk through a new persisted entity, a UI-only feature, and a gameplay request to verify correct routing and conditional gates.
- [x] 2.3 Run `git diff --check` and `openspec validate add-shell-feature-skill --strict --no-interactive`; confirm the diff contains only the owning skill, routing guidance, and OpenSpec artifacts. Runtime tests are inapplicable because this delivery changes documentation only.

After these tasks pass, reconcile the delivered artifacts, archive through the native OpenSpec workflow, run `openspec validate --all --strict --no-interactive`, confirm absence from `openspec list --json`, and include the reconciled documentation in the same semantic completion commit. The coordinator owns this final lifecycle.

## Validation evidence

- Skill syntax, UI metadata, and repository reference checks passed.
- Independent review found no issues across new-entity, UI-only, and gameplay routing scenarios; Ecto generation, Backpex insertion wiring, runtime IDs, and native commands were checked against repository sources.
- `git diff --check` and `openspec validate add-shell-feature-skill --strict --no-interactive` passed. Application behavior is unchanged, so runtime tests were not required.
