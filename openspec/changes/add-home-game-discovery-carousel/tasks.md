## 1. Persisted-Catalog Specification Reconciliation

- [x] 1.1 Synchronize the persisted `game-catalog`, `game-catalog-availability`, `game-metadata-fallback`, and `game-session-launch-policy` requirements from `manage-persisted-game-catalog` into `openspec/specs/` without closing #223.
- [x] 1.2 Add exact #264 deltas for `game-catalog`, `game-catalog-availability`, and `game-metadata-fallback` that replace the all-record home grid with playable and randomized browse collections.
- [x] 1.3 Record that every persisted record remains directly detail-addressable, selected playable records are capped at eight, remaining records appear exactly once in browse groups, and provider-only discovery is deferred.
- [x] 1.4 Run `openspec validate --all --strict --no-interactive` and confirm the synchronized base plus #264 deltas contain no stale registry, slug, status, or all-record home requirement.

## 2. Server-Owned Home Projection

- [x] 2.1 Add pure home-partition logic that accepts persisted records in catalog order, evaluates the authoritative launch predicate, takes the first eight eligible records, excludes their ids from browse candidates, shuffles every remaining record through an injectable randomizer, and chunks them into groups of at most sixteen.
- [x] 2.2 Ensure launchable records beyond the eight-card cap remain eligible for browse, every persisted record appears at most once, and empty or final partial browse groups are represented intentionally.
- [x] 2.3 Add focused tests for three current development-playable games, mixed stage/enabled/engine/environment policy, stable playable order, eight-item truncation, deterministic shuffle, complete remaining membership, no duplicate ids, groups of sixteen, final partial, and empty browse.
- [x] 2.4 Add a `D20.Games` home operation that loads records once, delegates partitioning, and enriches the selected records through the existing batched metadata/fallback path without a new provider request type or cache.
- [x] 2.5 Verify metadata success, total failure, partial omission, and missing credentials do not change local collection membership or remove fallback cards.

## 3. Home Controller Contract

- [x] 3.1 Replace the home `games` prop with `playableGames` and `browseGroups`, using stable local ids, stage, and existing game metadata shapes.
- [x] 3.2 Keep the home response successful for empty playable, empty browse, partial final group, and metadata fallback states without adding an endpoint, continuation token, cache header, or migration.
- [x] 3.3 Extend controller tests for exact prop shapes, three current development-playable games, environment-sensitive launch filtering, eight-card cap, non-overlap, complete browse membership, groups of sixteen, stable local links, and fallback metadata.

## 4. Home Types and Semantic Markup

- [x] 4.1 Update TypeScript page contracts and Storybook fixtures from `games` to `playableGames` and typed browse groups without `any`, unsafe assertions, external ids, or continuation state.
- [x] 4.2 Refactor home markup into a hidden page heading plus semantic playable and browse sections while keeping the shell at 46.25rem.
- [x] 4.3 Reuse the existing persisted-game card treatment and `/games/:game_id` Inertia links in both collections, including fallback preview and generic accessible-label behavior.
- [x] 4.4 Preserve server order in the playable collection and in every browse group without client-side filtering, sorting, shuffling, or regrouping.

## 5. CSS-First Carousel State and Accessibility

- [x] 5.1 Add Svelte 5 local state only for selected group index, group element bindings, control focus, and status text. Do not add a global store, fetch, recommendation persistence, or second data owner.
- [x] 5.2 Implement Previous and Next as loaded-group-only navigation using bound elements and `scrollIntoView`, with no network request.
- [x] 5.3 Use a scroller-rooted IntersectionObserver to synchronize selected state after touch, trackpad, keyboard, or focus scrolling without owning snap geometry or moving focus.
- [x] 5.4 Add persistent native buttons named `Previous game suggestions` and `Next game suggestions` with decorative chevrons, determinable disabled state, visible focus, Enter/Space parity, focus transfer before a focused Next becomes disabled, and polite selected-group status.
- [x] 5.5 Disable both controls for one group, disable Previous on the first group and Next on the final group, and keep every card link naturally keyboard reachable.

## 6. Responsive Presentation

- [x] 6.1 Style both section headings as inline-start labels followed by decorative divider rules while preserving semantic text and existing home theme conventions.
- [x] 6.2 Implement `Playable games` as four equal `minmax(0, 1fr)` columns at the supported wide layout with three-, two-, and one-column narrower rules, yielding one row for up to four and two rows for five to eight.
- [x] 6.3 Implement the browse region with native horizontal overflow, logical-axis scroll snap, one full-width group per scrollport, and overscroll containment without JavaScript transforms or drag physics.
- [x] 6.4 Implement each browse group as a four-column grid so sixteen games form 4x4 at the supported wide layout, with three-, two-, and one-column narrower rules and no placeholders in a partial group.
- [x] 6.5 Place chevrons at the logical sides on the supported wide layout and in an adjacent non-obscuring row on narrower layouts without expanding the shell or causing page-level inline overflow.
- [x] 6.6 Keep smooth scrolling and non-essential card motion in CSS and add `prefers-reduced-motion: reduce` rules that use immediate scrolling and remove non-essential transforms/transitions.
- [x] 6.7 Run `cd assets && bun run browsers && bun run browsers:target`, confirm selected CSS/Web APIs satisfy repository policy, and verify no experimental generated scroll controls or anchor positioning entered implementation.

## 7. Frontend Tests, Stories, and Visual Coverage

- [x] 7.1 Update focused home component tests using role/name/text queries for section headings, local links, playable and browse order, native control names/states, loaded-group navigation, focus, and status feedback.
- [x] 7.2 Assert Previous/Next navigation sends no request, one-group controls remain disabled, multi-group navigation preserves all groups, final partial groups add no placeholders, and browse membership does not imply launchability.
- [x] 7.3 Add real-browser home coverage for Enter/Space and pointer activation, focus retention/transfer, observer-selected changes, native scrolling outcomes, and configured Chromium/Firefox execution without style or geometry assertions.
- [x] 7.4 Update deterministic public/authenticated home stories for three playable games, eight playable games, multi-group browse, final partial, no playable games, no browse games, fallback metadata, and focused controls.
- [x] 7.5 Update and review focused home visual baselines in existing desktop, tablet, and mobile projects for partial 4x1 and full 4x2 playable grids, 4x4 browse groups, narrower reflow, divider headings, controls, partial groups, and absence of inline overflow.
- [x] 7.6 Run the smallest focused home component/browser commands from `assets/`, then run `bun run test:visual` after reviewed baseline updates.

