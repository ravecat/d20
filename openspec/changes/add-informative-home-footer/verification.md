# Local Implementation Evidence

Updated: 2026-09-07. Owner: #268. Worktree: `worktree/informative-home-footer`.

## Implemented locally

- Every App-layout page uses one shared footer composition. Compact/informative selection and page-level footer configuration are removed; existing narrow/wide shell geometry only controls alignment.
- The footer starts directly with Explore and Help, without a repeated D20 brand/tagline introduction. Storybook exposes only Default and Mobile expanded under Widgets/Footer; the ordinary Home stories cover page integration.
- Explore and Help use the same link nodes in desktop columns and independent mobile disclosures at 48rem. Privacy and Terms stay outside disclosures.
- Breakpoint changes reset mobile state, preserve focused links, and transfer focused triggers to desktop headings and back. Same-mode resizing preserves state.
- Unenhanced markup exposes every link; the implementation has no disclosure animation, remote content fetch, storage persistence, or social integration.
- `/about` uses the existing public Inertia boundary and factual product copy, one reading column, and the same shared footer. Guest and authenticated route tests preserve authentication behavior.
- The `site-footer` block name avoids a confirmed collision with daisyUI's global `.footer` child-grid styles. Screenshots were inspected after the correction.
- The Home page component, catalog props, workspace implementation, game behavior, and other worktrees are unchanged.

## Initial implementation verification

Historical evidence below predates the September 7 simplification. Removed modes and story URLs describe that earlier revision, not the current implementation.

- Baseline: 2 existing Layout unit tests and the existing Developers route test passed before their respective changes.
- Footer browser suite: 26 checks passed across Chromium and Firefox. Covers exact link contracts, 320/390/767/768/769 widths, independent toggles, ARIA controls, hidden-link exclusion, focus transitions, keyboard activation, no fetch/navigation on toggles, and unavailable-enhancement fallback. Closing a group also restores focus when activation does not natively move focus away from a child link.
- Page controller suite: 39 tests passed, including both new About access cases and existing routes. The initial development-dependency compilation was interrupted by SIGTERM; the subsequent run completed successfully.
- Focused unit suite: 9 tests passed for App layout selection, About copy/links, and matching Storybook page context.
- `mix assets.format.check`, `mix assets.lint`, `mix typecheck`, and `mix assets.build` passed. The build retains the existing large-bundle advisory; no bundle-policy change was introduced.
- Updated visual references: all 54 story cases passed a normal comparison run across the existing desktop/tablet/mobile presets, including informative and narrow/wide compact footers, both themes, open mobile groups, focus, About, public/authenticated Home, and empty Home.
- The full frontend run exposed expected compact-footer screenshot changes on account/confirmation/registration pages and the existing layout browser fixtures. Only those affected baselines were updated. An isolated Player Count glyph comparison failed once and passed all 12 cases on an unchanged rerun; its component and references remain untouched.
- Final `mix assets.test`: all 263 tests in 50 files passed after the affected references were reviewed and updated. Final frontend formatting, lint, type checks, and production asset build also passed. This includes the new close-with-focused-link regression coverage.
- Full-document Storybook captures of content taller than the viewport include blank area beyond the visible viewport. These are not evidence that lower page sections were visually reviewed; direct scrolling/manual inspection remains pending.
- `just check` was retried through `nix shell --inputs-from . nixpkgs#just --command just check` because Just was absent from PATH. All 792 backend tests passed, but the gate stopped at three existing Credo nesting violations in `lib/d20/koala_rescue_club/game.ex` at lines 250, 345, and 383. Its Git blob is identical to HEAD (`a060bb624dd76329d42a079d4ac3fdb6aa693db0`). Later broad-gate steps did not run.
- `mix openspec.check` passed for 9 active changes; `openspec validate --all --strict --no-interactive` passed all 80 items. The footer change intentionally remains active.

## Review refinement on 2026-09-06

