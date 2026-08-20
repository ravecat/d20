## Why

Playable games are currently described across multiple places: mocked metadata in `D20.Games`, engine mapping in `D20.Module.Manifest`, and iframe sandbox settings in `priv/modules/registry.json`. This makes it unclear which data actually defines an implemented game and creates drift between game availability, engine startup, iframe framing, and external BGG metadata.

## What Changes

- Introduce a game registry as the source of truth for implemented playable games.
- Represent each implemented game with only stable configuration fields: internal slug, engine module, BGG id, and per-game iframe sandbox policy.
- Treat title, preview image, description, player counts, and other display metadata as runtime-derived data, primarily resolved from BGG using the configured BGG id.
- Replace the engine lookup currently stored under `D20.Module.Manifest` with game registry lookup.
- Replace the separate static iframe sandbox registry JSON with per-game sandbox configuration in the game registry.
- Preserve existing `/games/:slug` routes and session behavior; slugs remain internal application identifiers.
- Keep BGG id as an external metadata binding, not as the primary application identifier.

## Capabilities

### New Capabilities

- `playable-game-registry`: Defines how implemented games are declared and resolved by internal slug, engine module, BGG id, and iframe sandbox policy.
- `runtime-game-metadata`: Defines how display metadata such as title and preview image is resolved at runtime from external game metadata.
- `game-catalog`: Defines how the `/games` catalog lists playable games using registry entries enriched with runtime metadata.
- `game-detail`: Defines how users navigate from a catalog tile to a game detail page backed by the registry and runtime metadata.

### Modified Capabilities

- None. There are no existing OpenSpec capabilities yet.

## Impact

- Affected backend modules: `D20.Games`, `D20.Games.Game`, `D20.Module.Manifest`, `D20Web.PageController`, and session creation paths that resolve an engine by slug.
- Affected configuration: `config/config.exs` game/module configuration and `priv/modules/registry.json`.
- Affected UI: the `/games` game catalog and `/games/:slug` game detail page should render from playable registry entries enriched with runtime metadata.
- No database migration is required for this change.
- No route contract change is intended; `/games/:slug` remains the public game URL.
- Runtime compatibility risk: synchronous BGG metadata resolution means `/games` catalog and `/games/:slug` rendering depend on resolvable BGG metadata unless caching or asynchronous loading is added later.
- Rollback impact: the previous mock metadata and module manifest lookup can be restored if the registry introduces resolution regressions.
- Completion and archival of this historical change are tracked by [GitHub issue #153](https://github.com/ravecat/d20/issues/153).