## 8. Validation, Manual Review, and Completion

- [x] 8.1 Format touched Elixir and frontend files with repository-native scoped formatters and run focused Games, controller, and home tests.
- [x] 8.2 Run `mix assets.lint`, `mix assets.test`, `mix typecheck`, `mix assets.build`, and `mix assets.storybook`; resolve failures attributable to #264.
- [x] 8.3 Run `mix openspec.check`, `openspec validate --all --strict --no-interactive`, and `just check` after implementation and artifact reconciliation.
- [x] 8.4 Verify wide partial 4x1 and full 4x2 playable layouts, 4x4 browse groups, final partial, tablet/mobile reflow, touch/trackpad snapping, and no page-level inline overflow through configured browser tooling.
- [x] 8.5 Verify keyboard order, Enter/Space controls, meaningful local link names, visible focus, focus transfer at the final group, polite announcements, disabled states, and reduced motion.
- [x] 8.6 Review the final diff against issue #264 and the synchronized #223 contract; confirm no provider-only game, BGG hot request, external link, continuation endpoint, cache process, persistence, migration, launch-policy change, iframe/module change, experimental CSS feature, or client-owned shuffle entered scope.
- [x] 8.7 Reconcile every task and acceptance criterion, archive `add-home-game-discovery-carousel`, rerun strict validation, and confirm the new capability plus modified base requirements are authoritative before reporting #264 complete.

## 9. Review Refinements

- [x] 9.1 Extend issue #264, proposal, design, and the home discovery delta with optical divider-heading alignment and hidden scrollbar acceptance while preserving native scrolling.
- [x] 9.2 Optically center each section label with its divider line and hide the browse scrollport scrollbar using compatible CSS without disabling touch, trackpad, keyboard, or focus scrolling.
- [x] 9.3 Update and review focused home visual baselines, then verify divider-heading alignment, hidden scrollbar presentation, carousel controls, native scrolling, focus, and responsive layouts in the prepared Storybook page.
- [x] 9.4 Run scoped frontend formatting, linting, type checking, home tests, visual checks, strict OpenSpec validation, and `just check`; synchronize the delta, archive the change again, and confirm it is absent from the active change list.

## 10. Section Visibility and Carousel Alignment Refinements

- [x] 10.1 Extend issue #264, proposal, design, and the home discovery delta with `Playable` and `Games` labels, omitted empty sections, equal section spacing, shared card-grid gutters, and compact centered carousel controls and chevrons.
- [x] 10.2 Conditionally render only non-empty home sections, remove empty-state markup and styles, equalize inter-section spacing, align playable cards to the 4x4 browse-grid gutters, and use compact square side controls with centered decorative SVG chevrons.
- [x] 10.3 Update focused component expectations and desktop, tablet, and mobile visual baselines; verify omitted sections, labels, spacing, shared outer card edges, compact control alignment, chevron alignment, focus, navigation, and responsive placement in the prepared Storybook page.
- [x] 10.4 Run scoped formatting, linting, type checking, home tests, visual checks, strict OpenSpec validation, and `just check`; synchronize authoritative specs, archive the change again, and confirm it is absent from the active change list.

## 11. Divider Visual Hierarchy Refinement

- [x] 11.1 Extend issue #264, proposal, design, and the home discovery delta with identical muted divider contrast and tertiary label typography.
- [x] 11.2 Apply one shared regular-weight low-emphasis style to both divider headings and draw each decorative rule as the same crisp one-pixel logical border without changing semantic heading markup.
- [x] 11.3 Update and review focused desktop, tablet, and mobile visual baselines; verify both dividers have identical brightness and apparent line thickness, remain optically aligned, and stay subordinate to card titles and primary controls.
- [x] 11.4 Run scoped formatting, linting, type checking, home tests, visual checks, strict OpenSpec validation, and broad checks; synchronize authoritative specs, archive the change again, and confirm it is absent from the active change list.

## 12. Four-Column Collection Capacity Refinement

- [x] 12.1 Extend issue #264, proposal, design, home discovery and catalog deltas, authoritative specs, and task tracking with an eight-card 4x2 playable limit and sixteen-card 4x4 browse groups.
- [x] 12.2 Raise the server-owned playable and browse-group limits, preserve overflow membership and randomized grouping, and update focused Games and controller tests.
- [x] 12.3 Render four-column wide grids with responsive three-, two-, and one-column reflow; update status thresholds, deterministic fixtures, stories, component/browser tests, and reviewed responsive visual baselines.
- [x] 12.4 Run scoped formatting, backend and frontend tests, linting, type checking, builds, strict OpenSpec validation, and broad checks; reconcile task 11.4, archive the change, and confirm it is absent from the active change list.

## 13. Browse Section Label Refinement

- [x] 13.1 Update issue #264, proposal, design, home discovery delta, authoritative specification, and task tracking so the browse collection's visible section label is `Games`.
- [x] 13.2 Replace the semantic browse-section heading and accessible region name with `Games`, update focused component expectations, and refresh affected responsive Storybook baselines without changing grid or carousel behavior.
- [x] 13.3 Run focused formatting, home component and visual tests, strict OpenSpec validation, rearchive the change, and confirm it is absent from the active change list.

Sections 1–13 record the previously archived #264 delivery. The same change is now reactivated; unchecked work below supersedes the affected home query seam, grid presentation, carousel behavior, tests, validation, and archive completion.

## 14. Reactivation, CSS-Only Decision, and Row Mapping

