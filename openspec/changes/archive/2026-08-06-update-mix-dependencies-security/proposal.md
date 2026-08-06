## Why

The current `mix.lock` resolves packages with known Hex security advisories, including high-severity denial-of-service and injection findings. The dependency graph must be refreshed now so supported builds no longer ship versions that Hex currently identifies as vulnerable.

## What Changes

- Refresh all Mix dependencies to the latest versions permitted by the existing `mix.exs` requirements.
- Require the resulting lockfile to pass `mix hex.audit` without retired or security-advisory packages.
- Validate the updated graph through the repository's complete checks and review dependency-authored usage-rule changes if synchronization reports any.
- Preserve the existing dependency requirements, application behavior, public contracts, database schema, and frontend Bun dependency graph.

## Capabilities

### New Capabilities

- `mix-dependency-security`: Defines the security-audit and validation boundary for the resolved Mix dependency graph.

### Modified Capabilities

None.

## Impact

- Tracking: [GitHub issue #197](https://github.com/ravecat/d20/issues/197).
- Dependency resolution: `mix.lock` and locally fetched or compiled Mix dependencies.
- Validation: Hex advisory audit, dependency-managed skill synchronization check, and `just check`.
- Runtime and delivery: package implementations may change within existing requirements, but no D20 API, route, session, persistence, iframe module contract, database migration, or frontend package change is intended.
- Rollback: restore the previous `mix.lock`; no data rollback or migration is required.
