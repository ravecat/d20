## Why

Tracking issue: [#272](https://github.com/ravecat/d20/issues/272).

Home Games previously selected the local backlog instead of discovering games independently through BGG. This change adds Hot discovery with optional local association and internal detail pages for provider-only games, with the Games context supplying the route identifier.

## What Changes

- Preserve implemented local list/playable options, provider Hot discovery, bounded detail fetching, four-field BGG-keyed catalog maps, and independent home collections.
- **BREAKING** Make catalog `slug` a non-null internal route identifier: the visible local record's persisted slug or the BGG ID as a decimal string. Keep catalog `id` numeric BGG identity and `stage` nullable.
- Give every home card the same internal `/games/:slug` Inertia link; remove external BGG URL selection and the conditional `fromAction` attachment.
- Resolve detail routes by exact local slug first. When no slug matches, pass the original string directly to `BoardGameGeek.fetch_game/1`, let the provider response determine resolution, and derive the resulting route slug from its returned BGG ID. Do not perform an additional local lookup by BGG ID: the numeric fallback remains metadata-only even if a row uses that BGG ID under a different stored slug.
- Render provider-only details with metadata, null local identity/stage, and no Play, creation schema, or Session. Preserve local visibility, launch authorization, existing Session access, and provider error contracts without creating database rows.
- Keep inline context fallback and simplify both provider functions to pass supplied ID values without type/positivity/syntax validation. Use one fetch_game path through fetch_games, inline Enum.uniq(ids) at the batch call, and return parsed provider items without matching them back to input values. Preserve empty-list, HTTP, batching, and caller catalog-selection behavior.
- Defer the replacement for Play on provider-only pages; do not add a placeholder or new CTA.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `game-catalog`: Server-resolved internal route slugs and optional local association within the existing catalog map.
- `home-game-discovery`: Uniform internal Inertia links and accessible provider-only cards.
- `game-catalog-availability`: Nullable local stage with internal provider details while preserving local visibility.
- `game-metadata-fallback`: Local enrichment fallback versus provider-only detail existence and failure behavior.
- `runtime-game-metadata`: Shared unvalidated scalar/list request flow, provider-result ordering, and existing Hot/batching/error behavior.
- `game-detail`: Local-first slug resolution, numeric BGG fallback, and provider-only detail props.
- `game-session-launch-policy`: Provider-only details cannot create or attach Sessions and expose no Play control.

## Impact

Implementation touches `lib/d20/games.ex`, `lib/d20_web/controllers/page_controller.ex`, home/detail Svelte props and navigation, and their tests/fixtures. Routes retain `/games/:slug`; persisted TypeIDs, Session/runtime and iframe contracts, dependencies, configuration, and migrations remain unchanged. No new Game struct, provider framework, cache, or fake engine is needed. The user authorized implementation after reviewing the specification and confirmed that slug always remains a string, whether a readable alias or a decimal BGG ID. Complete the remaining implementation and validation tasks, then synchronize and archive the same change. The user approved committing the complete change and transferring the local branch into master after review. Stage implementation, tests, fixtures, synchronized specifications, and the owning archived artifacts in the same semantic commit. Track integration and validation evidence in issue #272; publication is outside this request.
