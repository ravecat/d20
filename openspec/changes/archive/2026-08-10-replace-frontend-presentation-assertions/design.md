## Context

The frontend suite uses Vitest with jsdom unit projects and Playwright-backed Chromium and Firefox browser projects. Four browser test files currently call `getComputedStyle`, `getBoundingClientRect`, and element dimension properties to verify exact presentation. These assertions synchronously query browser style or layout, duplicate CSS implementation details, and mix visual review with tests that otherwise cover authentication, application landmarks, game launch behavior, and workspace state.

The repository does not currently maintain screenshot baselines. Production styles and components already express the visual behavior, and this change must not alter that runtime behavior. The new boundary therefore removes weak presentation assertions without claiming replacement visual regression coverage.

## Goals / Non-Goals

**Goals:**

- Keep frontend tests centered on application logic and user-observable behavior.
- Remove direct computed-style and geometry assertions from existing frontend tests while preserving semantic, state, focus, and interaction coverage.
- Prevent the same assertion strategy from returning through a test-scoped ESLint rule.
- Preserve the existing Vitest unit and real-browser projects and repository command boundary.

**Non-Goals:**

- Change production Svelte markup, CSS, layout, or runtime browser behavior.
- Add screenshot baselines, a visual-regression service, Storybook, or another test dependency.
- Ban production code from measuring layout when measurement is required for application behavior.
- Replace presentation assertions with class-name, inline-style, CSS-variable, or DOM-shape assertions.

## Decisions

### Assert behavior at semantic boundaries

Tests that combine behavioral and visual checks will retain assertions for rendered content, roles, accessible names, enabled or disabled state, focus, state transitions, and user actions. Visual-only test cases or visual-only portions of mixed cases will be removed.

Alternative considered: retain geometry checks only in the real-browser project. A real browser makes the values accurate but does not make exact pixels, colors, or CSS properties a stable behavioral contract, and the reads still trigger style or layout work.

### Enforce the boundary in frontend test files

An ESLint override for `tests/**/*.test.ts` will use core `no-restricted-globals` and `no-restricted-properties` rules. It will reject direct `getComputedStyle`, rectangle methods, and width or height dimension properties used by the current presentation tests. The override remains test-scoped so production behavior is unaffected.

Alternative considered: rely only on written guidance. The global web-testing skill now documents the boundary, but a local lint failure gives contributors immediate, repository-specific feedback and prevents regression independently of which development tool creates a test.

### Defer screenshot infrastructure

When exact presentation is an explicit contract, focused screenshot comparison in a real browser is the appropriate verification layer. This change records that boundary but does not introduce baselines because the repository has not selected baseline storage, update workflow, operating-system and font normalization, or review ownership.

Alternative considered: convert every removed assertion into a screenshot. That would create broad snapshots with high review and maintenance cost before the repository has a visual-test strategy, and it would exceed the requested test cleanup.

## Risks / Trade-offs

- [Risk] Exact visual regressions previously caught by individual pixel or style assertions will no longer fail the test suite. -> Keep the production styles unchanged, preserve behavior coverage, and use focused screenshot comparison when visual regression infrastructure is deliberately introduced.
- [Risk] A broad property restriction could block legitimate behavioral tests. -> Restrict only direct computed-style, rectangle, and width or height dimension APIs in test files; leave production sources and semantic locator assertions unaffected.
- [Risk] Deleting mixed test sections could accidentally remove useful interaction coverage. -> Review each affected case and retain or split every assertion that verifies content, accessibility, state, focus, permissions, or interaction outcomes.

## Migration Plan

1. Add the test-scoped ESLint restrictions.
2. Refactor the four affected browser test files until the lint guard passes without suppression.
3. Run focused browser tests, frontend formatting, lint, type checking, and the complete frontend suite.
4. Roll back by reverting the ESLint override and test refactor; there is no data, API, or deployment migration.

## Open Questions

None.
