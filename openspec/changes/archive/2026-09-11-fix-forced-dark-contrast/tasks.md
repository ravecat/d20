## 1. Shared CSS Delivery

- [x] 1.1 Configure Vite's LightningCSS transformer with targets derived from the existing Browserslist policy and explicit `Features.Nesting`; promote the locked `lightningcss` 1.32.0 to a direct development dependency and update the lockfile without unrelated upgrades. Disable redundant Svelte style preprocessing so Svelte lowers its own syntax before Vite processes emitted CSS.
- [x] 1.2 Add `crossorigin="anonymous"` to both PhoenixVite root asset calls, preserving current URLs, manifest resolution, and server CORS policy; cover the rendered stylesheet attributes for both layouts with focused tests.
- [x] 1.3 Inspect transformed development and production CSS for complete theme variables and lowered nesting; confirm explicit light, explicit dark, system preference, and current asset/HMR boundaries remain intact.

## 2. Contrast Audit and Representative Coverage

- [x] 2.1 Retest the reproduced game panels and header link after the shared correction, then audit all page/component families and relevant states listed in `design.md`; record failures and unchanged outcomes in this artifact.
- [x] 2.2 Correct only any remaining demonstrated contrast failures at their owning declarations, retaining the authored palette and correctly rendered mixtures otherwise; verify ordinary enabled text/link contrast and preserved focus/disabled behavior.
- [x] 2.3 Reuse or extend deterministic production-component stories for representative affected native light/dark game, shell/authentication, profile, and workspace states; keep interactions in `play` without duplicating existing UI scenarios.
- [x] 2.4 Run the existing desktop, tablet, and mobile screenshot projects for affected stories through `bun run test` or `bun run test:visual`; inspect affected baseline, actual, and available diff images, update only intentional references, and rerun normal comparisons.

## 3. Integrated and Command Validation

- [x] 3.1 Run `bun run test -- tests/pages/game/ui/game.test.ts tests/app/ui/header.browser.test.ts` from `assets/` and the smallest additionally affected suites; run the focused root-layout rendering tests with `mix test <test-path>` and format touched Elixir/HEEx files through the repository formatter.
- [x] 3.2 Run `bun run browsers` and `bun run browsers:target` from `assets/`, then `mix assets.format.check`, `mix assets.lint`, `mix typecheck`, and `mix assets.build`; verify both existing manifest entries and broaden to `just check` for this shared compilation and root-layout change.
- [x] 3.3 Use `devtools-validations` on the selected existing development page to verify the actual compiled candidate, anonymous-CORS CSSOM access, corrected game panels, interactive header, and wider audit under Dark Reader; record URL, theme/transformation, colors/contrast, screenshots, console outcome, and restore prepared browser state.

## 4. Native Theme and Viewport Matrix

- [x] 4.1 Replace the three repeated Storybook project configurations in `assets/vite.config.mjs` with six generated `visual-<theme>-<viewport>` Chromium projects from light/dark and desktop/tablet/mobile lists. Pass both values through `storybookTest.initialGlobals`, remove `groupOrder`, and retain sequential files and tests within each project.
- [x] 4.2 Add native screenshot and actual/diff resolvers for visual projects using the theme/viewport/browser hierarchy, preserving the existing unit/browser project configuration and browser reference paths. Update `test:visual` and existing workflow documentation for wildcard filters and the new hierarchy.
- [x] 4.3 Remove the 12 theme-only Dark story exports and any remaining theme overrides that defeat project selection. Preserve all 49 meaningful scenarios, including HeaderFocused, their fixtures and interactions, and the interactive theme toolbar.
- [x] 4.4 Migrate the 183 existing references unchanged and generate the 111 missing dark candidates through native `bun run test:visual`, obtaining all 294 Storybook references, review mapped prior references and paired native themes, and remove the obsolete viewport-first Storybook directories. Verify every retained scenario appears in all six cells and all 28 standalone browser references remain unchanged; limit subsequent intentional font reference updates to task 4.5.

