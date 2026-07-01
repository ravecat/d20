## 1. Metadata Contract

- [x] 1.1 Verify that `/games/:slug` Inertia props expose `minPlayers`, `maxPlayers`, `playingTime`, `minPlayTime`, `maxPlayTime`, `minAge`, `complexity`, and `rating` from runtime game metadata.
- [x] 1.2 Add or update source parser and controller coverage for metadata fields that are not currently serialized to the game detail page.
- [x] 1.3 Keep client-side formatting helpers inside the metadata Svelte label components without hardcoded game-specific fallbacks.

## 2. Detail Layout

- [x] 2.1 Update `assets/js/pages/game.svelte` so the content below the preview uses a desktop 2fr/3fr grid split with activation on the left and description on the right, without surrounding panel borders.
- [x] 2.2 Make the description panel internally scrollable for long descriptions while preserving normal stacked page flow on narrow viewports.
- [x] 2.3 Add 1.125x users and clock icon treatments to the activation metadata row without introducing a new frontend dependency.
- [x] 2.4 Render player-count and play-time infographic labels through dedicated Svelte components that receive the `GameMetadata` object.
- [x] 2.5 Render metadata labels as chips and avoid hardcoded localized unit text.
- [x] 2.6 Place metadata label components directly in the game page activation row without an intermediate proxy component.
- [x] 2.7 Let metadata label components decide whether to render DOM, without page-level metadata visibility helpers.
- [x] 2.8 Add dedicated age and complexity metadata label components that receive the `GameMetadata` object.
- [x] 2.9 Add a dedicated BGG rating metadata label component that receives the `GameMetadata` object.

## 3. Activation And Players

- [x] 3.1 Move page-level activation UI so the left panel owns the metadata row and no-session primary CTA.
- [x] 3.2 Implement the no-session `Play` CTA so it creates a session and spans the available activation width.
- [x] 3.3 Render the existing `SessionPanel` inside the activation column for active sessions without changing its public props API or session ownership.
- [x] 3.4 Preserve existing session channel commands, `/games/:slug/sessions`, `SessionPanel` props, module props, and iframe connection behavior while styling the panel-owned `Start` action like the page primary CTA.

## 4. Validation

- [x] 4.1 Update `assets/js/pages/game_pages.test.ts` for metadata display, `Play` session creation, split layout structure, and fallback metadata behavior.
- [x] 4.2 Keep `assets/js/components/session_panel.test.ts` focused on the existing `SessionPanel` API and behavior.
- [x] 4.3 Run the targeted frontend tests with `cd assets && bun run test -- js/pages/game_pages.test.ts js/components/session_panel.test.ts`.
- [x] 4.4 Run `mix typecheck`.
- [x] 4.5 Run `mix assets.test`.
- [x] 4.6 Run `mix test test/d20_web/controllers/page_controller_test.exs` if backend serialization or controller behavior changes.