- [x] 14.1 Restore `add-home-game-discovery-carousel` from its archived directory to the active OpenSpec change path without creating a second issue or change.
- [x] 14.2 Reconcile issue #264, proposal, design, delta specifications, authoritative specifications, and task tracking with the requested looping hero/compact composition and backend query-boundary decisions.
- [x] 14.3 Resolve the Games row mapping: both rows mirror one lossless ordered browse sequence; the hero row owns the single canonical `/games/:game_id` link; the compact strip is inert decoration; dynamic and odd counts use the same sequence; zero entries omit the section; one entry renders a static composition without animation or sentinels.
- [x] 14.4 Record the 2026-09-02 user decision that carousel behavior is CSS-only with apple.com as a visual and behavioral reference only; remove the blocking Open Question, remove Svelte-owned state/timers/listeners/synchronization/status and JS-driven Previous/Next and Play/Pause from the contract, and transparently revise issue #264, proposal, design, and every affected delta before implementation.

## 15. Catalog Query Boundary and Home Props

- [x] 15.1 Extend `D20.Games.list/1` with composable domain options for launch-availability and excluded-id filters, non-negative limit, and `order_by: :catalog | :random`, while keeping `list/0` behavior as the default.
- [x] 15.2 Apply filters, limit, catalog order, and database random order in the Ecto query before `Repo.all`; retain batched metadata enrichment and fallback for each returned non-overlapping result.
- [x] 15.3 Remove dedicated `D20.Games.home/1`, `home_partition/2`, home-specific types/constants that no longer belong, injected randomizer seams, and in-memory browse shuffling.
- [x] 15.4 In `PageController.home/2`, query the first eight launchable catalog entries in catalog order, query all other ids in database-random order, chunk browse results into the existing at-most-sixteen `browseGroups`, and serialize `playableGames` and `browseGroups` inline instead of retaining the helper seam.
- [x] 15.5 Replace helper/randomizer tests with repository-bound tests for default order, launch filter, excluded ids, limit, deterministic catalog order, database randomization, metadata fallback, and controller-level observable cap, membership, non-overlap, group bounds, and exact prop shape.

## 16. CSS-Only Carousel Rendering

- [x] 16.1 Derive the Playable and Games presentation sequences without filtering, shuffling, fetching, or changing the order/membership of initially delivered entries, using the resolved same-sequence row mapping.
- [x] 16.2 Render each multi-item carousel as a CSS animated track with a `--n` slide-count custom property, an approximately five-second dwell per slide, 600ms eased one-slide movement after each dwell, infinite looping, and a seamless `-50%` wrap over a duplicated inert second copy of the sequence.
- [x] 16.3 Render the Games hero row with canonical `/games/:game_id` links and the compact strip plus every duplicated loop copy as `aria-hidden`, inert, non-focusable visuals; keep Playable cards as canonical links with an inert duplicate copy.
- [x] 16.4 Pause each section's animations on `:hover` and `:focus-within` through `animation-play-state`, scoping the Games pause so both rows pause and resume together, with no script participation.
- [x] 16.5 Remove `prefers-reduced-motion: reduce` animation and non-essential transitions so leading slides render statically, with no opt-in autoplay reintroduced.
- [x] 16.6 Render one-item collections as one static card with no duplicate track or animation, omit empty sections entirely, and keep all carousel behavior free of timers, listeners, observers, selected indices, synchronization, document-visibility tracking, dynamic status, and scripted controls.
- [x] 16.7 Ensure a focused canonical link is revealed inside its viewport through a paused-transform override and native hidden-overflow focus scrolling, with visible focus and no script involvement.

## 17. Responsive Hero and Compact Presentation

- [x] 17.1 Replace the Playable grid with the compact landscape strip sharing its responsive card sizing and proportions with the compact Games row.
- [x] 17.2 Replace the Games group grid with an upper large landscape hero row occupying roughly two thirds and a lower compact landscape row occupying roughly one third at desktop, tablet, and mobile without page-level inline overflow.
- [x] 17.3 Keep CSS authoritative for overflow containment, card basis and spacing that keep every animation step exactly one slide, focus-outline clearance, transition presentation, and reduced-motion overrides.
- [x] 17.4 Do not require `::scroll-button()`, anchor positioning, scroll snap events, scroll-state queries, or scroll-driven animations anywhere in the production path.
- [x] 17.5 Preserve lifecycle treatment, title legibility, local fallback previews, semantic section/divider headings, the current shell width, and complete omission of empty sections.

## 18. Component, Browser, Story, and Visual Coverage

- [x] 18.1 Update jsdom component tests with role/name/text queries for section structure and order, server-order flattening, canonical link uniqueness and hrefs, inert and `aria-hidden` duplicates, fallback names, lifecycle badges, zero/one-item static rendering, and no Inertia request during carousel presentation.
- [x] 18.2 Update Chromium and Firefox browser tests with deterministic animation-clock snapshots for dwell, intermediate eased movement, and one-slide advancement, seamless wrap, hover and focus-within pause with resume, matched Games row timing, duplicated-track inertness, Chromium reduced-motion static rendering, and no transition-time request.
- [x] 18.3 Update deterministic public/authenticated Storybook fixtures and states for default, fallback metadata, no Playable, no Games, one Playable, one Games item, and multi-group browse without scripted controls.
- [x] 18.4 Refresh and review focused Chromium Storybook baselines at desktop, tablet, and mobile for the two-thirds/one-third Games composition, compact strip sizing, static one-item states, fallbacks, responsive overflow, and reduced-motion presentation.

## 20. Storybook Motion and Playable Review