- Isolated stories moved from `App/Footer` to `Widgets/Footer`, including their existing visual references. Runtime ownership remains in App UI; this is a Storybook navigation change, not a new widget slice.
- The informative footer now uses Home's `--color-base-100` surface, preserving light/dark themes. Desktop columns are capped at 12rem each with a 1rem gap; block spacing and link padding follow the tightened layout reference. Mobile disclosure triggers and links retain their 44px minimum height.
- The footer link is now `About` at `/about`; the About page title and copy are unchanged.
- Public and signed-in Home previews assert exactly one informative footer from the actual Home layout selection. The new `home--footer` story scrolls to that footer without duplicating the component. Review URLs are `http://localhost:6100/?path=/story/widgets-footer--informative` and `http://localhost:6100/?path=/story/home--footer`; both entries were verified in the running Storybook index.
- `bun run test:unit -- tests/app/layout.test.ts tests/stories/page_layout.test.ts`: 8 tests passed. `bun run test:browser -- tests/app/ui/footer.browser.test.ts`: 26 Chromium/Firefox checks passed with the revised About label.
- `bun run lint`, `bun run typecheck`, `bun run format.check`, and `mix assets.build` passed. No dependency, runtime configuration, backend, or other worktree changes were needed for this refinement. The build's existing bundle-size advisory remains.
- `bun run test:visual -- stories/widgets/footer.stories.ts stories/pages/public/home.stories.ts stories/pages/authenticated/home.stories.ts --update` passed 51 cases across desktop, tablet, and mobile. Desktop/tablet light, desktop dark, mobile expanded, and desktop/mobile full Home screenshots were inspected. The same command without `--update` then passed all 51 visual comparisons. The earlier full-suite counts above predate this refinement.
- No matching Storybook page was available in the connected Chrome session. The user was asked to open `http://localhost:6100/?path=/story/home--index`; unrelated tabs and the carousel server on port 5000 were left untouched. Screenshot review and automated tests do not claim completion of the remaining manual DevTools matrix.

## Simplification on 2026-09-07

- Removed compact/informative selection from Footer, Layout, Home, and Storybook decorators. Layout, Home's module exports, and the layout decorator now match their original shared-shell contracts; narrow/wide still controls alignment only.
- Removed the repeated D20 brand/tagline introduction. Every App-layout page renders the same Explore/Help directory and legal strip; mobile disclosures and focus behavior remain intact.
- Reduced eight isolated footer stories to Default and Mobile expanded under Widgets/Footer. Theme and viewport are existing toolbar controls, not separate stories. Removed the redundant footer-focused Home story; ordinary public/authenticated Home stories assert integration.
- Verified the running Storybook index contains exactly `widgets-footer--default` and `widgets-footer--mobile-expanded`. Preview URLs are `http://localhost:6100/?path=/story/widgets-footer--default` and `http://localhost:6100/?path=/story/widgets-footer--mobile-expanded`; the ordinary Home preview remains `http://localhost:6100/?path=/story/home--index`.
- `bun run test:unit -- tests/app/layout.test.ts tests/stories/page_layout.test.ts`: 8 tests passed. `bun run test:browser -- tests/app/ui/footer.browser.test.ts`: 26 Chromium/Firefox checks passed, including identical link content under both shell widths and the absent introduction.
- `bun run test:browser -- tests/app/layout.browser.test.ts --update`: 6 checks passed with affected page references updated. `bun run test:visual -- stories/widgets/footer.stories.ts stories/pages --update`: 57 cases passed across the existing three viewport presets. Inspected desktop Default, mobile Mobile expanded, and full desktop Home references; the footer is visible and aligned with Home's content.
- Old generated references for removed footer stories were moved recoverably to `/tmp/d20-footer-story-cleanup.COc9BE`, including the three removed Home footer-story images. Only references affected by the shared footer were updated; Workspace and Player Count sources/references remain unchanged.
- `bun run lint`, `bun run typecheck`, `bun run format.check`, and `mix assets.build` passed. The existing large-bundle advisory remains. No backend, dependency, runtime configuration, or other worktree edits were needed for this simplification.
- Final `mix assets.test` passed all 245 tests in 50 files without updating references, including full frontend unit/browser coverage and normal story screenshot comparisons. This supersedes the earlier revision's frontend counts.
- `mix openspec.check`, `openspec validate --all --strict --no-interactive`, and `git diff --check` passed after reconciliation. All 80 specification items remain valid; this change remains active because the publication and manual verification gates below are still open.
- No matching Storybook tab was open in connected Chrome. The user was asked to open the Default preview; unrelated tabs and the carousel server on port 5000 were left untouched. Automated tests and screenshot inspection do not close the remaining manual DevTools matrix.

