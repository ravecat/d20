## Why

Tracking issue: [#264](https://github.com/ravecat/d20/issues/264).

The first #264 implementation separates playable and browseable persisted games, but its grid-and-group carousel no longer matches the requested discovery experience. The same delivery outcome now needs an accessible, continuously looping landscape-card composition whose advancement, looping, pausing, and reduced-motion behavior is owned entirely by CSS, inspired by Apple's current “Endless entertainment” section, while retaining D20-owned catalog selection, initial-response-only data, local detail routes, and the repository browser baseline.

## What Changes

- Commit and transfer the existing home work onto current local master, including the footer delivered at `72afec0`, preserving the flat props, two-stage model, option normalization, inline markup, and screenshot-only presentation coverage. Adopt master's stable public game slugs, Storybook preview motion suppression, and session command dispatch.

- Move catalog query construction from PageController into `Games.list_playable/1` and `Games.list_browse/1`; the controller passes ordinary limits and ids and serializes the results.

- Simplify home source readability with inferred derived-value types, no derivation-explanation comments, and fully inline card markup without snippets.

- Normalize supported catalog options directly into a keyword list with defaults; ignore unknown keys, clamp integer limits to 0..100, and default nil/non-integer limits to 32. Keep metadata fallback local to enrichment.

- Simplify persisted stages to `in_development` (default, engine optional) and `released` (engine required). Migrate existing planned rows without changing ids, enabled state, or any engine binding. Keep migration logic independent of specific games.
- Remove `allow_launch_in_development` and its helper. Derive public visibility and launch eligibility from the application environment: development sees both stages; production sees only released games. Keep `Games.list` policy-neutral with explicit caller conditions, independent enabled state, and existing-session access.

- Make `Games.list()` a bounded, unfiltered catalog query: at most 32 records by default, no implicit ordering or randomization, and a maximum effective limit of 100. Accept native Ecto `where` and `order_by` values without a domain-filter alias; define the option shape inline in `@spec list`, compose the query inline, and remove the separate list-option type, all catalog SQL fragments, and custom ordering/filter helper machinery.
- Reduce spacing between image cards and rows by approximately one third: compact-card and row gaps become 0.5rem, and the spacing around the intervening section heading becomes two thirds of its former 1rem. Refresh responsive screenshots and verify them without baseline updates using the screenshotter's default animation handling and comparison settings.
- Correct the Storybook review defects: keep Playable visibly sized independently of daisyUI's `.carousel` utility, hold each slide for about five seconds, then interpolate a short eased slide movement before settling. A bare `steps()` jump does not satisfy the motion requirement. Verify visible cards and short collections through screenshots with application CSS loaded; do not inspect or manipulate browser animation timelines.
- Keep the conditional home sections named `Playable` and `Games`, omitting each complete section when its collection is empty.
- Replace the Playable grid with an independently auto-advancing, continuously looping strip of compact landscape cards driven entirely by a CSS keyframe animation.
- Replace the Games group-grid carousel with a two-row composition: a large landscape hero row occupying roughly two thirds of the presentation and a compact landscape strip occupying roughly one third. Both rows derive from the same lossless ordered browse sequence, use identical CSS dwell duration and step count so they advance together, and loop seamlessly.
- Make carousel behavior strictly CSS-owned: CSS keyframes advance one slide after an approximately five-second dwell, loop continuously, pause while the pointer hovers or keyboard focus is inside the carousel, and stop animating under `prefers-reduced-motion: reduce`. Svelte renders static markup only; it adds no carousel state, timers, listeners, observers, synchronization, document-visibility tracking, dynamic ARIA status, Previous/Next, or Play/Pause controls.
- Put every canonical detail link in exactly one row: Games hero cards own the `/games/:slug` links while the compact strip is an inert decorative synchronized visual; Playable compact cards own their own links. Duplicated loop tracks and the compact strip are `aria-hidden`, inert, non-focusable, and contribute no duplicate link or control.
- Return flat `playableGames` and `games` arrays in the initial Inertia response. Browse contains at most 32 catalog-entry maps without group wrappers or synthetic ids. The client renders the delivered sequence without flattening, fetching, filtering, shuffling, or changing membership.
- Inline metadata batching, schema validation, fallback, and entry assembly in `Games.list/1`, using the provider's existing result instead of artificial `:available`/`:unavailable` arguments or single-use catalog metadata helpers. Keep `{:ok, entries}`, logging semantics, and the Inertia prop shapes. Home requests up to eight playable games and up to 32 other visible games through domain APIs; the context owns released/in-development and id ordering and the browse exclusion query. Serialize each selected record inline in PageController without grouping.
- Keep CSS responsible for responsive geometry, overflow containment, dwell and loop timing, pause state, and reduced-motion styling. Use Svelte only for static rendering decisions: conditional sections, direct sequence rendering, the slide-count custom property, and duplicated inert tracks.
- Preserve keyboard access to every canonical link with visible focus, stable `/games/:slug` links, metadata fallback, and exactly one accessible detail link per delivered game.
- Keep the production path within `baseline widely available with downstream`. Do not make `::scroll-button()`, CSS anchor positioning, scroll snap events, container scroll-state queries, or scroll-driven animations primary behavior.
- Treat <https://www.apple.com/> and <https://aarontgrogg.github.io/NoLoJS/components/css-carousel/animated-hero/index.html> only as visual and behavioral references; do not copy Apple assets or source code, and do not treat either page as an exact technical implementation target.
- Keep component coverage for content, local links, empty/single-item states, metadata fallback, and no presentation-time requests. Use Chromium/Firefox browser tests for keyboard navigation and screenshots, including reduced-motion presentation, and desktop/tablet/mobile Storybook screenshots for layout. Do not test browser animation timing, play state, interpolation, or cycle mechanics.

## Rationale

On 2026-09-06 the user clarified that ordinary unordered `Repo.all` behavior is desired, not random sampling. This supersedes complete-catalog default reads and database-randomized browse membership. The 32-record default and 100-record maximum bound database results and metadata batches; omitted conditions include every lifecycle/availability category in the candidate set. The follow-up review removes the `filter: :playable` alias entirely: callers express fields through native `where`, and the catalog domain APIs own the enabled/stage/engine conditions before the limit.


The user directed that carousel behavior be achieved only with CSS and that apple.com serve as a visual and behavioral reference. The previously drafted Svelte-owned design (canonical indices, dwell timers, row synchronization, scroll reconciliation, visibility tracking, dynamic status, and script-driven Previous/Next and Play/Pause controls) is therefore superseded. Requirements from that design that a strict CSS-only implementation cannot honor were removed transparently in the owning issue and specifications rather than claimed or smuggled back in through script.

## Capabilities

### New Capabilities

None. This reactivates and continues the previously archived #264 change; it does not create a parallel capability.

### Modified Capabilities

- `home-game-discovery`: Replace the grid/group carousel presentation with CSS-owned looping compact and hero/compact compositions, CSS-state pausing, static reduced-motion behavior, and updated accessibility/testing requirements.
- `game-catalog`: Bound catalog reads, use a native Ecto query-option subset with explicit schema-field conditions, and remove implicit catalog/random ordering.
- `game-catalog-availability`: Keep lifecycle presentation and explicit schema-field launch selection without imposing a default lifecycle order on catalog reads.
- `game-session-launch-policy`: Use stage and application environment without a launch feature flag; preserve existing sessions.
- `storybook-component-catalog`: Represent only the two supported stages.
- `game-metadata-fallback`: Preserve every selected entry and its local link when runtime metadata is missing, within the database result limit.

## Impact

- Backend implementation scope includes the game schema, a forward data/constraint migration, environment configuration, module/controller authorization tests, and admin enum expectations.
- Backend implementation scope: `D20.Games` query composition, `D20Web.PageController` inline home projection/serialization, and focused repository/controller tests. Replace the browseGroups envelope with games across the controller and client together; no compatibility envelope remains.
- Frontend implementation scope: `assets/js/pages/home/ui/home.svelte`, existing shared types only if presentation typing requires it, focused component/browser tests, Storybook fixtures/stories, and reviewed responsive baselines.
- Dependencies and browser policy: no new dependency; use current Svelte 5, CSS keyframes with stepped timing, `animation-play-state` pauses on `:hover`/`:focus-within`, `prefers-reduced-motion`, inert duplicated tracks, and the resolved `baseline widely available with downstream` targets.
- Compatibility and rollback: ids, metadata ownership, enabled state, and running-session contracts remain unchanged. Apply the stage migration before serving the new enum. Rollback restores the old default/domain and maps engine-less in-development rows to planned; the removed planned/in-development distinction is not reconstructed; every engine binding is preserved. No shared database reset is permitted.
