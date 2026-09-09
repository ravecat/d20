## 1. Center compact tracks

- [x] 1.1 Update `assets/js/pages/home/ui/home.svelte` with responsive compact alignment, inert tail coverage, logical loop distance, and focus reset; preserve hero/singleton geometry and CSS-only motion.

## 2. Verify the delivered behavior

- [x] 2.1 Adapt the nearby inert-copy expectation and run `bun run test:unit -- tests/pages/home/ui/home.test.ts` and `bun run test:browser -- tests/pages/home/ui/home.browser.test.ts` from `assets/`, refreshing affected screenshots with runner update mode where required; verify canonical links, focus, singletons, and reduced motion without inspecting animation internals.
- [x] 2.2 Refresh and review affected home story baselines using `bun run test:visual -- stories/pages/public/home.stories.ts stories/pages/authenticated/home.stories.ts --update`, then rerun without update; confirm centered desktop/tablet/mobile composition and two-item coverage, and run `bun run format.check`, `bun run lint`, and `bun run typecheck` from `assets/`.
- [x] 2.3 Use the selected existing `http://localhost:5000/` DevTools page for a temporary exact CSS preview; inspect centered compact rows, symmetric clipping, unchanged hero, focus recovery, and running motion, then remove the preview. Record that this page serves the primary checkout and actual worktree rendering is covered by Vitest browser and screenshots; preserve the user's server and prepared page.

## 3. Reconcile delivery artifacts

- [x] 3.1 Record verification, synchronize the delta through the native OpenSpec archive workflow after implementation passes, run `openspec validate --all --strict --no-interactive`, and confirm `center-home-compact-carousels` no longer appears in `openspec list --json`.

## Original centering verification evidence

- Baseline: Home unit tests passed 9/9; existing Home browser tests passed 7 with one existing Firefox reduced-motion skip.
- Final component checks: Home unit tests passed 9/9 and Home browser tests passed 9 with the same one skip. New narrow Playable focus screenshots verify all three canonical links in Chromium and Firefox.
- Full frontend `bun run format.check` and `bun run lint` passed. Scoped Svelte validation reported no issues.
- Selected existing page: `http://localhost:5000/`, serving the primary checkout. A temporary preview used the exact worktree CSS compiled with the existing component scope and the matching inert tails; the original stylesheet and DOM were restored afterward. At a 708px carousel width, both middle cards had 0px center error and both neighbors were clipped by 38px. A narrow emulated viewport also retained centered cards and no page overflow. Natural advancement, shared Games movement, and first-link keyboard reveal were observed. No browser animation objects or playback controls were used.
- Browser console initially had no warnings/errors. Later it reported a `runtime.lastError` message-channel failure and unattributed promise messages; DevTools exposed no source or stack. Their source remains unconfirmed. Actual worktree component behavior is verified separately by the passing browser tests.
- Read-only review found no defects in loop fractions, two-item tail coverage, focus reset, singleton behavior, or accessibility exclusions.
- Final Home visual comparison passed all 48 scenarios across desktop, tablet, and mobile after updating 36 story baselines and one reduced-motion baseline; six Playable focus baselines were added. Empty, singleton, fallback, and existing Games-focus baselines remained unchanged. Both visual runs exited successfully with a Vite shutdown timeout warning after completion.
- `bun run typecheck` passed with no errors or warnings. Full strict OpenSpec validation passed all 83 pre-archive items, and `mix openspec.check` passed for 10 active changes.
- Native archival synchronized the new home-discovery requirement and moved this change to `archive/2026-09-09-center-home-compact-carousels/`. Post-archive strict validation passed all 82 items, lifecycle validation passed for nine remaining active changes, and the archived change is absent from `openspec list --json`.

## 4. Soften the existing motion

- [x] 4.1 Update the shared cycle in `assets/js/pages/home/ui/home.svelte` to `6.1s`, the stationary keyframe endpoint to `81.967213%`, and the slide interpolation to `ease-in-out`; preserve all centering, looping, pause, focus, and reduced-motion rules.
- [x] 4.2 Run `bun run test:unit -- tests/pages/home/ui/home.test.ts` and `bun run test:browser -- tests/pages/home/ui/home.browser.test.ts` from `assets/`, plus scoped formatting, lint, and Svelte checks using the existing toolchain. Do not add animation internals, timing, or geometry assertions. Existing static screenshot baselines should remain unchanged.
- [x] 4.3 Integrate the checked local follow-up into `master` and inspect its actual `http://localhost:5000/` page with DevTools. Observe the longer eased movement, stationary interval, shared Games progression, centered compact rows, hover pause, and focus recovery without a temporary style preview. Record the served source and results.
- [x] 4.4 Record follow-up verification, synchronize and archive this reactivated change, run `openspec validate --all --strict --no-interactive` and `mix openspec.check`, and confirm absence from `openspec list --json`. Fold the motion and reconciled artifacts into the existing centering commit and leave `master` serving the combined result.

## Motion follow-up status

The four-line CSS amendment is implemented. Focused Home unit/browser checks passed 18 tests with one existing Firefox reduced-motion skip. Scoped `bun x oxfmt --check js/pages/home/ui/home.svelte`, `bun x eslint js/pages/home/ui/home.svelte`, `bun run typecheck`, Svelte autofixer, and `git diff --check` passed. No tests or screenshot baselines changed. The same focused Home command also passed on integrated `master`: 18 tests with the existing skip. Actual served-page verification passed. The delivery closure synchronizes and archives this change before folding the checked amendment into the original local centering commit.


## Actual master-served motion verification

- DevTools reused only the existing `http://localhost:5000/` page. Its Vite stylesheet identified `/home/max/apps/d20/assets/js/pages/home/ui/home.svelte` and contained the new cycle, hold endpoint, and easing. No temporary CSS or DOM substitution was used.
- Read-only observation of natural playback over 27 seconds showed approximately 1.1-second movements and 5-second stationary intervals. Both Games rows progressed together, and the Playable sequence crossed its loop boundary. No animation objects or playback controls were used, and no automated timing assertions were added.
- At the settled desktop state, both compact viewports were 708px wide. Middle-card center error was below 0.01px, with 38px clipping on each side. The hero retained its full-width geometry.
- Hovering Games paused both tracks at the same held position. Leaving restored their running state. Keyboard Tab reached the first canonical Playable link, paused its track, cleared displacement, and fully revealed the card. Leaving focus restored centered running tracks.
- The selected page reported no console warnings or errors during this follow-up. Existing component checks cover reduced motion and singleton behavior; screenshot baselines remain unchanged by the timing amendment.

- Final native archival synchronized one added cadence requirement and the amended centering scenario. `openspec validate --all --strict --no-interactive` passed all 82 items, `mix openspec.check` passed for the nine remaining active changes, and `center-home-compact-carousels` is absent from `openspec list --json`. The reconciled artifacts accompany the local centering/motion completion commit.
