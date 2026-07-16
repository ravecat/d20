## Why

Next Station: London is registered with `D20.NextStationLondon.Game`, but the engine still returns `:not_implemented`, so the catalog entry cannot host a playable session. The publisher's rulebook and map provide enough reviewed detail to specify the complete base game, solo scoring, both advanced modules, and a machine-readable map before implementation starts.

## What Changes

- Replace the Next Station: London placeholder with a server-authoritative engine for 1 to 4 fixed players stored in one participant-id-keyed map, 4 rounds, simultaneous section choices, automatic card and pencil preparation, line rotation, and terminal scoring.
- Encode the publisher map as reviewable static data for stations, districts, departure stations, tourist sites, legal sections, section intersections, and Thames crossings.
- Validate section construction, destination symbols, the central wild station, Joker cards, the Railroad Switch, passing, line branching, station reuse, duplicate sections, and crossings against committed player networks.
- Score each colored line, tourist visits, 2-line through 4-line interchanges, final totals, multiplayer tie breakers, and solo achievement bands.
- Support optional Shared Objectives and Pencil Powers through top-level `objectives` and `powers` creation attrs and aggregate fields, including their setup, action legality, scoring, and solo penalties.
- Add caller-specific permissions and projections, a custom server boundary for automatic randomized round preparation, an AsyncAPI contract, registry activation, and layered implementation tests.
- Implement the separate Svelte iframe client against the caller-specific projection, including the bundled map, route overlays, all setup and construction controls, advanced modules, score presentation, responsive layout, and browser tests.
- Keep the generic session lifecycle, public routes, persistence model, iframe sandbox contract, and unrelated game namespaces unchanged.

## Capabilities

### New Capabilities

- `next-station-london-map-data`: Defines the exact machine-readable London map, Station deck, scoring tables, and static integrity rules.
- `next-station-london-gameplay`: Defines the unordered players map, setup, automatic card flow, simultaneous construction, legality, scoring, projections, permissions, and runtime integration.
- `next-station-london-advanced-modules`: Defines Shared Objectives, Pencil Powers, and their multiplayer and solo effects.
- `next-station-london-client`: Defines the separate playable iframe client and its projection-driven interaction, accessibility, and deployment requirements.

### Modified Capabilities

- None.

## Impact

- Affected backend modules: `D20.NextStationLondon.Game`, new `Command`, `Rules`, `Ruleset`, `Permission`, `Projection`, and `Server` modules, plus explicit routing in `D20Web.Projection`.
- Affected runtime and public contract: the existing `next-station-london` registry entry becomes an `in_progress` catalog preview, remains launchable only outside production, and gains `priv/specs/next-station-london.yaml` and developer-contract-index coverage.
- Affected game client: `/home/max/apps/next_station_london` gains the D20 SDK adapter, typed projection model, playable Svelte UI, browser tests, and production endpoint configuration.
- Affected source assets: the publisher map remains a review source while the game client continues bundling its own board SVG; generated and user-supplied D20 static files remain untouched.
- Affected tests: new static-data, command, rule, reducer, permission, projection, custom-server, session, channel, registry, contract, client-store, and browser interaction tests.
- No database migration or persisted-game-state migration is required.
- Runtime compatibility risk is limited to the currently non-functional placeholder: errors change from `:not_implemented` to stable game-specific validation reasons.
- Rollback is a code, configuration, contract, and source-asset revert with no data rollback.
