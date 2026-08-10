## Why

Frontend browser tests currently read computed styles and element geometry to verify colors, spacing, dimensions, alignment, overflow, and animation. Those checks force browser style and layout work, couple tests to implementation details, and still provide weaker presentation coverage than reviewed screenshots, so the suite should focus on application behavior instead.

Tracking issue: [#207](https://github.com/ravecat/d20/issues/207)

## What Changes

- Establish a behavior-first frontend test boundary that favors content, accessibility semantics, state transitions, permissions, focus, and interaction outcomes.
- Remove presentation-only assertions based on computed styles, bounding rectangles, and element dimension properties while retaining meaningful behavioral coverage.
- Add test-scoped ESLint restrictions that prevent direct presentation measurement APIs from returning to frontend tests.
- Route explicit visual contracts to focused real-browser screenshot comparison when visual regression infrastructure is in scope; this change does not add screenshot baselines.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `frontend-code-quality-tooling`: Extend frontend test quality enforcement with a behavior-first assertion boundary and lint restrictions for direct computed-style and geometry checks.

## Impact

- Affects `assets/eslint.config.mjs` and the focused browser tests for the app header, app layout, game detail activation, and workspace UI.
- Does not change production Svelte components, CSS, routes, public contracts, dependencies, session behavior, iframe behavior, or runtime compatibility.
- Rollback consists of reverting the test and lint changes; no data or deployment migration is required.
