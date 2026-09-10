## Why

The shell feature skill requires frontend verification but does not make Storybook scenarios and reviewed screenshot comparisons a completion gate. D20 already runs stories and visual comparisons through the Vitest addon, so the guidance needs to define coverage and evidence rather than new infrastructure.

## What Changes

- Require stories for new or changed screens and visual states, with interaction scenarios and semantic assertions in `play`.
- Require actual screenshot comparisons and image inspection, including required initial and intermediate states, narrow intentional baseline updates, and a normal comparison rerun.
- Center UI tests on stories; permit separate Vitest tests only when complex logic or boundaries need distinct coverage that stories cannot adequately provide, with a documented reason.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `shell-feature-implementation`: Add a Storybook UI testing gate and connect it to delivery completion.

## Impact

- Continue [issue #277](https://github.com/ravecat/d20/issues/277), reopened in the D20 Project. The earlier phase is recorded at `openspec/changes/archive/2026-09-10-add-shell-feature-skill/`; a new delta is needed because that skill introduction was already delivered and archived.
- Change only `.agents/skills/implement-shell-feature/SKILL.md` and owning OpenSpec artifacts. Existing `AGENTS.md` routing remains sufficient.
- No runtime, story, test, screenshot baseline, runner, dependency, database migration, session, API, or iframe contract changes. Rollback reverts the guidance and matching specification changes together.
