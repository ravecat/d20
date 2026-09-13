## Why

Frontend validation can spend minutes running the complete Vitest unit, browser, and six-cell Storybook visual matrix, while even a small passing visual file has exhibited a 10-second shutdown timeout. Contributors need an evidence-based strategy to minimize this feedback time on the existing machine, preserve meaningful coverage, and retain one native command surface.

## What Changes

- Record the historical timing audit, its failing-run and concurrency limitations, and the distinction between measured savings, conditional arithmetic, and unmeasured hypotheses.
- Specify a controlled evaluation of trace recording, screenshot timeout cleanup, browser isolation, visual project consolidation, concurrency, font readiness, repeated story and accessibility work, and lower-priority unit or cache changes.
- Describe automatic dependency-graph selection, native watch mode, and the requested affected-tests-or-full fallback without adding aliases, wrappers, manually curated test lists, or unsupported Vitest behavior.
- Preserve Chromium and Firefox behavior checks, all light/dark by desktop/tablet/mobile visual states, reviewed references, and semantic and accessibility coverage when evaluating candidates.
- Record the missing release test gate and require an unfiltered full-suite gate before any future reduced development policy is treated as sufficient for delivery.
- Define adoption, rollback, and specification reconciliation gates. Following the autonomous sweep and review corrections, the user authorizes two semantic commits and local integration into `master`: first the trusted fullscreen story prerequisite, then the Vitest environment optimization and its finalized delivery records. No publication is requested.
- Restrict candidate changes to documented configuration, CLI flags, and public APIs of the tools. Dependency patches, forks, monkey-patching, and private internal APIs are excluded even when their installation mechanism is documented.
- Record screenshot timeout cleanup as measured but rejected because its implementation modifies Vitest internals. Restore the original dependency; revisit this direction only through a verified supported upstream release or public API.
- Correct the Workspace fullscreen story to use a trusted native browser click in the Vitest visual project through its explicit public environment marker if the activation probe confirms the trace-dependent synthetic-click defect; preserve ordinary Storybook, production behavior and every assertion.
- Keep research iterations scoped to a small passing file/project for fast feedback. Do not repeat the full suite per candidate; reserve broad validation for the eventual selected combination before final delivery.

## Capabilities

### New Capabilities

- `frontend-test-performance`: Evidence, coverage, command, and adoption requirements for evaluating frontend test acceleration with the same or minimally changed environment.

### Modified Capabilities

- `storybook-visual-regression`: retain routine traces off with focused diagnostic tracing, one inline Storybook project with six named browser instances and public per-instance globals, and two isolated visual files per instance in a separate native sequence group. The trusted fullscreen story prerequisite preserves browser activation, existing assertions and references. Font loading and default isolation remain unchanged.

The native unfiltered command contract remains unchanged.

## Impact

- Tracking: [D20 issue #282](https://github.com/ravecat/d20/issues/282), in the D20 GitHub Project.
- Archived planning record: `openspec/changes/archive/2026-09-13-evaluate-vitest-performance-strategies/`, originally authored on `worktree/vitest-performance-strategy` from committed base `577c5c34ed1fa5dbb873f90c99b3e747d2cfb0ee`. The dirty favorites worktree that produced the historical measurements remains separately owned.
- Delivered implementation owners: `assets/vite.config.mjs`, `assets/.storybook/vitest.setup.ts`, `assets/.storybook/svelte-docs-preview.d.ts`, and `assets/stories/widgets/workspace.stories.ts`. Existing `mix assets.test`, `just check`, and package scripts define the unchanged command boundaries. Package/lock manifests, unit settings, fonts and release CI remain unchanged; their screened or deferred candidates are recorded in the experiment ledger.
- Related work: [issue #280](https://github.com/ravecat/d20/issues/280) covers the separate browser-test migration option; this strategy does not silently take over or duplicate its implementation.
- The first candidate is rejected and its package, lockfile, and patch changes are rolled back. Retain its measurements and rejection reason in these delivery records. Future candidate changes must use documented settings, CLI flags, or public APIs and remain independently reversible. Production behavior, references, CI, backend behavior, database, session/runtime, and iframe contracts remain outside this experiment.
