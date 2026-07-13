## Why

Live game-session ownership is currently split between a default `D20.Sessions.Server` GenServer and custom modules built through `D20.Game.Server`, forcing the session context to support two OTP primitives and duplicating shared runtime behavior. Unifying all game servers on `:gen_statem` gives every session one runtime contract, one lifecycle model, and one extension point for game-specific state transitions and timers.

## What Changes

- Make `D20.Game.Server` the single runtime contract and shared adapter for processes that own a live `%D20.Sessions.Session{}`.
- Make `:gen_statem` the only OTP primitive supported by `D20.Game.Server`; remove the `:gen_server` adapter branch and the `otp:` selection option.
- Introduce a default game-server implementation on `:gen_statem` that preserves the existing state access, dispatch, Presence, publication, idle-expiration, registry, supervision, and temporary-restart behavior.
- Make `use D20.Game.Server` provide the stable process API and overridable default `:gen_statem` callbacks, so custom servers extend standard callbacks with `super` instead of relying on a separate hook protocol.
- Generate a default `server/0` callback for every engine using `D20.Game`, while preserving explicit custom servers such as `D20.KoalaRescueClub.Server`.
- Move shared runtime behavior out of `D20.Sessions.Server` and remove that module after parity is verified.
- Keep `D20.Sessions` as the OTP-agnostic public facade for create, get, dispatch, lookup, and stop operations; keep `D20.Sessions.Session` and game engines as pure state and command reducers.
- **BREAKING** Remove support for `use D20.Game.Server, otp: :gen_server` and replace GenServer-specific server types and stop paths with `:gen_statem` equivalents.

## Capabilities

### New Capabilities

- `game-server-runtime`: Defines the unified `:gen_statem` game-server contract, default implementation, custom-server selection, and shared session lifecycle behavior.

### Modified Capabilities

- None.

## Impact

- Affected runtime modules: `D20.Game.Server`, `D20.Game`, `D20.Sessions`, `D20.Sessions.Server`, and custom game servers.
- Affected tests: shared game-server and session tests, game-engine server-selection tests, Koala server integration tests, and Presence/channel lifecycle tests.
- Public `D20.Sessions` function signatures, session command results, registry keys, Presence semantics, PubSub payloads, iframe contracts, routes, schemas, and persisted data remain unchanged.
- No database migration, frontend dependency, or external service change is required.
- Existing live sessions are volatile; rollback is a code revert and does not require persisted-state conversion or dual-runtime compatibility.
