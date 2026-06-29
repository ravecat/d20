## 1. Registry Configuration

- [x] 1.1 Add `D20.Games.Registry` configuration with `games: [qwinto: [engine: D20.Qwinto.Game, bgg_id: 183_006, sandbox: [...]]]`.
- [x] 1.2 Implement a registry module that lists games and fetches full game entries by internal slug.
- [x] 1.3 Validate registry entries for slug format, engine module contract, integer `bgg_id`, and list-based sandbox policy.
- [x] 1.4 Update `D20.Games` and `D20.Games.Game` so stable game records come from the registry rather than hard-coded mock metadata.
- [x] 1.5 Add targeted tests for registry listing, slug lookup, missing slug behavior, invalid engine behavior, and sandbox lookup.

## 2. Runtime BGG Metadata

- [x] 2.1 Add a BGG metadata fetch path that retrieves a game by configured BGG id using `Authorization: Bearer <BGG_API_KEY>`.
- [x] 2.2 Reuse or extend the existing BGG XML parser to produce runtime display metadata including title, preview image, description, and player metadata when available.
- [x] 2.3 Define metadata source errors for missing source config, failed HTTP request, empty BGG response, and parse failure.
- [x] 2.4 Ensure metadata resolution uses `bgg_id` directly and does not search by title during normal rendering.
- [x] 2.5 Add tests for successful BGG metadata resolution and source error cases without making live network calls.

## 3. Route, Session, and Iframe Integration

- [x] 3.1 Replace session engine lookup from `D20.Module.Manifest.fetch_engine/1` with `D20.Games.Registry` lookup.
- [x] 3.2 Replace iframe sandbox lookup from `D20.Module.Manifest.fetch/1` and `priv/modules/registry.json` with game registry sandbox lookup.
- [x] 3.3 Preserve `/games/:slug` route behavior for existing game pages and session URLs.
- [x] 3.4 Remove `D20.Module.Manifest` and `priv/modules/registry.json` after all call sites are migrated.
- [x] 3.5 Update controller and channel tests that currently assume `D20.Module.Manifest` owns engine or sandbox lookup.

## 4. Games Page Catalog

- [x] 4.1 Update the `/games` data path so the catalog is derived from registry games enriched with runtime metadata.
- [x] 4.2 Render each catalog entry as a game tile with a preview area.
- [x] 4.3 Render runtime title and preview image when metadata is available.
- [x] 4.4 Render a fallback preview state when resolved runtime metadata does not include a preview URL.
- [x] 4.5 Ensure catalog entries link to `/games/:slug` and do not expose BGG id as the application route identity.
- [x] 4.6 Update frontend types, components, and tests affected by changed game props.

## 5. Game Detail Page

- [x] 5.1 Ensure activating a `/games` catalog tile navigates to `/games/:slug`.
- [x] 5.2 Update the `/games/:slug` data path so the detail page resolves the registered game by slug and enriches it with runtime metadata.
- [x] 5.3 Render runtime title, preview image, and description on the detail page when metadata is available.
- [x] 5.4 Render detail fallback UI when resolved runtime metadata omits optional presentation fields.
- [x] 5.5 Preserve session start behavior from the detail page when the configured engine is valid.
- [x] 5.6 Add controller and frontend tests for registered detail pages, missing detail pages, metadata rendering, optional metadata fields, and tile navigation.

## 6. Validation

- [x] 6.1 Run targeted backend tests for `D20.Games`, `D20.Games.Registry`, BGG metadata, page controller, and session creation.
- [x] 6.2 Run targeted frontend tests or type checks for changed `/games` and `/games/:slug` props/components.
- [x] 6.3 Run `mix format --check-formatted` for Elixir changes.
- [x] 6.4 Run `just test` after targeted tests pass.
- [ ] 6.5 Run broader `just check` if frontend or cross-cutting behavior changed beyond targeted coverage.
  - Blocked: `just check` currently fails in `mix format.check` on existing formatting in `test/d20/qwinto/game_test.exs`, which is outside this change.
