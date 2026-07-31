## Why

`D20.Game` already owns the compile-time contract shared by every game engine, while Koala currently configures Pathex and defines the aggregate field lens locally. Centralizing that setup prevents game namespaces from duplicating the same low-level DSL and establishes one supported lens vocabulary for future aggregate transitions.

## What Changes

- Make `use D20.Game` configure Pathex with map paths.
- Make the shared game DSL import the supported `all/0` collection lens and inject a private literal-field `lens/1` macro.
- Remove the equivalent `use Pathex`, `all/0` import, and `lens/1` definition from Koala Rescue Club.
- Keep `Function.identity/1` local to Koala because it is a reducer implementation choice rather than shared DSL.
- Add focused compile-time coverage for field and collection paths supplied by `D20.Game`.
- Preserve every existing game callback, default server, transition, public projection, and protocol contract.

## Capabilities

### New Capabilities

- `game-engine-lens-dsl`: Defines the private Pathex field and collection lens surface supplied to game engine modules by `use D20.Game`.

### Modified Capabilities

- `koala-pathex-state-mutations`: Moves ownership of Koala's private field lens from the game module to the shared `D20.Game` DSL without changing reducer paths.

## Impact

- Affected code: `D20.Game.__using__/1`, `D20.KoalaRescueClub.Game`, and focused `D20.Game` tests.
- Compile-time impact: every `D20.Game` consumer receives Pathex map operators, `all/0`, and the private `lens/1` macro, including engines that do not yet use lenses.
- APIs and runtime: no exported game API, callback, route, persistence, session, projection, or iframe contract changes.
- Dependencies and migrations: no new dependency or data migration; Pathex is already locked by the application.
- Rollback: restore the Koala-local setup and remove the injected DSL declarations from `D20.Game`.
