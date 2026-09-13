## Context

The shared `preview.css` currently suppresses all CSS animation, transition, and smooth-scroll behavior. Four Workspace `play` functions also cancel document animations. Both mechanisms run during interactive browsing. The installed stack is Storybook 10.5.7, Vitest 4.1.7, and the existing Playwright browser provider.

The standard pipeline already stabilizes automated captures: Storybook's portable story runner calls `pauseAnimations()` before its test lifecycle completes, and Vitest's Playwright screenshot defaults disable animations. The existing `afterEach` hook waits for fonts and captures the document with a 15-second stability timeout.

Public and authenticated Home defaults use `fourBrowseGames`. The existing collection split assigns `ceil(N / 4)` entries to the hero, so four entries produce one hero card and activate the production singleton animation guard. The existing deterministic `homeBrowseGames` fixture has 32 entries, producing eight hero cards and 24 compact cards without changing application logic.

## Goals / Non-Goals

**Goals:** Restore real CSS motion in component and page previews; make default public and authenticated Home stories demonstrate hero cycling with sufficient data; retain stable screenshots of story-defined states across the existing two themes and three viewports; describe the actual standard test pipeline.

**Non-Goals:** Production CSS changes, new animation frameworks or tests, dependency upgrades, test-only global CSS, custom animation interception, controlled intermediate-frame coverage, or eliminating Storybook's upstream completion wait.

## Decisions

1. Delete `assets/.storybook/preview.css` and its import, and remove only the four cancellation loops in `assets/stories/widgets/workspace.stories.ts`. Preserve fixtures, interactions, accessible assertions, and theme decorators. A test environment branch would duplicate standard stabilization and leave two motion policies to maintain.
2. Preserve `assets/.storybook/vitest.setup.ts`, screenshot defaults, and visual project configuration. Stories select a meaningful state through existing arguments and interactions; the standard Storybook/Vitest/Playwright pipeline handles capture stabilization. Do not describe this as exclusively a Playwright action at the instant of capture.
3. Update the existing Storybook contributor guidance and replace the authoritative no-motion requirement at completion. Keep dedicated production browser tests for animation and reduced motion unchanged. A stable screenshot does not verify animation progression or arbitrary JavaScript motion.
4. Review any baseline differences before updating only affected references. Cancellation and standard completion/pause handling can produce different frames; unexplained differences remain failures.
5. Replace `fourBrowseGames` with the existing `homeBrowseGames` in both Home metadata defaults. Preserve explicit empty, singleton, and favorites overrides, one-to-four-entry widget examples, and existing tests. Do not add fixtures or change production data, CSS, collection splitting, or pause conditions. Verify cycling with reduced motion disabled and the hero neither hovered nor focused; production hover, focus, and reduced-motion behavior remains expected.

References: [Vitest visual regression guidance](https://vitest.dev/guide/browser/visual-regression-testing), [Playwright screenshot animation handling](https://playwright.dev/docs/api/class-pageassertions#page-assertions-to-have-screenshot-1), and the installed Storybook preview API and portable-story runner.

## Risks / Trade-offs

- Storybook 10.5.7's interactive `waitForAnimations()` can wait for its five-second fallback on finite scroll timelines, including after a theme change. The user prioritizes real motion and the standard mechanism. Verify and document observed behavior; do not claim this delay is fixed or add an internal monkeypatch.
- Smooth scrolling and restored effects can alter captured states. Start with Home and Workspace visual tests, inspect actual/reference/diff images when needed, then run the complete six-instance visual suite without updates.
- Existing manual browser access might be unavailable. Record a concrete access blocker rather than substitute a different project's Storybook or claim a live review passed.

## Validation and Rollback

Run both public and authenticated Home story files across all six visual instances after the default-data change, review and refresh affected baselines, then rerun the full visual suite without updates. If the host cannot sustain the parallel matrix, invoke the existing `vitest` package script once per configured visual project with `--maxWorkers=1`, preserving all six instances and assertions without changing repository configuration. Retain Workspace coverage and rerun scoped formatting and lint checks, `typecheck`, and `storybook:build`. Use the available D20 Storybook browser surface to inspect hero cycling under normal motion conditions, Workspace motion, scrolling, and light/dark theme behavior. Existing tests and live review are sufficient; no synthetic tests of removed suppression code are required.

Reconcile and archive the change only after its recorded validation is complete, then run strict OpenSpec validation. No migration, deployment, or integration into the primary branch is required for this delivery. Roll back by reverting this change and its associated reviewed baselines.

## Open Questions

None blocking. The upstream interactive completion wait is an explicit accepted scope limitation, not a promised fix.
