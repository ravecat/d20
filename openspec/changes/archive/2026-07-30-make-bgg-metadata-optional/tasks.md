## 1. Registry Boundary

- [x] 1.1 Confirm registry list and fetch operations remain independent of display metadata.
- [x] 1.2 Keep `D20.Games.Registry.Entry` limited to stable operational bindings and leave fallback display fields empty.

## 2. Optional BGG Configuration

- [x] 2.1 Add source adapter tests proving that missing and empty API keys return a stable configuration error without executing an HTTP request.
- [x] 2.2 Update `D20.Games.Sources.BoardGameGeek` to reject unusable credentials before building or sending a request while preserving current HTTP and parse error contracts.
- [x] 2.3 Retain the production startup failure for a missing `BGG_API_KEY` and document the variable as optional catalog enrichment outside production in `envs/.env.example` and nearby setup documentation where applicable.

## 3. Metadata Composition

- [x] 3.1 Add `D20.Games` tests for empty fallback on missing credentials, HTTP failure, parse failure, and a BGG batch response that omits one registered game while enriching others.
- [x] 3.2 Select successful BGG attributes or empty fallback attributes before one `Game.new/1` call in `D20.Games.fetch_by_slug/1` and `D20.Games.list/0` without changing catalog membership or ordering.
- [x] 3.3 Add sanitized context-level logging for degraded metadata resolution and test that failure logs do not contain credentials or authorization headers.

## 4. Web Behavior

- [x] 4.1 Add controller tests proving the home page returns the complete catalog with nameless fallback entries without BGG credentials or availability instead of an empty list.
- [x] 4.2 Add controller tests proving registered game detail pages render fallback metadata and launch controls without BGG, including the valid existing-session flow.
- [x] 4.3 Preserve `404 Not Found` for unknown slugs and add or retain focused regression coverage that distinguishes registry absence from provider failure.
- [x] 4.4 Run the existing Svelte game-page fallback tests and change frontend code or types only if they do not already support the unchanged props with absent provider fields.

## 5. Validation

- [x] 5.1 Format touched Elixir files with `mix format <files>` and verify them with `mix format --check-formatted <files>`.
- [x] 5.2 Run `mix test test/d20/games/registry_test.exs test/d20/games/sources/board_game_geek_test.exs test/d20/games_test.exs test/d20_web/controllers/page_controller_test.exs`.
- [x] 5.3 Run `bun run test -- js/pages/game_pages.test.ts` from `assets/` and run `mix typecheck` if frontend sources or types change.
- [x] 5.4 Run `just check` after targeted validation and report any unrelated pre-existing failure separately.