- [x] 20.1 Reconcile #264 and its artifacts with visible Playable sizing under application CSS and eased slide interpolation after each dwell.
- [x] 20.2 Remove the daisyUI carousel class collision and add synchronized CSS-only dwell/slide motion with gap-free short loops.
- [x] 20.3 Verify visible cards, intermediate movement frames, loop boundaries, keyboard focus, reduced motion, and desktop/tablet/mobile stories; update the focused regression coverage.
- [x] 20.4 Reduce image-card gutters and row gaps from 0.75rem to 0.5rem, and reduce intervening section/heading spacing from 1rem to approximately 0.6667rem.
- [x] 20.5 Freeze infinite animation clocks deterministically in the Storybook screenshot harness, refresh the affected baselines, then run tests without update mode to verify stability.
- [x] 20.6 Prevent compact-card categories from wrapping over mobile titles and verify the narrow screenshot with full accessible text preserved.
- [x] 20.7 Resolve the catalog-test Credo findings from broad validation by asserting exact returned identities, preserving count and duplicate coverage.
- [x] 20.8 Simplify the shared Storybook screenshot setup to font loading and a 15-second capture budget, remove manual animation freezing and comparison overrides, review and refresh affected baseline glyph edges, and verify the visual suite without update mode. This supersedes the shared animation-freezing approach in task 20.5.
- [x] 20.9 Inline catalog-entry assembly in `D20.Games.list/1`, remove `catalog_entries/1`, and verify catalog/controller behavior, metadata fallback, formatting, and scoped static checks without changing the public contract.
- [x] 20.10 Replace the stage-order SQL constant and `CASE` fragment with native Ecto comparison ordering; verify lifecycle priority, local-id tie-breaking, limits, and catalog/controller behavior without changing database random ordering.

## 19. Validation and Completion

- [x] 19.1 Run `cd assets && bun run browsers && bun run browsers:target`; confirm the production path remains within `baseline widely available with downstream` and Firefox 128 without relying on the prohibited experimental features.
- [x] 19.2 Run scoped Elixir/frontend formatting plus focused `mix test test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs`, `cd assets && bun run test:unit -- tests/pages/home/ui/home.test.ts`, and `cd assets && bun run test:browser -- tests/pages/home/ui/home.browser.test.ts`.
- [x] 19.3 Run `cd assets && bun run test:visual`, review every changed desktop/tablet/mobile baseline, then run `mix assets.lint`, `mix assets.test`, `mix typecheck`, `mix assets.build`, and `mix assets.storybook`.
- [x] 19.4 Manually verify dwell and seamless wrap, matched Games row advancement, hover/focus pause and resume, reduced-motion static rendering, keyboard reachability and visible focus of canonical links, zero/one items, fallback metadata, unique accessible links, and no transition request at desktop/tablet/mobile.
- [x] 19.5 Run `mix openspec.check`, `openspec validate --all --strict --no-interactive`, and `just check`; reconcile issue acceptance and every task with observed results.
- [x] 19.6 Archive the same `add-home-game-discovery-carousel` change only after implementation and validation are complete, rerun strict OpenSpec validation, and confirm it is absent from `openspec list --json` before reporting #264 complete.

## Validation Record (2026-09-05)

- `direnv exec . just check` passed: 783 backend tests; 233 frontend tests passed and one Chromium-only CDP reduced-motion case skipped in Firefox. Formatting, Credo, Dialyzer, ExDNA, architecture checks, OpenSpec lifecycle, frontend lint/typecheck, and Storybook build passed.
- `mix assets.build` passed. Vite reports the existing large-chunk advisory; no build error remains.
- The 42 public/authenticated home Storybook cases were refreshed at desktop, tablet, and mobile, then passed in the normal full frontend run without `--update`.
- Focused Chromium/Firefox carousel coverage passed with application CSS loaded, deterministic dwell/intermediate/wrap/focus screenshots, hover/focus pause and resume, short loops, single-item and reduced-motion states.
- DevTools validation reused `http://localhost:5000/`. At 768px and 320px widths both Games rows showed matched intermediate positions, 8px row gaps, and no page-level inline overflow. Viewport and theme were restored after inspection.
- Local runtime metadata remains degraded to the existing fallback cards; no provider credentials or metadata policy were changed. Mobile compact titles and categories no longer overlap.
- The initial full frontend run hit two five-second screenshot-capture timeouts. After deterministic animation freezing and a 15-second capture budget, the repeated full gate passed without changing the comparison tolerance.
- The native archive synchronized all four delta specifications into the main specifications. Post-archive strict validation passed all 80 active/specification items, lifecycle validation passed, and the archived change is absent from the active change list. The verified worktree remains uncommitted; #264 stays open pending commit and integration.

## Screenshot Setup Review (2026-09-06)

- Removed the shared document-animation pause/seek/playback-rate loop, redundant animation/comparator defaults, and the additional mismatched-pixel ratio. Font loading and the 15-second capture budget remain. Dedicated motion tests still select explicit animation frames locally.
- The first normal home comparison passed 19 of 42 cases; 23 references differed by 5-86 pixels, with no screenshot-stability timeout. Reviewed diffs showed small glyph-edge changes rather than shifted carousel content. Refreshed only home references with `direnv exec . just assets test:visual -- stories/pages/public/home.stories.ts stories/pages/authenticated/home.stories.ts --update`; all 42 cases passed.
- `direnv exec . just assets test` then passed without update mode: 233 tests passed across 43 files, with one expected Firefox skip for the Chromium-only reduced-motion check. This includes all Storybook viewports and separate carousel motion coverage without the shared animation workaround or additional comparison tolerance.
- Frontend `format.check`, `lint`, and `typecheck` passed; typecheck reported no errors or warnings. No production code changed during this review, and backend tests were not rerun.
- Strict OpenSpec validation passed all 80 active/specification items. This is a correction to the same uncommitted archived delivery; no parallel change or issue was created, and #264 remains open pending commit and integration.

## Catalog Assembly Review (2026-09-06)

- Moved the metadata-batch coordination and entry mapping from the single-use `catalog_entries/1` wrapper into `D20.Games.list/1`, then removed that wrapper. Query composition, metadata fetching/fallback, selected order, and `{:ok, entries}` remain unchanged.
- `mix format --check-formatted lib/d20/games.ex` passed.
- `mix test test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs` passed all 55 tests, including catalog order/filtering and partial, failed, and missing-credential metadata fallback.
- `mix credo --strict --files-included lib/d20/games.ex` passed with no issues. All commands ran in the existing direnv environment. No frontend behavior or screenshot baseline changed during this review.

## Lifecycle Ordering Review (2026-09-06)

- Removed `@stage_order_sql` and the catalog `CASE` fragment. Native Ecto comparisons retain released, in-development, planned priority and local-id tie-breaking before the database limit.
- `mix format --check-formatted lib/d20/games.ex`, `mix test test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs` (55 passed), and `mix credo --strict --files-included lib/d20/games.ex` passed in direnv.
- This verification covers lifecycle ordering only. The separate `fragment("RANDOM()")` remains because the existing contract requires database-owned random ordering; replacing it with Elixir-side shuffling requires clarification of that requirement. No complete removal of inline SQL is claimed.