- [x] 4.5 Replace the fallback font that lacks U+2264 with pinned Noto Sans Math 5.3.0 in shared application/Storybook CSS, verify actual WOFF2 coverage, and review the six MaximumOnly reference updates without comparison-tolerance changes.

- [x] 4.6 Pre-optimize `@inertiajs/core` in the existing browser project to prevent the reproduced late dependency optimization from reloading a running test after the lockfile change; preserve browser behavior and baseline paths.

## 5. Matrix Validation

- [x] 5.0 Isolate each generated project's Vite dependency cache after the Storybook addon applies its shared-config cache default; verify normal parallel execution without stalled browser initialization.

- [x] 5.1 Run the complete visual matrix without `--update`, either through `bun run test:visual` or the full frontend test command. Verify project wildcard selection, correct theme and viewport before interaction/capture, parallel project execution, sequential files/tests within each project, and no surviving theme-only scenarios or reference filenames. Complete the intentional two-project failure check for isolated actual/diff evidence, restore its references, and require the final normal run to pass.
- [x] 5.2 Run the existing unit/browser commands needed to verify their preserved behavior and references, then `bun run format.check`, `bun run lint`, `bun run typecheck`, and `bun run storybook:build` from `assets/`. Record command results and investigate failures without silently weakening capture, comparison, or project concurrency.

## 6. Reconcile Delivery

- [x] 6.1 Reconcile issue #278 and these artifacts with the delivered shared CSS correction, prior forced-dark audit evidence, completed matrix migration, reviewed references, commands, and remaining limitations; preserve issue #280 and unrelated active work ownership.
- [x] 6.2 After required validation passes, synchronize and archive this change with the native OpenSpec workflow, run `openspec validate --all --strict --no-interactive`, confirm it is absent from `openspec list --json`, and include the reconciled artifacts in the semantic completion commit.

## Prior Contrast Verification Record

The following evidence predates the matrix continuation. It records completed contrast work and earlier validation; final matrix evidence appears in the later record. Implementation and validation tasks 1 through 5 are complete. Issue and artifact reconciliation, final archive, and the completion commit are covered by tasks 6.1 and 6.2 and the final local delivery record.

