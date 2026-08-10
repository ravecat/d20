## Why

The private `lens/1` macro supplied by `use D20.Game` expands a complete Pathex path closure at every call site, making lens-heavy game aggregates disproportionately slow to compile. Game engines still need one automatic and field-agnostic lens vocabulary, so the shared DSL should preserve the existing call shape while compiling the reusable path logic once per consuming module.

## What Changes

- Replace the private `lens/1` macro injected by `D20.Game` with a private runtime helper that returns a Pathex map path for any field.
- Keep `lens(field)` automatically available inside every module that calls `use D20.Game` without requiring a field registry or game-local setup.
- Preserve Pathex path composition, `all/0`, bang-operation failures, reducer behavior, and helper privacy.
- Extend focused tests to cover arbitrary map and struct fields, collection composition, and the absence of an exported lens function.
- Record a repeatable before-and-after compilation measurement for the lens-heavy Koala aggregate.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `game-engine-lens-dsl`: Change the automatically supplied private field lens from repeated compile-time macro expansion to a private runtime helper while preserving the engine-facing DSL and Pathex semantics.

## Impact

- Affected code: `D20.Game.__using__/1` and focused `D20.Game` tests. Existing Koala reducer call sites remain unchanged.
- APIs and runtime compatibility: no exported API, callback, route, session, projection, persistence, or iframe contract changes. The private helper adds one local runtime function to each game engine module.
- Dependencies and migrations: no dependency, configuration, protocol, or data migration changes.
- Tracking: GitHub issue #205.
- Rollback: restore the private macro implementation. No stored state or deployment migration is required.
