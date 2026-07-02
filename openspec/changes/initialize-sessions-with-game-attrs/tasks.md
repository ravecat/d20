## 1. Backend Game Creation Contract

- [x] 1.1 Remove registry-owned `attrs` config and struct fields from `D20.Games.Registry`.
- [x] 1.2 Add optional game-owned creation attrs callbacks/helpers in `D20.Game`.
- [x] 1.3 Make `D20.Game` reject non-empty creation attrs for engines that do not support them.
- [x] 1.4 Update registry and page controller tests to expect attrs from the game engine, not registry config.

## 2. Session Initialization Flow

- [x] 2.1 Update `D20.Sessions.create/4` to accept raw creation attrs and pass them into `Session.new/3`.
- [x] 2.2 Update `D20.Sessions.Session.new/3` to initialize the hosted game before starting the session process.
- [x] 2.3 Ensure invalid creation attrs return an error before `D20.Sessions.Server` starts.
- [x] 2.4 Preserve `D20.Sessions.create/3` compatibility for games with empty attrs if useful for existing call sites.

## 3. Koala Rescue Club Creation Attrs

- [x] 3.1 Add a Koala-owned creation attrs schema or changeset for required `sheet`.
- [x] 3.2 Expose Koala creation attrs description from the game engine using `Ruleset.sheets/0`.
- [x] 3.3 Initialize Koala game state with the selected sheet during session creation.
- [x] 3.4 Update Koala join behavior so player sheets use the selected sheet before start.
- [x] 3.5 Update Koala start command validation and reducer so `start` does not require or apply `sheet`.

## 4. HTTP and Frontend Flow

- [x] 4.1 Update `POST /games/:slug/sessions` to pass submitted attrs into session creation.
- [x] 4.2 Return a user-visible Inertia error when creation attrs are invalid.
- [x] 4.3 Move attrs controls from `SessionPanel` to the no-session Play form on `assets/js/pages/game.svelte`.
- [x] 4.4 Submit Play with `FormData` attrs to `POST /games/:slug/sessions`.
- [x] 4.5 Update `SessionPanel` so Start sends no game creation attrs.
- [x] 4.6 Update TypeScript types to model engine-provided creation attrs props.

## 5. Tests

- [x] 5.1 Add backend tests that valid Koala sheet attrs create a session initialized with that sheet.
- [x] 5.2 Add backend tests that invalid Koala sheet attrs do not create a session process.
- [x] 5.3 Add session lifecycle tests that Koala starts without `sheet` in the start command.
- [x] 5.4 Add controller tests that Play posts attrs to session creation and redirects to the session URL.
- [x] 5.5 Add frontend tests that the game detail Play form renders attrs and posts selected values.
- [x] 5.6 Update SessionPanel tests so Start calls `session.start()` without attrs.

## 6. Validation

- [x] 6.1 Run `mix test test/d20/games/registry_test.exs test/d20/sessions/session_test.exs test/d20/sessions_test.exs test/d20/koala_rescue_club/game_test.exs test/d20_web/controllers/page_controller_test.exs`.
- [x] 6.2 Run `npm test -- js/components/session_panel.test.ts js/pages/game_pages.test.ts` from `assets`.
- [x] 6.3 Run `npm run typecheck` from `assets`.
- [x] 6.4 Run `mix test`.
- [x] 6.5 Run `npm test` from `assets`.
- [x] 6.6 Run `git diff --check`.