Delivery is local to `worktree/forced-dark-contrast`, based on `caac3ad2`, and tracked by [issue #278](https://github.com/ravecat/d20/issues/278). No integration, publication, deployment, live authentication submission, interest mutation, or live session change is part of this delivery.

### CSS and asset delivery

- The production compiler consolidates the ten repeated base layers into one and lowers nested support rules, restoring externally transformed theme variables without changing their native light/dark values or selectors.
- Development output and production output retain explicit light, explicit dark, and system-preference selection. The existing JavaScript and CSS manifest entries remain present; Svelte global selectors and development virtual CSS imports remain valid.
- Paired separate-origin stylesheet trials establish that both transformed CSS and anonymous CORS are necessary. The candidate stylesheet exposes its CSS rules using the existing Vite response policy. Both Phoenix root rendering tests assert the CORS attribute and unchanged CSS, application-script, and HMR URLs.

### Browser audit

Initial reproduction used the existing selected browser page at `http://localhost:5000/`, `/games/477246`, and `/games/qwinto` with Dark Reader dynamic styles active, document `data-theme="light"`, stored `phx:theme=light`, and dark system preference. The actual development candidate stylesheet was substituted temporarily in that document, without changing source theme preferences or server routes.

The extension stopped being active during the later audit. Final repeatable checks used the official Dark Reader 4.9.130 website API, enabled only in the temporary inspected document with brightness/contrast 100 and sepia 0. This is recorded separately from the initial extension reproduction. Production component previews used the built Storybook at `http://localhost:6007/iframe.html`; the API and diagnostic server are temporary inspection tools and are not product dependencies.

| Area | Evidence and result |
| --- | --- |
| Game detail | Initial live extension reproduction and candidate CSS: unavailable and playable game panels are dark and readable; description contrast approximately 7.01:1 and metadata 6.56:1. Play, Lobby, interest, Requested, pending/error behavior additionally passes deterministic existing tests and native-theme stories. No game-page color patch is needed. |
| Header and shared navigation | Real pointer hover and keyboard Tab verify the D20 brand, including the compact header: 4.79:1 against `rgb(28, 30, 31)` with foreground `oklab(0.629058 0.000628152 0.00632546)`. Its keyboard underline remains visible. Native expanded/compact and authenticated header checks pass. |
| Home and information pages | Home/catalog, About, Contact, Rights holders, and Developers were inspected with actual candidate CSS and dynamic recoloring. Cards, headings, content, and footer remain readable. Final footer hover is 11.43:1. Current-page selectors remain present with lower specificity and explicit component colors preserved. Footer destinations absent from the router are not new pages to implement. |
| Authentication and account | Native light/dark stories plus final built previews under the API cover sign-in, account settings, confirmation, and registration completion. Provider hover originally remained at 4.15:1 in auth and 3.59:1 in account after compilation alone. The shared specificity correction raises them to 9.89:1 and 8.57:1; auth keyboard focus is 10.93:1. Linked/unlinked actions, fields, errors, success, and disabled/pending behavior retain existing presentation and tests. |
| Notifications | The built registration-success preview reproduced the remaining pale surface. Direct severity tokens restore dark surfaces while retaining native tints: info text 10.33:1, warning 9.95:1, error 10.24:1. The real info mailbox link is 5.35:1. Warning/error surface probes selected the existing severity classes; they did not submit real workflows. Error notifications currently render text and a primary-colored recovery button, not severity-colored anchors. |
| Workspace | Built deterministic reconnecting and failed previews remain readable under dynamic recoloring. The expanded Theater preview also retains visible close, compact, and fullscreen controls. Compact inversion, Theater, control focus, reconnection feedback, and disabled controls also pass the existing workspace story interactions and reviewed native states. No workspace palette changes are required. |

Browser screenshots inspected include `/tmp/d20-forced-dark-game-before.png`, `/tmp/d20-candidate-game-darkreader.png`, the four `/tmp/d20-candidate-<information-page>.png` captures, `/tmp/d20-production-auth-hover.png`, `/tmp/d20-production-account-forced.png`, confirmation/registration/workspace production-preview captures, `/tmp/d20-production-notification-fixed.png`, and `/tmp/d20-final-compact-header-hover.png`. These are temporary local audit captures; the reviewed native reference images are stored under `assets/__screenshots__/` as delivery artifacts.

The final built notification preview has no application console errors. The only warning comes from repeated Canvas2D readback in the temporary contrast-measurement script. The browser is restored to the original home route and scroll position with stored light theme unchanged; temporary scripts and stylesheet substitutions are removed by fresh navigation. User browser settings and unrelated tabs are preserved.

### Automated and native visual validation

Commands use repository scripts; Mix validation uses `CI=true nix develop --command ...`, with `MIX_TEST_PARTITION=contrast` for database tests.

- Baseline: game behavior 17 passing tests, game stories 12 passing cases, and focused controller coverage 60 passing tests before implementation.
- Final affected run from `assets/`: `bun run test -- stories/pages/public/game.stories.ts stories/pages/public/home.stories.ts stories/pages/authenticated/account_settings.stories.ts stories/widgets/workspace.stories.ts tests/pages/game/ui/game.test.ts tests/app/ui/header.browser.test.ts tests/pages/home/ui/home.browser.test.ts tests/pages/registration_completion/ui/registration_completion.test.ts tests/pages/auth_confirmation/ui/auth_confirmation.test.ts`: **19 files passed, 218 tests passed, 2 skipped**.
- Before the matrix continuation, nine additional stories produced 27 reviewed references across desktop `1280x720`, tablet `1024x640`, and mobile `320x900`: game activation dark states, header keyboard focus in both themes, sign-in dark, established account dark, and workspace connection statuses dark. All then-existing screenshot references remained unchanged. The new matrix supersedes the theme-only aliases and their path layout. Real pointer hover was checked with DevTools because synthetic story hover does not establish CSS `:hover` reliably.
- The first broad frontend run exposed carousel focus geometry changes caused by merging the independent translation reset. Baseline PostCSS and the equivalent final reset both pass the existing Chromium/Firefox focus comparisons. The final affected run includes these unchanged references. A separate 8-pixel MaximumOnly glyph difference did not reproduce in the focused player-count run, which passed all 12 cases without edits or baseline updates. The earlier broad run is not claimed as green.
- `mix test test/d20_web/components/layouts_test.exs`: **2 tests passed**. Touched layout/template formatting passes.
- `just check`: compilation and formatting passed and **899 backend tests passed**. It then stopped on three pre-existing Credo nesting findings in `lib/d20/koala_rescue_club/game.ex` at lines 250, 345, and 383. That file is identical to the base, blob `a060bb624dd76329d42a079d4ac3fdb6aa693db0`.
- Remaining broad checks run separately: `mix dialyzer` passed with the existing one ignored diagnostic and no unnecessary ignores; `mix ex_dna lib --max-clones 14` passed with 11 clones; `mix reach.check --arch --smells` passed.
- `bun run browsers` and `bun run browsers:target` resolve the shared policy (minimum target families: Chrome/Edge 121, Firefox 128, iOS/Safari 17.4, Opera 107). No independent support query is added.
- Final `mix assets.format.check`, `mix assets.lint`, `mix typecheck`, `mix assets.build`, and `mix assets.storybook` all pass. Type checking reports zero errors and warnings. Builds retain only the existing large-chunk advisory.
- Independent final diff review reports no outstanding findings.
- Before this continuation, `git diff --check` passed. OpenSpec synchronized five added shell requirements and one modified build-policy requirement, then archived this change as `2026-09-10-fix-forced-dark-contrast`; strict validation passed all 85 items. The archive and implementation remained uncommitted, so the earlier completion-commit claim was premature. This same change was reactivated for the authorized matrix work; its final lifecycle is tracked by tasks 6.1 and 6.2.

### Limits and ownership

This verifies the observed Dark Reader behavior and representative native browser states, not every browser extension configuration. Authentication and workspace edge states use deterministic production-component fixtures. Embedded third-party game documents and API reference renderers remain outside the shell correction. The unrelated Credo findings prevent a fully green aggregate `just check`; they do not arise from this diff. Favorites, discovery, footer layout/content, and other active changes retain their own delivery ownership.

## Matrix Implementation and Verification Record

### Configuration and reference migration

- The generated matrix contains `visual-light-desktop`, `visual-light-tablet`, `visual-light-mobile`, `visual-dark-desktop`, `visual-dark-tablet`, and `visual-dark-mobile`. Each project supplies theme and viewport through `storybookTest.initialGlobals` before the existing decorator, render, and interaction lifecycle. The shared native screenshot hook and comparison tolerances remain unchanged.
- The built Storybook index contains 49 meaningful stories after removing 12 theme-only Dark exports. The reference inventory contains 294 PNGs, exactly 49 in each theme/viewport cell, with no Dark alias filenames or obsolete viewport-first Storybook directories.
- All 183 prior Storybook references were migrated byte-identically before any intentional rendering update. The first normal matrix run generated 111 previously missing dark candidates and reported **180 passing and 114 failing tests**: the 111 missing-reference failures and three eight-pixel MaximumOnly mismatches in light projects. This initial candidate-generation run is not a passing validation result. Its machine-readable record is `/tmp/d20-matrix-first.json`.
- The first run's 78 story-file intervals overlap at a peak of six, establishing concurrent project progress. Each project's `fileParallelism: false` retains one story-file worker, and no concurrent story execution is introduced.
- The native default actual/diff paths omitted project identity, so concurrent matrix failures could overwrite their evidence. The visual `resolveDiffPath` now includes theme, viewport, and browser under `assets/.vitest-attachments/`, matching reference separation. An intentional two-project negative check produced exactly the two expected MaximumOnly mismatches in `visual-light-mobile` and `visual-dark-mobile`, with distinct theme/viewport actual and diff paths. All references were restored afterward. `/tmp/d20-matrix-diff-path-check.log` records the expected nonzero test result; it verifies failure evidence isolation, not a passing normal comparison.
- All 28 standalone browser references remain unchanged. Unit and browser environments, filters, browsers, viewports, mocks, and reference paths are retained; the browser project now pre-optimizes `@inertiajs/core` as recorded below. Their environment migration remains separately owned by [issue #280](https://github.com/ravecat/d20/issues/280).

### Deterministic mathematical glyph

- A focused repeat before the font correction passed the light MaximumOnly cases but failed all three dark cases by eight pixels: **21 passing and 3 failing tests**, recorded in `/tmp/d20-matrix-player-focused.log`. This reproduced variable rendering rather than a stable intended visual change.
- `fc-query` of the actual pinned fonts showed that both the primary Mono font and Symbols 2 math font omitted U+2264. The mathematical label therefore fell back to a host font despite successful declared-font loading.
- Shared production and Storybook CSS now imports `@fontsource/noto-sans-math/latin-400.css` from pinned version 5.3.0. Its actual WOFF2 charset covers U+2190 through U+2300, including U+2264. The explicit subset import also avoids the package index stylesheet's Unicode ranges excluding the mathematical character. The primary Mono font, label text, capture timing, and comparison thresholds remain unchanged.
- The native intentional update command `bun run test -- --project 'visual-*' stories/shared/player_count_label.stories.ts -t 'Maximum Only' --update` passed **6 tests with 18 unrelated cases skipped**, recorded in `/tmp/d20-matrix-glyph-update.log`. Only the six MaximumOnly references were intentionally updated; all other 180 prior Storybook references and all 28 standalone browser references retain their prior bytes. The later successful normal matrix comparison independently verified these accepted references.

### Validation status and known limits

- Frontend formatting, linting, type checking, and the static Storybook build passed before and after the font correction. The latest `mix assets.build` also passed. Formatting, linting, and type checking were repeated after the browser dependency optimization change and each exited 0; type checking reported zero errors and zero warnings. Targeted config formatting and ESLint checks also passed after the subsequent visual-cache isolation correction.
- The non-visual run before the font correction passed **187 tests with 2 skipped**. The later combined full frontend attempt in `/tmp/d20-matrix-final.log` was aborted after late `@inertiajs/core` optimization caused an unexpected test-page reload; its exit code was 130 and it is not passing validation evidence.
- The existing browser project now includes `@inertiajs/core` in startup dependency optimization. The following combined non-visual run had no late optimization reload. This change has been reviewed and preserves the established browser test boundaries.
- That combined non-visual run, `/tmp/d20-matrix-nonvisual-final.log`, completed **22 files and 187 tests with 2 skipped**, but exited **1** because a Phoenix reconnect timer raised `ReferenceError: location is not defined` after `tests/shared/stores/auth.test.ts` teardown. Review traced the side effect to the unchanged shared-store barrel importing a real socket at module load, independently of the visual matrix. This run is not a green validation result despite its passing test assertions.
- The isolated auth suite passed **5 tests**. A complete unit-only rerun with `bun run test -- --project unit` passed **79 tests in 12 files**, exited 0, and took 14.44 seconds. The separate final `bun run test:browser` passed **108 tests in 10 files with 2 skipped**, exited 0, and took 31.18 seconds; its record is `/tmp/d20-matrix-browser-final.log`. These independent runs complete task 5.2 while retaining the explicit combined-run limitation.
- The subsequent normal visual run in `/tmp/d20-matrix-visual-final.log` was aborted after approximately nine minutes with exit 130. Only two projects completed, accounting for 98 passing assertions; four remained idle before story execution. This run does not establish a passing full matrix.
- Inspection of the installed Storybook addon 10.5.7 found that its config hook derives the Vite cache path from the shared `configDir`, giving all six project servers the same mutable dependency cache. Together with the stalled startup, this strongly supports a cache-collision explanation; the exact browser network failure chain was not captured. The `visual-project-cache` plugin now runs with `enforce: "post"` and assigns `.vitest/cache/<project-name>` independently for each visual project.
- Distinct ignored `deps/_metadata.json` files confirm that all six projects resolve separate caches. During the replacement normal run, fresh trace writes and story progress were visible in all six projects, with no other Vitest process running. No comparator, tolerance, capture, or project-order change accompanied cache isolation.
- Final normal matrix command: `bun run test:visual -- --reporter=default --reporter=json --outputFile.json=/tmp/d20-matrix-isolated-cache.json`. It passed **78 files and 294 tests with zero failures**, exited **0**, and took **947.32 seconds**. `/tmp/d20-matrix-isolated-cache.log` records the run and the JSON report has `success: true`; its story-file intervals overlap at a peak of six. This completes tasks 5.0 and 5.1 against the reviewed references, including all six MaximumOnly cases.
- The final visual process printed the existing ten-second shutdown warning after writing the successful report, then exited 0. The warning was also observed in baseline runs before these changes; it does not change the verified assertion or exit results and remains a runner shutdown limitation.
- Review identified an existing screenshot coverage gap, separately tracked by [issue #281](https://github.com/ravecat/d20/issues/281): the old light and new dark EightPlayable desktop captures measure `1280x824` but become blank below the `720`-pixel iframe viewport; ImageMetadata tablet captures measure `1024x704` but become blank below `640`. The unchanged native capture currently does not prove complete below-viewport document coverage. This matrix migration preserves that capture behavior and does not weaken the existing whole-document specification; resolving the iframe clipping requires the separately tracked correction.
- Normal visual validation, independent unit/browser validation, and isolated failure-evidence verification are complete. Delivery reconciliation includes authoritative specification synchronization, native archive, strict validation, issue #278, and the local semantic completion commit. Final lifecycle results are recorded below. The unchanged Phoenix teardown side effect and earlier pre-existing Credo limitation prevent claiming a fully green combined aggregate run.

### Final local delivery reconciliation

- Native `openspec archive fix-forced-dark-contrast --yes` synchronized the three owning specifications and archived the completed change as `2026-09-11-fix-forced-dark-contrast`. The authoritative visual specification purpose now describes both themes and all three viewports.
- `openspec validate --all --strict --no-interactive` passed **85 items with zero failures**. `openspec list --json` confirms this change is no longer active.
- Final inventory verifies 294 Storybook references, 49 per matrix cell, with every image matching its configured width. All 28 standalone browser reference hashes are unchanged. `git diff --check` passes.
- Issue #278 records the delivered matrix, prior contrast evidence, verification commands, and remaining limits. Issue #280 retains the separate browser migration; issue #281 owns the existing iframe clipping correction.
- Implementation, reviewed references, and reconciled artifacts are split into two related local commits for review: stylesheet contrast first, then the visual environment and references. No push, integration, or deployment is part of this delivery.

### Review history split

- The user requested two related commits in the existing worktree. The first contains CSS compilation, contrast declarations, root stylesheet loading, layout tests, and corresponding contracts. The second contains the visual matrix, stories, reference migration, the shared mathematical glyph needed by its six references, and final delivery reconciliation.
- Shared configuration and dependency files were staged by intent. The first commit retains the original viewport projects and Symbols 2 font; the second introduces the matrix and Math font together with their reviewed references.
- Three automatic failure captures under `assets/tests/pages/home/ui/__screenshots__/` were accidentally included in the original combined commit. Diagnostic copies are retained outside the repository; the generated paths are now ignored. They are not reference baselines.
- The split preserves all executable source and all 322 authoritative reference images from the verified combined tree. Validation checks staged syntax, blob identity, ignored failure paths, strict OpenSpec validation, and clean Git state; the previously passing runtime suites remain the applicable execution evidence.
