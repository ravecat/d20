## Why

Registered games currently depend on a successful synchronous BoardGameGeek metadata request to render. A missing `BGG_API_KEY`, invalid credentials, or a BGG outage makes playable game pages return `404 Not Found` and can empty the home catalog even though the local game registry and engines remain available.

## What Changes

- Make BoardGameGeek metadata optional enrichment instead of an availability dependency for registered games.
- Keep display metadata out of the registry and use an empty `GameMetadata` fallback when BGG is unavailable.
- Return complete registry-backed catalog entries when BGG configuration, requests, responses, or parsing are unavailable, while preserving any successfully resolved metadata and allowing fallback cards to be nameless.
- Render registered game detail pages and keep session launch and reconnection available with fallback metadata.
- Reserve `404 Not Found` for slugs absent from the local registry rather than metadata-provider failures.
- Treat a missing `BGG_API_KEY` as a supported degraded state outside production and avoid making an unauthorized external request when it is absent, while retaining fail-fast production configuration.
- Preserve existing routes, Inertia prop shapes, session behavior, and iframe module contracts.

## Capabilities

### New Capabilities

- `game-metadata-fallback`: Defines graceful-degradation behavior for the catalog and registered game detail pages when BGG enrichment is unavailable.

### Modified Capabilities

- None. The repository has no archived baseline capability specs; this change supersedes the current provider-required behavior through the new fallback capability.

## Impact

- Affected configuration and backend modules: `config/runtime.exs`, `D20.Games`, and `D20.Games.Sources.BoardGameGeek`.
- Affected web behavior: home catalog and both `/games/:slug` detail flows, including detail pages with an existing session.
- Tests will cover missing credentials, upstream failures, partial batch results, registered detail fallback, catalog completeness, and unknown-slug `404` behavior.
- No database migration, public route change, persistence change, session/runtime contract change, or iframe module contract change is required.
- Rollback is configuration and code only, but it restores the current risk that metadata-provider failures make registered games unavailable.