## Not ready for publication

`/help`, `/contact`, `/privacy`, and `/terms` are not implemented by this local increment. The footer's corresponding links remain part of the required final contract, not accepted working destinations. Do not merge/deploy this increment as a completed footer release.

- #247 is open: the deletion action, security/retention decisions, and usable public instructions are not supplied. No fictitious deletion action or unfinished answer has been rendered.
- #248 is open: approved Privacy/Terms, actual operator identity, monitored private support address, processing/retention decisions, and revision dates are missing. The user was asked for these inputs.
- Publication, anonymous production document GETs, real deletion verification, and #249 Meta handoff remain unperformed.
- DevTools inspection requires the user to open the footer worktree's preview. The existing `http://localhost:5000/` belongs to the separate carousel worktree and was not navigated or modified. An isolated Storybook preview was started at `http://localhost:6100/`; no existing matching tab was available at selection time.
- Manual zoom, safe-area/Workspace overlap, reduced-motion settings, and supplementary viewport review remain pending. Automated responsive assertions are not a substitute for this evidence.

The OpenSpec change and #268 stay open, with 6 of 26 tasks checked and the Project item in In Progress. Checkbox groups that include missing pages or manual/production evidence stay unchecked even where their footer-only portion is implemented. Implementation changes remain uncommitted in the owning worktree; no branch integration, push, deployment, or Meta dashboard mutation was performed. The worktree and isolated Storybook preview are retained for continuation.

## Legal-row and rights-holder review increment

- Removed only the copyright font-size override and the <=48rem forced column from `footer.svelte`. Copyright and legal links now inherit identical typography; existing flex wrapping handles content pressure. Directory disclosures are unchanged.
- Added deterministic footer screenshots at 320px and 446px (single line) and 220px (content-pressure wrapping), in Chromium and Firefox. Focused browser run passed 32 tests, including normal comparisons after baseline generation. The two existing Widgets/Footer stories passed 6 normal visual comparisons after their six references were refreshed. Existing shared-page references elsewhere were not regenerated in this narrow increment and may need reconciliation in the owning delivery's broad visual run.
- Focused ESLint and oxfmt passed; frontend typecheck reported 0 errors and 0 warnings.
- DevTools reused the existing `http://localhost:6100/?path=/story/widgets-footer--default&globals=viewport.value:mobile` page, backed by this worktree's Storybook process. Verified at 320px and 446px; reviewed `/tmp/d20-footer-446.png`. Computed copyright, Privacy and Terms all use `13px / 19.5px "Noto Sans Mono Variable", "Noto Sans Symbols 2", monospace`. No console warnings/errors. Restored the original story URL/mobile viewport; unrelated tabs were untouched.
- The requested exact label is `For Publishers and Rightholders`; owning issue #268 and specs record `/rights-holders` and both game-proposal/rights-concern scenarios. Runtime replacement remains pending by supervisor direction because no useful public page or confirmed monitored contact exists. Games remains unchanged in runtime rather than introducing a 404. No page, invented contact, route, catalog, or legal text was added.
- Existing dirty work was preserved; no files staged, commit, push, integration, deployment or archive performed. Delivery and external publication gates remain open.