## 21. Bounded Native Ecto Listing Review (2026-09-06)

This review supersedes the default full-catalog/lifecycle order, custom query options, and database-random browse requirements in tasks 15.1, 15.2, 15.4, 15.5, and 20.10. Earlier checked tasks remain historical verification records, not requirements to retain superseded behavior.

- [x] 21.1 Reactivate the same #264 artifact set and reconcile proposal, design, all affected deltas, and issue acceptance with unfiltered/unordered 32-record defaults, a validated maximum of 100, native Ecto options, and opt-in playable filtering.
- [x] 21.2 Add focused regression tests for nonempty bounded defaults, native where/order composition, explicit playable policy, invalid limits/options, capped metadata batches, and bounded non-overlapping home groups; first demonstrate the default-limit regression.
- [x] 21.3 Implement inline query assembly and option types in Games.list, remove SQL fragments and superseded query helpers, and adapt PageController's two calls without changing metadata or Inertia entry shapes.
- [x] 21.4 Run touched-file formatting, focused catalog/controller tests, all backend tests, and strict Credo; review the diff for SQL fragments, unbounded loads, and unrelated changes.
- [x] 21.5 Synchronize all affected authoritative specs, archive the same change, run strict OpenSpec/lifecycle validation, and reconcile issue evidence while leaving delivery open pending commit/integration.

### Verification

- The default-limit regression first failed against the previous implementation: `Games.list()` returned all 129 fixture records instead of 32. It passes after the change; both no-option forms return 32, explicit limit 100 returns 100, and metadata requests contain exactly the selected ids.
- The shared default test database has an unrelated required `games.slug` column absent from this worktree's schema and migrations. Validation uses the existing test-partition mechanism with `MIX_TEST_PARTITION=_home_catalog_review_20260906`; its isolated database was initialized by the normal `mix test` alias. No shared database, migration, or environment file was changed.
- `direnv exec . env MIX_TEST_PARTITION=_home_catalog_review_20260906 mix test test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs` passed all 60 tests, including default membership, native dynamic/keyword filters and ordering, opt-in launch policy, limits 0/32/100, invalid options, metadata fallback, and bounded/non-overlapping home groups.
- `direnv exec . env MIX_TEST_PARTITION=_home_catalog_review_20260906 mix test` passed all 788 backend tests. The touched-file formatting check and `direnv exec . mix credo --strict` also passed.
- No frontend source or screenshot baseline changed in this review. The initial Inertia entry/group shapes, CSS-only carousel behavior, and launch policy remain unchanged.
- `direnv exec . mix compile --warnings-as-errors`, `direnv exec . mix reach.check --arch --smells`, and `direnv exec . mix dialyzer` passed. Dialyzer retained its existing single configured exclusion; no new exclusion was added.
- Native OpenSpec archival synchronized all four affected authoritative specifications and moved the same change to `2026-09-06-add-home-game-discovery-carousel`. Post-archive strict/lifecycle validation passed; the change is absent from the active list. Issue #264 acceptance and evidence were reconciled, and it remains Open/In Progress pending commit and integration.

## 22. Schema-Field Conditions and Inline Metadata Review (2026-09-06)

This follow-up supersedes the named playable filter and retained single-use metadata helpers from section 21. It continues the same uncommitted #264 outcome.

- [x] 22.1 Reactivate the owning artifacts and update issue acceptance, proposal, design, and affected deltas for native schema-field conditions and inline provider-result handling.
- [x] 22.2 Cover rejection of the removed filter alias, field-based conditions without hidden launch policy, and preserved per-record/batch fallback logging; characterize existing fallback before refactoring.
- [x] 22.3 Remove the playable option and single-use catalog metadata helpers, inline the batch result and schema validation, and pass explicit home selection conditions without changing launch eligibility or response shapes.
- [x] 22.4 Run focused and full backend tests, touched-file formatting, strict Credo, compilation, architecture checks, and Dialyzer; review for unrelated changes.
- [x] 22.5 Synchronize authoritative specs and archive this same change with native OpenSpec tooling; verify strict validation and the active list, update issue evidence, and leave delivery open pending commit/integration.

### Inline review verification

- Existing focused tests first passed (60). Updated tests characterized one per-game warning for a partial response and one catalog warning for a failed batch before changing production code. The removed-alias regression initially failed because `filter: :playable` still reached the provider; after removal it raises `ArgumentError` before any request.
- `direnv exec . env MIX_TEST_PARTITION=_home_catalog_review_20260906 mix test test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs` passed all 61 tests against the final implementation.
- `direnv exec . env MIX_TEST_PARTITION=_home_catalog_review_20260906 mix test` passed all 789 tests after the final inline refinement. The same isolated test database avoids the unrelated shared `games.slug` mismatch recorded in section 21; no shared schema or environment file changed.
- Touched-file `mix format --check-formatted`, `mix credo --strict`, `mix compile --warnings-as-errors`, `mix reach.check --arch --smells`, and `mix dialyzer` passed. Dialyzer retained its existing single configured exclusion. An initial Credo nesting finding was resolved by mapping a failed batch to empty per-row schema attributes before the shared inline validation/entry loop; no suppression or new helper was added.
- The public list options are only native `where`, `order_by`, and bounded `limit`. No named playable filter, catalog metadata status arguments, catalog SQL fragment, or single-use catalog metadata helper remains. Defaults, selected metadata batch bounds, membership, fallback, and Session authorization are preserved.
- No frontend source or screenshot changed during this review. The existing home controller supplies equivalent enabled/stage/engine conditions and retains the response contract.
- Native `openspec archive add-home-game-discovery-carousel --yes` synchronized the four affected authoritative specifications and rearchived the same artifacts at `2026-09-06-add-home-game-discovery-carousel`. Strict validation passed all 80 remaining active/specification items, lifecycle validation passed, and the home change is absent from the active list. Issue #264 remains Open/In Progress; all work is uncommitted.

