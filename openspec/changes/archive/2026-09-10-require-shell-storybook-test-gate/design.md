## Context

The existing shell skill has generic frontend verification guidance. `assets/stories/README.md` defines deterministic production-component stories and `play` assertions. `assets/vite.config.mjs` runs those stories with `@storybook/addon-vitest` at desktop, tablet, and mobile viewports; `assets/.storybook/vitest.setup.ts` compares the full document after `play` through `toMatchScreenshot`. These are the implementation sources for the new guidance.

## Goals / Non-Goals

**Goals:** Require story-based shell UI coverage, reviewed visual evidence, and a justified allocation of separate tests.

**Non-Goals:** Change runtime behavior, test infrastructure, existing stories or baselines, backend test policy, or unrelated guidance.

## Decisions

1. Extend the skill's verification gate using existing Storybook conventions. New or changed screens and visual states need deterministic stories; interaction scenarios and semantic assertions belong in `play`, including complex UI flows expressed as steps. Repeating that coverage in standalone Vitest UI tests adds no distinct signal.
2. Require affected story execution through the native `bun run test:visual -- <story-path>` command from `assets/`, preserving its desktop/tablet/mobile projects. Storybook already uses Vitest, so the exception concerns separate test files, not the runner. Permit those files only for complex logic or boundaries inadequately covered by stories, recording the reason and unique signal in the owning change. Retain relevant backend and distinct lower-layer or cross-process coverage.
3. Treat screenshots as state-specific evidence. Since the shared hook captures only the end of the story lifecycle, use dedicated deterministic stories for required before or intermediate states that `play` would otherwise leave behind. Keep interaction assertions as complementary behavioral evidence.
4. Require image-tool inspection of baseline, actual, and available diff images before accepting a visual change. For new UI with no baseline, inspect the candidate against the intended design, create or accept only the reviewed reference, then run a normal comparison. For intentional changes, update only affected references and rerun without update mode. A passing `play`, build, generated file, or blanket baseline update cannot satisfy the visual gate.

## Risks / Trade-offs

- Story mocks cannot prove backend or transport behavior. Preserve tests for distinct real boundaries and require an explicit reason when adding separate frontend tests.
- End-of-play capture can miss transient required visuals. Make those states stable story outcomes instead of claiming final-state screenshots cover the whole interaction.
- Automatic reference creation can accept an unnoticed defect. Inspect candidate images and rerun comparison after reviewed baseline acceptance.

No migration is required. Rollback reverts the skill and matching specification delta together. No unresolved decisions remain.