## Footer component consolidation on 2026-09-07

- Moved directory data, markup, styles, and disclosure state into `assets/js/app/ui/footer.svelte`; removed the single-use `footer_group.svelte`. Runtime ownership remains in App UI with the existing Widgets/Footer previews.
- One matchMedia subscription now handles both groups. CSS controls heading/button visibility from the shared mobile class, after focus is captured, and rotates one static chevron path from `aria-expanded`. Shared link styles replace duplicate group styling. Native buttons, anchors, and the hidden attribute retain keyboard activation and collapsed-link semantics.
- `bun run test:browser -- tests/app/ui/footer.browser.test.ts`: 32 Chromium/Firefox tests passed, including independent toggles, 768/769 boundary transitions, focused links/headings, pointer-focus fallback, and enhancement failure.
- `bun run test:unit -- tests/app/layout.test.ts tests/stories/page_layout.test.ts`: 8 tests passed. `bun run test:visual -- stories/widgets/footer.stories.ts`: 6 normal screenshot comparisons passed across desktop, tablet, and mobile without updating references.
- Scoped `bunx --no-install eslint js/app/ui/footer.svelte`, `bunx --no-install oxfmt --check js/app/ui/footer.svelte`, and `bun run typecheck` passed; svelte-check reported no errors or warnings.
- DevTools initially had no matching preview tab; the user was asked to open the existing preview. A subsequent attempt could not connect to Chrome at port 9222. No unrelated tab was navigated, and manual DevTools verification remains pending.
- This review increment remains uncommitted with the owning delivery. Existing content, manual-review, and publication gates remain open, so #268 and its OpenSpec change are not closed or archived.


## CSS responsive presentation and shorter classes on 2026-09-07

- Removed the reactive mobile flag and mobile CSS class. The existing viewport media query now selects heading/button presentation. `footer--enhanced` is independent of width and only enables working disclosure controls; initial state keeps all links readable. The single matchMedia listener synchronizes open state and focus, not presentation classes.
- Replaced `site-footer` class prefixes with `footer`. The root uses a scoped `footer` element selector, avoiding DaisyUI's existing global `.footer` component rules. All markup, styles, and state remain in `footer.svelte`.
- The first direct media-query conversion reproduced focus loss in Chromium and Firefox: CSS hid the active trigger before the matchMedia callback captured focus. A `:focus` display rule retains that trigger until the callback transfers focus to its heading. DOM binding arrays are reactive to avoid Svelte binding warnings.
- Final `bun run test:browser -- tests/app/ui/footer.browser.test.ts` passed all 32 Chromium/Firefox checks without those warnings. Scoped ESLint, oxfmt checking, and `bun run typecheck` passed with no errors or warnings.
- DevTools could not connect to the existing Chrome instance at port 9222; the previous request to open the prepared preview remains unresolved. No unrelated tab was opened or changed. Existing publication/manual-review gates remain open and this refinement is uncommitted.
- Final visual comparisons passed all 6 Widgets/Footer cases without reference updates; the two focused layout/unit files passed all 8 tests. Strict OpenSpec validation passed all 80 items; `git diff --check` passed.


## Single CSS breakpoint on 2026-09-07

