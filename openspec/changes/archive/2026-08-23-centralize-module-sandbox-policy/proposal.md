## Why

Iframe sandbox capabilities are a shell framing policy, but D20 currently duplicates the same policy across playable game registry entries. Moving that policy to `D20Web.Module` gives the web boundary one authoritative configuration and prevents per-game registry drift without changing the iframe descriptor consumed by clients.

## What Changes

- Add one non-empty iframe sandbox policy to the application configuration owned by `D20Web.Module`.
- Make `D20Web.Module` read that configured policy when it builds every module descriptor.
- **BREAKING (internal configuration):** Remove `sandbox` from `D20.Games.Registry.Entry`, configured game entries, registry validation, and registry types.
- Preserve the current effective `allow-scripts allow-same-origin` policy and the public module descriptor's `sandbox` field.
- Update focused tests and authoritative specifications so catalog availability depends on engine binding, while iframe capability ownership remains in the web framing boundary.

## Capabilities

### New Capabilities

- `embedded-module-sandbox-policy`: Defines the shell-owned sandbox configuration and its unchanged projection into every iframe module descriptor.

### Modified Capabilities

- `playable-game-registry`: Remove iframe sandbox policy from the stable game registry contract.
- `game-catalog-availability`: Require an engine, but not a per-entry sandbox value, for active and in-progress games.
- `game-session-creation-attrs`: Remove sandbox from the registry bindings named by the creation-attrs boundary.
- `runtime-game-metadata`: Define playable registry sufficiency without a sandbox field.
- `next-station-london-gameplay`: Preserve the effective shared iframe sandbox behavior without assigning it to the Next Station: London registry entry.

## Impact

- Affected backend configuration and modules: `config/config.exs`, `D20.Games.Registry`, and `D20Web.Module`.
- Affected focused tests: registry, module descriptor, workspace channel, module controller, and game-page session-launch coverage that constructs registry entries.
- The module descriptor shape, iframe capabilities, routes, channel endpoint/topic/token handoff, session behavior, and separate game repositories remain unchanged.
- No database migration, dependency, frontend source, public AsyncAPI payload, or deployment migration is required.
- Rollback restores the sandbox field and validation on registry entries and makes `D20Web.Module` read the per-entry value again.
- Tracks [GitHub issue #222](https://github.com/ravecat/d20/issues/222) and remains separate from the broader browser-isolation work in [#108](https://github.com/ravecat/d20/issues/108).