## 23. Two-Stage Catalog and Environment Policy (2026-09-07)

This follow-up supersedes the three-stage model, launch feature flag, and unrestricted production browse/detail discoverability. Existing running-session behavior remains unchanged.

- [x] 23.1 Reconcile #264 and the same proposal/design/deltas with the accepted two-stage model, environment visibility, no launch toggle, and migration/rollback boundaries.
- [x] 23.2 Add regression coverage for default in-development records without engines, released validation, stage/database constraints, migrated identities, and preservation of all engine bindings.
- [x] 23.3 Add the forward migration and simplify schema, launch policy, public home/detail visibility, and configuration while preserving explicit policy-neutral list options and existing sessions.
- [x] 23.4 Update frontend stage types, fixtures, admin expectations, and tests; review affected home screenshots and run normal comparisons without update mode.
- [x] 23.5 Verify dev/production catalog, detail, and both launch endpoints, including existing-session continuity; validate migration up/down/up in an isolated database and run targeted tests followed by just check. Verify the existing localhost:5000 page against an isolated migrated database so shared development state does not need to change.
- [ ] 23.6 Synchronize affected authoritative specs, archive the same change, validate strict OpenSpec/lifecycle/active-list state, and record verified evidence in #264; the later commit/transfer request supersedes the earlier uncommitted-delivery restriction.

### Two-stage verification

- Schema regressions first failed against the old implementation: new rows defaulted to planned, in-development records required engines, and planned remained accepted. The new enum/default and database constraints now cover both supported stages; released engine validation uses ordinary inline `validate_required`.
- Before the generic-migration correction below, migration `20260907093528` passed up/down/up against the isolated `d20_test_stage_migration_20260907` database. Assertions cover stable ids, BGG bindings, timestamps, enabled flags, implemented engine bindings, engine-less defaults, the Fliptown placeholder, and the documented lossy stage rollback.
- Runtime and channel tests explicitly release their Next Station London fixtures instead of depending on development launch permission. The focused server/channel run passed 17 tests. After adopting native required-field validation, the admin form regression was updated to check its rendered `can't be blank` message; all 13 admin tests passed.
- Reviewed updated desktop/tablet/mobile home screenshots for the two-stage fixtures. In narrow decorative cards, categories no longer overlap the stage badge; canonical hero categories remain visible and accessible. No global animation manipulation or comparison tolerance was added.
- Shared `d20_dev` includes migration `20260827000000` from another worktree. It was inspected read-only and was not migrated or reset. The existing localhost:5000 page currently reports `Phoenix.Ecto.PendingMigrationError`; applying the stage migration to this shared database requires the user's decision before live-page verification and finalization.

## 24. Generic stage migration correction (2026-09-07)

- [x] 24.1 Remove game-specific engine cleanup and redundant flush/callback/query machinery; use declarative SQL stage updates and preserve every engine binding.
- [x] 24.2 Replace the game-specific migration expectation with generic binding coverage and verify up/down/up plus focused catalog/controller tests in a fresh isolated database.

Verification for section 24:

- The migration now queues one SQL stage update per direction and never writes engine bindings. Removed both flush calls, Ecto.Query import, callbacks, and game-specific cleanup.
- The existing full catalog backfill assertion now verifies all original engine bindings; removed the obsolete game-specific cleanup test. Updated catalog/controller membership expectations for the preserved binding.
- `direnv exec . env MIX_TEST_PARTITION=_generic_stage_20260907 mix test test/d20/games/game_test.exs test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs`: 81 passed.
- An isolated up/down/up check in the same test partition verified unchanged ids, BGG ids, all engine bindings, enabled flags, and timestamps for all 19 rows, including planned records with and without engines.
- Preserving bindings makes every registered in-development engine eligible under the current dev policy, including a placeholder whose init returns not_implemented. The migration does not infer engine readiness; production still excludes in-development records.
- Shared development databases were not modified. Section 23 finalization gates remain open.
- Full backend verification in the same isolated partition: `mix test` passed 801 tests. Touched-file formatting, `git diff --check`, and `openspec validate --all --strict --no-interactive` passed (81 items).

## 25. Catalog option normalization (2026-09-07)

- [x] 25.1 Normalize supported options into a keyword list with defaults, ignore unknown keys, clamp integer limits to 0..100, and default other limits to 32; remove the intermediate tuple and custom option errors.
- [x] 25.2 Verify normalized defaults, ignored keys, limits and metadata batch bounds with catalog tests, formatting, Credo, and strict OpenSpec validation.

Initial section 25 verification before the normalization clarification: `direnv exec . env MIX_TEST_PARTITION=_generic_stage_20260907 mix test test/d20/games_test.exs` passed all 21 tests. Strict Credo found no issues. Touched-file formatting, diff whitespace checks, and strict OpenSpec validation passed (81 items). The with returns validated options and limit before query/enrichment to preserve the existing nesting depth. Broader section 23 delivery gates remain open.

## 26. Home component readability (2026-09-07)

- [x] 26.1 Remove derived-value annotations and explanatory script comments; inline all card markup without snippets while preserving rendered behavior.
- [x] 26.2 Verify home component tests, frontend typecheck, focused lint/format checks, strict OpenSpec validation, and inspect the prepared development page when available.

Initial section 26 verification before the final snippet removal:

- `bun run test -- --project unit tests/pages/home/ui/home.test.ts`: all 7 tests passed, covering section states, links, duplicate accessibility, and metadata fallback.
- `bun run typecheck`: passed, with zero Svelte errors or warnings. Focused ESLint, oxfmt check, and diff whitespace checks passed.
- The initial refinement retained one shared card body snippet; link/decorative wrappers are inline and derived count/slide types are inferred. Classes, ids, hrefs, inert duplication, and CSS remain equivalent.
- Chrome DevTools list_pages could not connect to http://127.0.0.1:9222/json/version, so prepared-page inspection was unavailable. No alternative browser surface was opened. Broader section 23 finalization gates remain open.
- `openspec validate --all --strict --no-interactive`: all 81 items passed.