- Removed `matchMedia` and its API-availability guard. The 48rem threshold now appears only in CSS. The directory uses native Flexbox: capped equal groups in a row on desktop and full-width groups in a column on mobile, with the same spacing and link geometry.
- A single ResizeObserver reads the directory's computed `flex-direction` and updates disclosure state/focus only when that mode changes. Initialization runs synchronously before exposing controls, avoiding a first-click race. The existing focus guard and Svelte tick remain for the required focus handoff. All behavior stays in `footer.svelte`.
- Replaced the obsolete matchMedia-unavailability fallback test with a real-browser check that mobile toggling, desktop links and focus transfer work when matchMedia is absent. Added a local ResizeObserver stub to the existing jsdom layout test, where browser layout observation is unavailable; runtime code has no compatibility shim.
- `bun run test:browser -- tests/app/ui/footer.browser.test.ts`: 32 Chromium/Firefox tests passed. `bun run test:visual -- stories/widgets/footer.stories.ts`: 6 unchanged visual comparisons passed. The two focused layout/unit files passed all 8 tests.
- Compiled Footer with Svelte's server compiler and rendered initial HTML without executing client hooks: all 8 anchors and 2 lists are present, neither list is hidden, and there is no enhancement class or client script. This characterizes the component fallback; it does not claim the application has gained server rendering.
- Scoped ESLint and formatting passed for the component and touched tests; `bun run typecheck` reported no errors or warnings. DevTools still cannot connect to Chrome at port 9222. No unrelated browser page was opened or changed.
- Changes remain uncommitted in the same delivery; existing public-content, manual-review and publication gates remain open. No archive, commit, integration, or deployment was performed.
- Full `bun run test:unit` passed all 82 tests in 14 files.


## Native disclosures without synchronization on 2026-09-07

- The user explicitly accepted omitting automatic focus handling to prioritize simple native behavior. Replaced reactive disclosure state, layout reads, observers, media-query APIs, mount hooks and focus calls with mobile `details`/`summary` and CSS-selected static desktop lists. Both representations use one link inventory and one local template in `footer.svelte`; only one set is accessible at a time. Mobile open state now survives width changes while mounted instead of resetting.
- Removed the temporary ResizeObserver stub from the jsdom layout test and replaced obsolete focus/state-reset tests with native open-state and unique-accessible-link checks. The jsdom test checks both rendered link targets; actual CSS visibility is verified in browser tests. The existing Mobile expanded story activates visible heading labels inside summary. Native expanded state is asserted through `details.open`, not manually assigned ARIA attributes.
- `bun run test:browser -- tests/app/ui/footer.browser.test.ts`: 24 Chromium/Firefox tests passed. `bun run test:unit`: all 82 tests in 14 files passed. Scoped ESLint/oxfmt and frontend typecheck passed with no errors or warnings.
- Separately compiled the component with Svelte's server compiler and supplied its markup and CSS to Playwright Chromium and Firefox contexts with `javaScriptEnabled: false`. Native Enter/Space toggling, desktop's 8 unique accessible links, and retained open state across viewport changes passed in both engines. This verifies disclosure behavior from markup without client hooks; it does not add application SSR.
- Reviewed actual and reference mobile-expanded screenshots. Geometry and content are unchanged; native activation no longer leaves the former synthetic button-focus outline after the story's click. Updated only affected Mobile expanded references across the three presets; Default comparisons already passed. The update run passed all 6 cases.
- DevTools remains unavailable because Chrome cannot be reached on port 9222; no unrelated tab was opened or modified. The existing manual-review and public-content/publication gates remain open. This local increment is uncommitted and does not close or archive the broader delivery.
- Final normal visual run passed all 6 cases without updating references.


## Inline footer list markup on 2026-09-07

- Removed the local `linkList` snippet, then completed the requested inlining by replacing the group array, link loops, and `clientNavigation` flag with two explicit Explore and Help navigation blocks. Each representation contains literal links. Applicable anchors use bare `use:inertia`, which reads their href from the anchor; Help/FAQ and legal links remain ordinary anchors. CSS and native disclosure behavior are unchanged.
- Repeated the focused checks below after this final static-markup refinement; all passed without changing tests or screenshot references.
- `bun run test:browser -- tests/app/ui/footer.browser.test.ts` passed all 24 Chromium/Firefox checks. `bun run test:visual -- stories/widgets/footer.stories.ts` passed all 6 comparisons without reference updates. Scoped ESLint/oxfmt and `bun run typecheck` passed with no errors or warnings.
- This local refinement remains uncommitted with the same delivery; existing manual-review and public-content/publication gates remain open.


