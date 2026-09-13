## Why

Frontend validation can spend minutes running the complete Vitest unit, browser, and six-cell Storybook visual matrix, while even a small passing visual file has exhibited a 10-second shutdown timeout. Contributors need an evidence-based strategy to minimize this feedback time on the existing machine, preserve meaningful coverage, and retain one native command surface.

## What Changes

- Record the historical timing audit, its failing-run and concurrency limitations, and the distinction between measured savings, conditional arithmetic, and unmeasured hypotheses.
- Specify a controlled evaluation of trace recording, screenshot timeout cleanup, browser isolation, visual project consolidation, concurrency, font readiness, repeated story and accessibility work, and lower-priority unit or cache changes.
- Describe automatic dependency-graph selection, native watch mode, and the requested affected-tests-or-full fallback without adding aliases, wrappers, manually curated test lists, or unsupported Vitest behavior.
- Preserve Chromium and Firefox behavior checks, all light/dark by desktop/tablet/mobile visual states, reviewed references, and semantic and accessibility coverage when evaluating candidates.
- Record the missing release test gate and require an unfiltered full-suite gate before any future reduced development policy is treated as sufficient for delivery.
- Define adoption, rollback, and specification reconciliation gates. This delivery creates planning artifacts only; experiments and implementation require a separate request.

## Capabilities

### New Capabilities

- `frontend-test-performance`: Evidence, coverage, command, and adoption requirements for evaluating frontend test acceleration with the same or minimally changed environment.

### Modified Capabilities

None in this planning delivery. Some candidates would change requirements in `storybook-visual-regression` or `project-command-interface`; the owning deltas must be expanded before a selected candidate is implemented. Recording an option does not select it or alter the current command, font, trace, isolation, or visual project behavior.

## Impact

- Tracking: [D20 issue #282](https://github.com/ravecat/d20/issues/282), in the D20 GitHub Project.
- Planning home: `openspec/changes/evaluate-vitest-performance-strategies/`, authored on `worktree/vitest-performance-strategy` from committed base `577c5c34ed1fa5dbb873f90c99b3e747d2cfb0ee`. The dirty favorites worktree that produced the historical measurements remains separately owned.
- Future candidate owners: `assets/vite.config.mjs`, `assets/.storybook/vitest.setup.ts`, Storybook setup and stories, `assets/package.json` and `assets/bun.lock`, and `.github/workflows/release.yml`. Existing `mix assets.test`, `just check`, and package scripts define the command boundaries.
- Related work: [issue #280](https://github.com/ravecat/d20/issues/280) covers the separate browser-test migration option; this strategy does not silently take over or duplicate its implementation.
- No current writes to source, tests, references, dependencies, CI, runtime configuration, or backend behavior. No database migration, session/runtime compatibility change, or iframe contract change is involved. Future changes must be independently reversible and must preserve diagnostic and failure semantics.
