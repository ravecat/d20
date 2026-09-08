## Context

Issue [#264](https://github.com/ravecat/d20/issues/264) already owns an uncommitted implementation that partitions the persisted catalog into `playableGames` and request-randomized `browseGroups`, delivers both collections in the initial Inertia response, and renders Playable and Games as responsive grids with group-level Previous/Next navigation. That OpenSpec change was archived, then its commit was soft-reset; this change directory is the same artifact set reactivated from `openspec/changes/archive/2026-09-01-add-home-game-discovery-carousel` rather than a parallel change.

The revised product direction keeps both collections but replaces their presentation. Games takes visual and behavioral inspiration from Apple's “Endless entertainment” section: a dominant hero row and a subordinate compact strip. The NoLoJS animated-hero demo demonstrates that native CSS keyframes with duplicated inert tracks can create a looping carousel without script. Neither reference is a source of D20 assets or code, and neither is an exact technical implementation target.

On 2026-09-02 the user directed that carousel behavior be achieved **only with CSS**, superseding the previously drafted Svelte-owned canonical-index/timer/synchronization design recorded in the earlier revision of this document. The former blocking Open Question about Games row mapping was resolved at the same time: both rows mirror one lossless ordered browse sequence, the hero card owns the single canonical detail link, and the compact strip is inert decoration.

References reviewed 2026-09-02:

- <https://www.apple.com/> — visual and behavioral reference for the two-thirds hero/one-third compact composition and timed advancement. Not an implementation target; not a source of assets or code.
- <https://aarontgrogg.github.io/NoLoJS/components/css-carousel/animated-hero/index.html> — reference for CSS-only looping with duplicated tracks and reduced-motion gating.

The browser contract remains the `assets/package.json` policy `baseline widely available with downstream` plus `not Firefox < 128`; the current resolved compiler floor is Chrome/Edge 121, Firefox 128, Safari/iOS 17.2, and Opera 107. Therefore `::scroll-button()`, CSS anchor positioning, scroll snap events, container scroll-state queries, and scroll-driven animations cannot own essential production behavior.

## Goals / Non-Goals

**Goals:**

- Keep non-empty `Playable` before non-empty `Games`, preserving empty-section omission, the current home shell, local identity, metadata fallback, and initial-response-only navigation.
- Render Playable as an independent compact landscape-card strip matching the compact Games-row proportions and sizing.
- Render Games as an upper hero row and lower compact strip derived from one lossless ordered browse sequence, with matched CSS animation timing so both rows advance together, and an approximate two-thirds/one-third visual allocation.
- Auto-advance and continuously loop every multi-item carousel using only CSS keyframes; pause on pointer hover and keyboard focus-within through `animation-play-state`; disable animation under `prefers-reduced-motion: reduce`.
- Preserve keyboard access and visible focus for every canonical link, exactly one accessible local detail link per delivered game, and inert non-focusable duplicated tracks.
- Keep the server authoritative for launchability, membership, cap, exclusion, caller-requested ordering, and flat catalog arrays while making `D20.Games` a deeper reusable query boundary.
- Validate behavior in focused unit/browser tests and presentation in deterministic desktop, tablet, and mobile Storybook baselines.

**Non-Goals:**

- Copying Apple images, names, markup, scripts, motion curves, or other proprietary assets, or treating Apple's page as an exact technical implementation target.
- Script-owned carousel behavior of any kind: canonical indices, dwell timers, scroll or intersection listeners, row synchronization code, manual-scroll reconciliation, document-visibility tracking, dynamic ARIA status, or JS-driven Previous/Next and Play/Pause controls.
- Claiming pause/resume semantics beyond what CSS state can honor: hover and focus-within pause the animation and it resumes when the reason leaves; there is no persistent Pause, no Play control, and no document-hidden pause.
- Provider-only discovery, continuation loading, per-transition requests, durable recommendations, personalized ordering, or persisted carousel position.
- Changing the adopted slug routes, metadata providers, running-Session behavior, iframe/module contracts, dependencies, or browser policy. The two-stage schema and public visibility follow-up below explicitly adds a migration and updates new-Session policy.
- Making experimental generated scroll controls, anchor positioning, scroll snap events, scroll-state queries, or scroll-driven animation a required path.

## Decisions

### 1. Continue the same #264 change and treat the CSS-only composition as a refinement

The archived directory is restored as `openspec/changes/add-home-game-discovery-carousel/`. Sections 1–13 of `tasks.md` remain the historical record of the first implementation and its reviews; later sections supersede the affected grid/group presentation and backend seam. The issue remains open and in the D20 Project with status `In Progress`.

A new issue or OpenSpec change was rejected because the working tree, issue, authoritative specs, and prior artifacts all belong to one uncommitted delivery outcome.

### 2. Preserve the Inertia collection contract and server-owned membership

The response retains:

```text
playableGames: GameCatalogEntry[]
games: GameCatalogEntry[]
```

All selected entries are present in the initial response as flat arrays. Browse contains at most 32 maps with id, slug, stage, and game metadata. The controller does not chunk records or synthesize group ids, and the client consumes games directly without flattening. Membership and response order remain unchanged during presentation.

Both Games rows consume the same derived sequence; hero and compact differ only in presentation. Partitioning delivered games into different hero and compact sequences was rejected because it would invent a second data mapping, duplicate or starve entries across rows, and add server-side presentation policy for no discovery benefit.

### 3. Keep catalog queries in `D20.Games`

The 2026-09-06 reviews supersede unbounded/default-catalog-order, randomized-browse, and named playable-filter decisions. `list(options \\ [])` supports only:

- `where`: Ecto equality keyword conditions or a `dynamic/2` expression on schema fields, default `[]`;
- `order_by`: native Ecto fields/directions/expressions, default `[]`;
- `limit`: integer inputs clamp to 0..100; missing, nil, or non-integer inputs use 32.

Merge the supported keys into the default keyword list and normalize its limit inline. Ignore unknown keys, including the former `filter: :playable` option. Clamp integer limits to 0..100 and use 32 for nil or non-integer limits. Do not return an intermediate tuple or raise custom option-validation errors. Ecto validates native query values. Define option types inline using `Ecto.Query.dynamic_expr()`; retain no separate list-option type or single-use query helper.

Build the query directly from `Game` inside `list/1`. The supplied schema-field conditions, ordering, and limit apply before `Repo.all` and before fetching BGG metadata. Listing never adds launch policy or reads its environment flag, including when explicit stage/enabled conditions are supplied. With no order there is no guarantee of oldest/newest or random selection, and no pagination promise. Both no-option call forms are identical.

Inline the existing batch request, metadata lookup by each persisted row's `bgg_id`, `Metadata.new/1` validation, fallback, and entry assembly in `list/1`. Branch directly on the provider's `{:ok, metadata}` / `{:error, reason}` response, without invented availability status arguments or the single-use `fetch_catalog_metadata/1` and `catalog_metadata/3` helpers. A batch error logs once at catalog scope and supplies empty attribute maps keyed by the selected rows' bgg ids; the existing metadata schema converts those empty attributes to its default empty struct. Successful batches preserve valid metadata and log/fallback individually for missing or invalid records. Do not turn a batch outage into one missing-game warning per row. This keeps schema validation and entry assembly in one shallow inline loop. Preserve order, identity, stage, `{:ok, entries}`, one bounded batch, and no network request for an empty selection. Single-game detail lookup and shared logging remain unchanged.

`Games.list_playable(limit)` owns the native query over enabled, visible stages, and the deployed engine enum, with released then in-development and id ordering. PageController passes only the eight-record limit; it does not import Ecto.Query or consult the Game schema. The context delegates bounded loading and metadata enrichment to list/1. Session creation continues to enforce `Games.session_launch_available?/1` independently. Controller tests guard agreement between the display selection and that policy.

`Games.list_browse(excluded_ids)` restricts visible stages and excludes the supplied ids before the default 32-record limit, and requests no order. PageController passes the selected playable ids as ordinary data. The controller serializes the selected entries directly into the flat games prop.

No new dependency, pagination endpoint, catalog SQL fragment, or in-memory shuffle is introduced; the updated master supplies the stable slug schema field. The two-stage follow-up adds the data/default/constraint migration described below. Tests cover field equality and dynamic membership/exclusion, policy-neutral listing, 0/32/100 bounds, ignored unsupported options, metadata batch bounds and warning scope, missing/failed metadata, and unchanged bounded/non-overlapping home props.

### 4. Combine CSS sequence stepping with an eased slide movement

Each multi-item carousel is a track containing two consecutive copies of its ordered sequence. The second copy is `aria-hidden="true"` and `inert`, so canonical content appears exactly once in the accessibility and tab order while the duplicate provides the visual wrap point and the focus-reveal runway. The track carries a `--n` custom property with the slide count set by the renderer, and CSS animates it:

```css
.track {
  animation: loop calc(5.6s * var(--n)) steps(var(--n), jump-end) infinite,
    slide 5.6s infinite;
}

@keyframes loop {
  from { transform: translateX(0); }
  to   { transform: translateX(-50%); }
}

@keyframes slide {
  0%, 89.285714% {
    translate: 0;
    animation-timing-function: cubic-bezier(0.22, 0.61, 0.36, 1);
  }
  100% { translate: calc(-50% / var(--n)); }
}
```

Each cycle holds for five seconds and moves for 600ms. The sequence transform advances one slide exactly when the independent translate animation resets, so their combined position is continuous at each cycle boundary and at the final wrap. A bare `steps()` animation is insufficient because it teleports between cards. Both Games rows share both animations and pause states; neither timing nor distance requires script. Compact cards must be large enough for the duplicated sequence to cover the viewport even with only two games.

Use a component-owned viewport class instead of `.carousel`: daisyUI defines that name as `inline-flex`, which shrink-wraps an inline-size query container to zero outside the Games grid. Give the viewport an explicit full inline size and contain grid minimum sizing. Browser coverage must load the real application CSS; component-only CSS missed this collision.

A focused first canonical link may already be translated before the scroll origin, where a browser cannot reveal it through scrolling alone. While focus is inside, CSS pauses both clocks, temporarily overrides their transforms, and changes the focused viewport from clipped to hidden overflow so native focus scrolling can reveal every canonical link. On exit, clipped overflow clears the temporary scroll offset and the held animation position resumes. The inset focus outline stays inside the card instead of being cut off at the viewport edge.

A pure-CSS duplicated *continuous* marquee (linear timing) was rejected because it never dwells on a slide; per-count authored keyframes were rejected because the slide count is runtime data; `scroll()`-timeline animation is prohibited by the browser policy.

### 5. Give each composition explicit and honest CSS-only motion state

Playable and Games each own one animation scope. Within a section, `:hover` and `:focus-within` set `animation-play-state: paused` on every track in that section, so the Games hero and compact rows always pause and resume together and cannot drift apart. Pause is transient by construction: when the pointer leaves or focus exits, the animation resumes from its held position. There is no persistent Pause, no Play control, no per-section manual stop, and no document-hidden pause, because none of these are expressible in baseline CSS; the issue and specifications record this reduction transparently instead of claiming unsupported behavior.

Under `prefers-reduced-motion: reduce`, track animation is removed entirely and each carousel renders its leading slides statically; non-essential card hover transitions are also removed. There is no opt-in Play under reduced motion.

A one-item collection renders one static card with no duplicated track and no animation. A zero-item collection omits its complete section.

### 6. Keep presentation CSS-owned, responsive, and script-free

All cards remain landscape. The Games presentation uses CSS rows whose visual allocation is approximately two thirds for the upper hero and one third for the lower compact strip; the hero uses a 2.9:1 aspect ratio on wide viewports and 1.9:1 below a 30rem container width so the mobile hero does not shrink to the compact row height. The Playable cards reuse the compact size variables rather than a separate grid geometry.

CSS owns shell containment, hidden overflow, viewport geometry, responsive card basis, hero/compact aspect ratios, the approximate ratio, stepped dwell and loop timing, pause state, focus-outline clearance, and reduced-motion overrides. Desktop, tablet, and mobile may show different counts of compact cards while the animation timing stays derived from the slide count alone.

The 2026-09-05 review reduces all spacing between image blocks by a factor of 1.5: compact-card gutters and the hero/compact row gap are 0.5rem instead of 0.75rem; the section separation and heading-to-card spacing are 0.6667rem instead of 1rem. Outer shell padding and card content insets remain independent of these image gaps.

Compact cards reserve a single metadata row and at most two visible title lines so narrow mobile cards do not overlap their title and categories. Category text can ellipsize visually while its full text remains in the DOM; the hero retains its larger metadata layout.

Storybook previews disable animations, transitions, and smooth scrolling through master's shared preview stylesheet. Baselines use Vitest's default screenshot and image comparison settings after loading fonts. The shared harness does not manually pause, seek, or change the playback rate of document animations and does not allow an additional mismatched-pixel ratio. Home browser tests use the same screenshot defaults without querying animations, seeking frames, changing playback, or asserting animation timing and state. The stability check retains a 15-second budget for multiple captures under full-suite load.

Svelte performs only static rendering decisions: conditional section omission, direct browse sequence rendering, the `--n` slide-count custom property, duplicated inert track copies, and existing card metadata fallback presentation. JavaScript does not own breakpoints, card widths, transform distances, timing, or pause state, and adds no listeners, observers, timers, or state.

### 7. Preserve one canonical local link and fallback presentation per delivered game

Every delivered game remains addressable at `/games/:slug`. The accessible DOM exposes exactly one canonical detail link per delivered browse entry, and it lives in the Games hero row; the compact strip is an inert decorative row hidden from the accessibility tree. Playable compact cards remain canonical local links. Loop duplicates cannot add another link anywhere.

Metadata title/image/category fields and lifecycle treatment are reused in every canonical card variant. Missing title or image keeps the generic accessible name and non-provider fallback preview. Browse presentation never implies launch eligibility.

### 8. Allocate tests by behavior and presentation

- `D20.GamesTest` exercises native `list/1` schema-field options, policy-neutral listing, bounded defaults, explicit ordering, exclusion, metadata success/fallback, and observable membership using real repository rows. It does not test a home/randomizer helper.
- `PageControllerTest` exercises the exact initial props, eight-item playable cap, no overlap, at-most-32 browse membership, flat browse entry maps, local ids, and degraded metadata without asserting an implicit database order.
- jsdom component tests cover section structure and order, canonical link uniqueness and hrefs, inert/`aria-hidden` duplicates, fallback metadata names, lifecycle badges, zero/one-item static rendering, server-order rendering, and that no Inertia request occurs. jsdom cannot honor CSS animations, so timing is not asserted there.
- Chromium/Firefox browser tests cover keyboard navigation through canonical links and exclusion of visual duplicates from tab order. Screenshots cover focused cards, narrow single-game sections, and reduced-motion presentation with application CSS loaded. Tests do not query or manipulate animations or assert browser timing, interpolation, pause/resume, or looping mechanics; ordinary multi-game layouts remain covered by Storybook screenshots.
- Deterministic Storybook states and Chromium screenshots cover desktop/tablet/mobile default, fallback, zero/one item, and multi-item layouts. Visual assertions remain screenshots/manual review rather than computed-style or geometry assertions.

## Risks / Trade-offs

- [Strict CSS-only motion removes persistent Play/Pause and manual scrolling] → Recorded transparently in the issue and specs; hover/focus-within pause and reduced-motion static rendering are the entire motion-control contract, and no unsupported behavior is claimed.
- [Two `list/1` calls can enrich metadata in separate batches] → Keep query results non-overlapping and test that failure in either batch preserves local membership and fallback cards; do not add a cache or page-specific context function.
- [Unordered bounded reads are not random or pagination] - Assert the selected count, membership, and absence of hidden launch filtering; use explicit native `order_by` for order-sensitive tests. Future pagination needs a separate contract.
- [A bounded home no longer displays the entire growing catalog] - Deliver at most eight playable and 32 browse games. Every environment-visible persisted game remains directly addressable; loading further pages is outside this review.
- [Duplicated tracks double the DOM] → Limit duplicates to inert/hidden copies required for seamless wrap and focus runway; assert one canonical accessible detail link per delivered game.
- [Two independently animated rows could drift] → Both rows share identical dwell duration and step count derived from the same slide count, and pause state is scoped to the whole section so rows always pause and resume together; automated tests do not retest browser animation mechanics.
- [CSS animations run while the document is hidden] → Browsers throttle off-screen animations; no script visibility tracking exists by design and none is claimed.
- [A hidden scrollbar weakens the overflow cue] → The viewport is not user-scrollable by design; canonical links remain keyboard reachable and focused cards are revealed through the duplicated-track runway, which browser tests verify.
- [No autoplay status announcements] → There is no selected-index state to announce; canonical links carry their own accessible names, and no dynamic live region exists.

### 9. Two stages and environment-owned visibility (2026-09-07)

Creating a catalog row already means in-development work; remove the separate planned stage. Use only `in_development` and `released`, with in-development as the schema/database default. Only released rows require an engine. Keep `enabled` independent as the new-Session kill switch.

Remove the custom `allow_launch_in_development` option and its helper. Store the application environment with standard `config_env()`; this is the environment identity, not another launch toggle, and is available in releases without runtime Mix calls. A shared visible-stage list returns both enum stages only for `:dev`, and released for all other environments. Use this inside catalog context queries and new-Session authorization. Tests vary the application environment with cleanup and verify both dev and production behavior.

Keep `Games.list` and direct record lookup unfiltered for internal/admin callers. Public home restricts both collections by visible stage before the limit. Public detail returns 404 for an unreleased record outside development unless opening a validated, matching existing Session. Merely supplying a session parameter cannot bypass this check. Both creation endpoints keep returning 403 for denied launches, independently of metadata. Existing module bootstrap and active session workspace remain accessible after stage/enabled edits.

The forward migration drops the old stage and engine-required checks, changes planned rows to in-development with one declarative SQL UPDATE, changes the database default, and installs the two-stage/only-released-requires-engine checks. Preserve ids, BGG bindings, enabled state, timestamps, and all engine integer mappings. Do not special-case any game or engine. Preserved registered bindings remain eligible under the existing dev policy, even when engine init returns not_implemented; migration does not infer engine readiness. Queue the SQL updates through execute/1 without explicit flush calls. Do not change the historical applied migration. Rollback maps engine-less in-development rows to planned before restoring the old checks/default. It cannot reconstruct which engine-bound rows were originally planned; record this semantic loss instead of inventing compatibility storage.

Update frontend stage types, deterministic development fixtures, admin enum expectations, and nearby tests. Existing in-development badges now apply to former planned browse cards. Below an 11rem card width, omit categories from the inert decorative in-development copy so they do not collide with the status badge; retain categories on the canonical hero card. Preserve all carousel motion, spacing, and the shared screenshot defaults.

## Migration Plan

1. Record the resolved row mapping and the CSS-only decision in issue #264 and these artifacts.
2. Replace home-specific `D20.Games` functions with `list/1` query options and repository-bound tests, then compose/serialize the same Inertia props inline in `PageController`.
3. Replace the Playable grid and Games group grid with the CSS stepped-loop strips, duplicated inert tracks, CSS pause state, and responsive geometry.
4. Update focused component/browser tests, deterministic stories, and reviewed desktop/tablet/mobile baselines.
5. Run targeted checks, browser policy commands, broad repository validation, strict OpenSpec validation, reconcile all acceptance criteria, and archive the same change only after implementation is complete.

For the two-stage follow-up, migrate before serving the new enum; validate up/down/up in an isolated test partition. Rollback follows decision 9 and has the documented stage information loss. No cache, external integration, or persisted carousel state is introduced.

## Open Questions

None. CSS-only motion remains unchanged. The 2026-09-06 user clarification resolves the SQL/random conflict by requesting ordinary unordered, bounded Ecto reads. Limits, explicit schema-field conditions, and inline provider-result handling are recorded above.

### 10. Catalog option validation structure (2026-09-07)

Normalize options directly into a keyword list using the default values and only the supported keys. Clamp integer limits to 0..100; use 32 when the limit is missing, nil, or non-integer. Unknown keys are ignored. Remove the validation with/else, its intermediate tuple, and custom option errors. Query construction reads the normalized limit from the same keyword list. Ecto continues validating where/order_by values. Metadata fallback stays local, and the public return shape is unchanged.

### 11. Home component readability (2026-09-07)

Let TypeScript infer browse count and slide-array types from typed props and computations. Remove script comments explaining these derivations. Inline the canonical link and decorative card wrappers in their respective loops so classes, hrefs, and accessible labels are visible at the render site. Inline image, metadata, and fallback markup in each card variant as well. Do not retain card snippets. Preserve rendered structure, title ids, link identities, inert duplicates, and CSS behavior. Verify with the existing home component tests, frontend typecheck and lint/format checks, and the prepared development page when available.

### 12. Catalog controller boundary (2026-09-07)

Expose list_playable(limit) and list_browse(excluded_ids) as public domain operations. Keep all Ecto query construction and schema engine enumeration inside D20.Games. Reuse the policy-neutral list/1 loading and metadata path; preserve the eight-playable/32-browse limits, ordering, exclusions, environment visibility, and fallback behavior. The controller receives catalog entries and retains its existing response serialization. This correction is scoped to catalog queries; existing changeset error responses are unchanged.

### 13. Flat browse response (2026-09-07)

Return games as a flat array of at most 32 maps matching GameCatalogEntry. Remove browseGroups, GameBrowseGroup, controller chunking, synthetic group ids, and client flattening. Keep the default catalog limit and domain query boundary unchanged. The client derives slide copies directly from the array and uses its length for loop count. Update fixtures, stories, component/browser inputs, and controller assertions in the same change. No compatibility wrapper, layout change, metadata shape change, or baseline refresh is required.

### 14. Integrate the current master baseline (2026-09-08)

Fast-forward the owning worktree from `28abd98` to pinned local master `e121780` after saving tracked, staged, and untracked changes in a recoverable snapshot. Reapply and adapt the same uncommitted delivery. Preserve master's stable `slug` field, create/update validation, slug lookup and public `/games/:slug` routes. Carry `slug` through both flat home props and fixtures; retain `id` for internal identity and keyed rendering. Master's Storybook preview stylesheet suppresses motion; keep that behavior together with the simplified screenshot tests. Preserve the two-stage migration and environment visibility, normalized bounded catalog options, context-owned queries, inline card markup, and all unrelated master changes.

Validate focused catalog/schema/controller/module/admin and home tests, migration up/down/up using a fresh isolated test partition, then `just check` and strict OpenSpec validation. Keep a recoverable pre-update snapshot and the adapted work uncommitted. This updates the worktree base; it does not transfer or publish the delivery to master, remove the worktree, or change shared development databases. Existing section 23 finalization gates remain separate.


### 15. Commit and integrate with the current master

The 2026-09-08 transfer request authorizes a local semantic commit and linear integration. Rebase on pinned master `72afec0`, preserve the new footer and public information pages, adapt the home story overlap, and review affected visual references before normal comparison runs. Keep diagnostic-only captures outside Git. Reconcile the remaining delivery gates using isolated persistence validation and available prepared-page inspection; known unchanged Credo findings remain documented. Validate the integrated target before retiring the worktree, and do not publish remote branches.