## Layout test simplification on 2026-09-07

- Removed `assets/tests/app/layout.test.ts`, including checks for page layout exports and duplicate developer-link assertions. Existing Storybook Home screenshots cover shell presentation, and footer browser tests cover link targets.
- Retained the nonvisual contracts in the existing layout browser scrolling scenario: main is not an Inertia scroll region and can actually receive programmatic focus. The latter replaces the unit assertion about its tabindex attribute. No application code changed in this refinement.
- The first verification exposed stale screenshot references from earlier footer refinements. Reviewed before/after images: seven Home references differ only in footer copyright typography or the mobile legal-row layout; the compact mobile browser reference adds 13 pixels of blank space. Refreshed only those eight references and preserved existing staged state.
- Final `bun run test:browser -- tests/app/layout.browser.test.ts tests/app/ui/footer.browser.test.ts` passed all 30 Chromium/Firefox checks. `bun run test:visual -- stories/pages/public/home.stories.ts stories/pages/authenticated/home.stories.ts -t "Index|Empty"` passed all 9 selected Home comparisons without updating references. Scoped ESLint/oxfmt and `bun run typecheck` passed with no errors or warnings.
- This refinement remains uncommitted with the owning delivery. Existing public-content, manual-review, and publication gates remain open.


## Approved support and rights addresses on 2026-09-07

- The user supplied `support@d20.ravecat.io` for support/feedback and `rights@d20.ravecat.io` for game proposals/rights concerns, explicitly authorizing preparation while provisioning is in progress. Used the existing ASCII production domain and stated the visually similar Cyrillic-character correction in the working update. No mailbox, DNS, forwarding, deployment, or email-send operation was performed.
- Added anonymous Inertia routes and static Svelte pages at `/contact` and `/rights-holders`, selectable addresses with ordinary mailto links, practical inquiry guidance, and cross-links between the pages. Inertia applies only to the site-page links. No forms, clipboard controls, new packages, reactive contact state, response-time promises, or legal/licensing claims were introduced.
- Replaced Games in both explicit footer representations with exact text `For Publishers and Rightholders` at `/rights-holders`. The existing Games route and About catalog entry remain intact. Updated footer browser assertions for the new target, including the mobile disclosures.
- Added Storybook examples for both new pages in light/dark with exact mailto/cross-link assertions. Reviewed representative desktop/tablet/mobile images and the expanded mobile footer. Refreshed 53 existing page/footer references for the new label and previous approved legal-row changes; created 12 new-page references. The update run passed all 69 affected visual cases. No unrelated Player Count Label reference was changed.
- Repository-wide frontend formatting, ESLint, and type checks passed with no errors or warnings. `bun run test:browser -- tests/app/ui/footer.browser.test.ts` passed all 24 Chromium/Firefox checks. The final normal `bun run test` passed 250 of 253 tests, including every changed page/footer case; three Maximum Only screenshot comparisons in the unchanged Player Count Label story differed at the ≤ glyph. Focused reruns of Maximum Only passed at all three Storybook viewports without reference changes; the broad suite is not reported as fully green.
- Recovered from a build-cache conflict between the default Elixir and the repository Nix toolchain by forcing test dependency compilation in Nix and using that environment for remaining Mix checks. `CI=true MIX_ENV=test nix develop --command ... just check` passed compilation, Elixir formatting, and all 794 backend tests, including direct guest access and signed-in Inertia requests with the actual asset version. It then stopped on the same three existing Credo nesting findings in `lib/d20/koala_rescue_club/game.ex` at lines 250, 345, and 383. That unrelated code was not changed.
- Separately ran `mix openspec.check`, `mix assets.build`, and `mix assets.storybook` in the same Nix test environment; all passed. Strict OpenSpec validation passed all 80 items, and `git diff --check` passed.
- DevTools could list browser pages but none matched the local development/Storybook origin. No unrelated tab was opened or navigated. Existing manual full-page/zoom/reflow review and mailbox receipt/monitoring gates remain open. Help, Privacy, Terms, and the deletion answer still depend on their separate approved content and implementation; this address input does not complete them.
- The contact-page preparation is complete locally and remains uncommitted with the owning delivery. #268 is not closed, and its broader OpenSpec change is not archived because publication and independent content work remain incomplete.