Final section 26 correction: removed cardBody and every snippet/render call. Each card now renders its image, metadata, fallback, and title inline. All 7 home component tests passed again, as did frontend typecheck (zero Svelte errors/warnings), focused ESLint and formatting, diff whitespace checks, and strict OpenSpec validation (81 items). Chrome DevTools remained unavailable at 127.0.0.1:9222; prepared-page verification was not claimed. Broader section 23 gates remain open.

Final section 25 normalization verification: the new expectations first failed in three tests against the previous validation. After normalization, `direnv exec . env MIX_TEST_PARTITION=_generic_stage_20260907 mix test test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs` passed all 67 tests. Coverage includes ignored keys alongside supported query options, 32-record defaults for nil/non-integer limits, clamping negative limits to zero, limits of 100/101/10000 returning at most 100 records, matching metadata batch bounds, and native Ecto query errors. Strict Credo, touched-file formatting, diff whitespace checks, and strict OpenSpec validation (81 items) passed. Section 23 finalization gates remain open.

## 27. Catalog controller boundary (2026-09-07)

- [x] 27.1 Move playable and browse query construction to public D20.Games APIs and remove Ecto.Query and the Game schema alias from PageController home selection.
- [x] 27.2 Cover domain selection behavior and verify existing controller contracts, formatting, Credo, and strict OpenSpec validation.

Section 27 verification: the unchanged focused suite passed 67 tests before the move. After adding context coverage, `direnv exec . env MIX_TEST_PARTITION=_generic_stage_20260907 mix test test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs` passed all 69 tests. Tests cover dev/prod visibility, enabled filtering before limits, stage/id order, excluded ids, disabled browse entries, empty selections, existing home caps, and unchanged public responses. Removed redundant Game struct patterns from two controller actions when dropping the schema alias; domain return contracts supply the same game values. Strict Credo, formatting, diff whitespace checks, and strict OpenSpec validation (81 items) passed. This refinement removes catalog query/schema construction from PageController; existing changeset error handling is outside its scope. Broader section 23 gates remain open.

## 28. Flat browse response (2026-09-07)

- [x] 28.1 Replace browseGroups with a flat games array, removing controller chunks/group ids and the shared group type.
- [x] 28.2 Consume games directly and update fixtures, stories, component/browser tests, and controller contract assertions.
- [x] 28.3 Verify focused backend/frontend tests, typecheck, formatting/lint, browser/story coverage, and strict OpenSpec validation.

Section 28 verification:

- Home returns flat `games` and `playable_games` props, serialized as `games` and `playableGames`. Each entry retains its id, stage, and metadata; browse selection remains bounded to 32 and excludes the selected playable ids. Controller chunks, group ids, the group type, and client flattening are removed.
- Focused catalog/controller tests passed (69), home component tests passed (7), and Chromium/Firefox home browser tests passed (11 with one expected Firefox skip). Existing screenshots matched without update mode.
- `direnv exec . env MIX_TEST_PARTITION=_generic_stage_20260907 just check` passed: 804 backend tests, 233 frontend tests across 43 files with one expected skip, formatting, lint, Dialyzer, architecture/lifecycle checks, typecheck, and Storybook build. Typecheck reported zero Svelte errors or warnings. The established isolated test partition avoids the unrelated shared schema mismatch.
- Strict OpenSpec validation passed all 81 items; `git diff --check` passed. No screenshot baselines were updated for this response change.
- Chrome DevTools reached the existing localhost:5000 page and confirmed `Phoenix.Ecto.PendingMigrationError`. The shared development database remains unchanged, and section 23 live-page/finalization gates remain open.

## 29. Home test scope correction (2026-09-07)

This review supersedes earlier animation-runtime validation requirements. CSS behavior is unchanged; automated tests trust browser animation mechanics.

- [x] 29.1 Remove timeline seeking, animation queries, play-state/timing assertions, and their unused screenshot baselines; retain keyboard navigation and UI-state screenshots with native screenshot defaults.
- [x] 29.2 Remove the component assertion on the single-item animation marker and verify home component/browser tests, formatting, lint, typecheck, and strict OpenSpec validation.

Section 29 verification:

- Removed three animation-runtime scenarios, the seek helper, custom animation screenshot options, all animation-object queries/assertions, and 12 obsolete frame baselines. The component test no longer asserts the single-item CSS marker. Application sources and CSS are unchanged.
- Retained keyboard navigation through canonical links, focused-card screenshots, narrow single-game screenshots, and a reduced-motion screenshot. Ordinary multi-game layouts remain covered by existing Storybook states. Reviewed and refreshed only the focus references after switching from explicitly sought frames to native screenshot defaults.
- `bun run test -- --project unit --project browser tests/pages/home/ui/home.test.ts tests/pages/home/ui/home.browser.test.ts` passed all 12 tests across three project files without update mode, with one expected Firefox skip for the CDP reduced-motion fixture.
- Focused ESLint and oxfmt checks passed. `bun run typecheck` passed with zero Svelte errors/warnings. Strict OpenSpec validation passed all 81 items, and `git diff --check` passed.
- Earlier motion-test evidence is historical; automated tests no longer claim validation of browser animation mechanics. Broader section 23 live-page/finalization gates remain open.

## 30. Master fast-forward and adaptation (2026-09-08)

This correction supersedes the TypeID-only public-link descriptions in earlier sections. Public links use stable slugs from master; TypeIDs remain internal identities.

- [x] 30.1 Save the complete current state, pin and fast-forward to local master, and restore the saved changes with a retained recovery snapshot.
- [x] 30.2 Resolve conflicts and adapt catalog props, slug links, schema/controller behavior, fixtures/tests, and affected specifications while preserving all accepted home refinements and master behavior.
- [x] 30.3 Validate focused frontend/backend behavior and isolated migration up/down/up, then run just check, strict OpenSpec validation, and final ancestry/preservation checks; reconcile #264 evidence.

Section 30 verification:

