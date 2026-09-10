## 1. Extend the shell skill

- [x] 1.1 Add the Storybook UI testing gate to `implement-shell-feature/SKILL.md`: deterministic screen/state stories, `play` scenarios and assertions, complex UI steps, and justified distinct standalone Vitest coverage without duplication.
- [x] 1.2 Require reviewed screenshot comparisons at the existing viewports, dedicated stories for required intermediate states, candidate review for new baselines, narrow intentional updates, normal comparison reruns, and visual evidence in completion reporting.

## 2. Validate the guidance

- [x] 2.1 Run skill-creator `quick_validate.py`; review the edited gate and native `bun run test:visual -- <story-path>` guidance against `assets/stories/README.md`, `assets/package.json`, `assets/vite.config.mjs`, and `assets/.storybook/vitest.setup.ts`. Walk through new UI, changed visuals, intermediate states, and a separate-test exception.
- [x] 2.2 Run `git diff --check` and `openspec validate require-shell-storybook-test-gate --strict --no-interactive`; confirm the diff is limited to the shell skill and owning OpenSpec artifacts. Runtime stories, tests, builds, and screenshots are inapplicable to this documentation-only delivery.

After these tasks pass, the coordinator reconciles and archives the change, runs `openspec validate --all --strict --no-interactive`, confirms absence from `openspec list --json`, and commits the skill and reconciled specifications together.

## Validation evidence

- Skill syntax validation and `git diff --check` passed; the TypeID and creation changeset gate is unchanged.
- Independent review verified the existing Storybook addon, viewport projects, shared screenshot lifecycle, and command boundary. New UI, changed visuals, intermediate states, complex UI flows, and separate-test exceptions passed the guidance walkthrough.
- `openspec validate require-shell-storybook-test-gate --strict --no-interactive` passed. This documentation-only change does not require runtime tests, builds, or screenshot capture.