## About collaboration copy on 2026-09-08

- Replaced the catalog promotion and technical session explanation with a warm introduction to D20 as a fan project creating digital versions of well-known board games. Added invitations for players, publishers, game designers, developers, and interface designers. About now links to `/contact`, `/rights-holders`, and `/developers`, with no `/games` promotion or link. Retained static inline markup and existing article styling.
- Updated the page brief, proposal, design, product-information requirement, page index, task 2.5, and #268 acceptance scope before reconciling this increment. Existing Help/legal/deletion and mailbox publication gates remain open; the broader change is not ready to archive or close.
- `bun run test:unit -- tests/pages/about/ui/about.test.ts` passed (1 test), verifying the collaboration destinations and absence of the Games link. Scoped ESLint and `oxfmt --check` passed; `bun run typecheck` reported zero errors and warnings.
- Updated only the six About screenshot references with `bun run test:visual -- stories/pages/public/about.stories.ts --update` and inspected every light/dark desktop/tablet/mobile reference. The normal run of `bun run test:visual -- stories/pages/public/about.stories.ts` then passed all six comparisons. The existing screenshot harness captures the visible iframe viewport with blank space below it, so these images do not establish full-page or scrolled-content review; the link test covers all article destinations. No manual zoom or full-page browser check is claimed.
- `openspec validate --all --strict --no-interactive` passed all 80 items. `git diff --check` passed. No backend code or routes changed in this copy refinement; broad cross-stack checks were not repeated. Changes remain local and uncommitted with the owning footer delivery.


## Local master transfer on 2026-09-08

The user requested a commit and transfer to local `master` for the implemented footer, About, Contact, and rights-holder pages. The candidate includes the reviewed screenshot references and the owning specifications. This is an implementation increment under #268, not final acceptance of its missing Help/legal/deletion content or external publication checks. Keep the issue and OpenSpec change active. No push or deployment is requested. Fresh candidate validation is recorded below. The owning issue records the resulting commit, local master transfer, and integrated-target checks.

- Pinned local master at `e12178085eff62d636d519ea4c4a7c869bbc3390`; the candidate rebase was a no-op and the target checkout was clean. Committed implementation, tests, references, and active delivery artifacts together with `Refs: #268` rather than closing the broader issue.
- Fresh `CI=true MIX_ENV=test nix develop --command just check` passed compilation, Elixir formatting, and all 794 backend tests, then reproduced the same three Credo nesting findings in `lib/d20/koala_rescue_club/game.ex` at lines 250, 345, and 383. That source and Credo configuration match the pinned master.
- Ran the checks after Credo separately in the same Nix environment: `mix dialyzer`, `mix ex_dna lib --max-clones 14`, `mix reach.check --arch --smells`, `mix openspec.check`, `mix typecheck`, `mix assets.build`, and `mix assets.storybook` all passed. Frontend formatting and ESLint passed, and strict OpenSpec validation passed all 80 items.
- Fresh full `bun run test` passed 249 of 253 checks. Three unchanged Player Count Label Maximum Only references differed by eight pixels; the mobile Established Account screenshot timed out while the dependency analysis was running. A focused mobile Established Account run passed, and isolated Maximum Only checks passed at all three viewports without reference or source changes. The broad suite is not reported as fully green.
- The user-authorized local integration proceeds with these recorded pre-existing and non-reproducing check failures. Retain the worktree and local candidate branch while the broad validation gate remains non-green; do not force retirement, close #268, archive the active change, push, or deploy. No product or reference changes were made to suppress those checks.