- Fast-forwarded from `28abd986009c61505c548360ff8006e32f18d15c` to pinned local master `e12178085eff62d636d519ea4c4a7c869bbc3390`, then restored the complete uncommitted state and resolved 11 conflicts. The original index, working files, and untracked files remain recoverable through `refs/backups/home-carousel-before-master-20260908` at `85268f535c14b0e28a02b162eb98cb220e3d3a6c`. No saved effective file is missing; 83 of 109 are byte-identical and the remaining files are adapted source/tests/specifications. Originally deleted animation-frame baselines remain deleted. HEAD equals master and no unmerged index entries remain.
- Both flat home collections carry the persisted slug and use `/games/:slug`; TypeIDs remain internal identities and DOM keys. Preserved master's immutable operator-assigned slugs, session dispatch, and Storybook preview CSS motion suppression, together with every accepted home refinement. In `home.svelte`, only the two canonical href expressions differ from the saved user version. The generic stage migration still preserves every engine binding.
- `direnv exec . env MIX_TEST_PARTITION=_home_ff_20260908 mix test test/d20/games/game_test.exs test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs test/d20_web/controllers/module_controller_test.exs test/d20_web/live/admin/game_live_test.exs` passed 124 tests. The isolated migration up/down/up check preserved ids, slugs, BGG ids, stages, every engine binding, enabled flags, and timestamps across all 19 rows. No shared development database was changed.
- `bun run test -- --project unit --project browser tests/pages/home/ui/home.test.ts tests/pages/home/ui/home.browser.test.ts tests/pages/game/ui/game.test.ts` passed 27 tests with one expected Firefox skip. `bun run typecheck` passed with zero Svelte errors/warnings; `bun run check` and `bun run storybook:build` passed without baseline updates.
- `direnv exec . env MIX_TEST_PARTITION=_home_ff_20260908 just check` passed compilation, formatting, and all 823 backend tests, then stopped at three existing Credo nesting findings in unchanged master code: `lib/d20/koala_rescue_club/game.ex:250`, `:345`, and `:383`. The remaining `mix dialyzer`, `mix ex_dna lib --max-clones 14`, `mix reach.check --arch --smells`, and `mix openspec.check` checks passed when run individually. Strict OpenSpec validation passed all 81 items.
- Full `bun run test` passed 229 tests with one expected skip and two failures: the tablet registration Auth Provider screenshot could not stabilize within 15 seconds, and the Firefox header mailbox test tried to respond before its form submission was registered. These story/application/test files are unchanged from master. A focused retry with `bun run test -- --project tablet --project browser stories/pages/public/registration_completion.stories.ts tests/app/ui/header.browser.test.ts` passed all 52 tests across three project files without source or baseline updates; neither failure reproduced. All home tests passed in the full run. A completely green `just check` is not claimed.
- The work remains uncommitted in this worktree. The issue stays Open/In Progress, and the broader section 23 live-page/finalization gates remain open.


## 31. Commit and transfer to master (2026-09-08)

The user now authorizes committing and transferring this delivery to local master. This supersedes the earlier instruction to keep work uncommitted. Local master advanced to `72afec0` with an independently delivered footer and public information pages; preserve those changes while adapting overlapping stories and screenshots. The previously reported master Credo findings and transient full-suite failures are known baseline limitations, not changes to game behavior.

- [x] 31.1 Prepare one semantic commit with source, tests, reviewed baselines, and owning artifacts; preserve diagnostic-only captures outside the repository.
- [x] 31.2 Rebase onto the pinned current master and adapt overlapping home stories and screenshots while retaining the footer and information pages.
- [ ] 31.3 Validate the candidate and reconcile remaining delivery gates before finalization; fast-forward master, validate the integrated target, and retire the source worktree when all transfer gates pass.


Section 31 candidate evidence:

- Rebased the local candidate on pinned master `72afec077f7236e7f256b7df83624aec55351554`. Preserved the independently delivered footer, public routes/controllers, and authenticated/empty-home story coverage. Empty home now supplies both empty collections and asserts their absence instead of obsolete placeholder copy. Conflicting home references are regenerated for the combined UI; no browser animation tests are introduced.
- Preserved the complete pre-transfer state at `refs/backups/home-carousel-before-transfer-20260908` (`7de49efadb1a294447ad38ef6faeaaac2f068d01`). Removed obsolete diagnostic captures and already-deleted animation references from the semantic commit; copies remain outside the repository and in the backup.
- Candidate `direnv exec . env MIX_TEST_PARTITION=_home_ff_20260908 just check` passed compilation, formatting, and all 827 backend tests. It then reported exactly the same three unchanged master Credo nesting findings at `lib/d20/koala_rescue_club/game.ex:250`, `:345`, and `:383`, disclosed before the user authorized transfer. Dialyzer, clone limits, architecture, frontend lint/formatting, and typecheck passed separately; Svelte reported zero errors/warnings.
- The existing Chrome DevTools page at `http://localhost:5000/` was restored using a task-owned development server connected to isolated `d20_test_home_ff_20260908`. It rendered four playable and fifteen browse links, two sections, fallback previews, and the current footer. Activating Qwinto navigated to `/games/qwinto` with its Play control; the original home route was restored. The first click during Vite setup did not navigate and left a generic rejected-promise message; the repeated navigation and final fresh home load completed with no console errors. The temporary server was stopped after verification. Shared development databases were unchanged.
- This isolated live-page verification resolves the earlier section 23 pending-migration gate without applying migrations to shared development state. The prior up/down/up verification still covers all 19 persisted catalog records and every engine binding.

- The merged home stories passed all 48 desktop/tablet/mobile cases in update mode; reviewed the desktop and mobile results. Removed nine obsolete references for former group/control stories. The subsequent normal full frontend run passed all 48 home story cases without updates and passed 280 tests overall, with one expected Firefox skip and five screenshot failures. Three were the unchanged Player Count Label `Maximum Only` eight-pixel glyph differences already recorded in master's footer verification; two were narrow home references. A normal focused rerun of both files passed all 17 tests with one expected skip, without modifying source or references. No failed case remains reproducible in its focused suite; a fully green aggregate run is not claimed.
- `bun run storybook:build` completed successfully. Strict OpenSpec validation passed all 82 active/specification items after synchronizing the six owning capabilities. Whitespace checks passed. The semantic implementation commit is ready for target integration; archival and final issue reconciliation follow the required integrated-target verification.
