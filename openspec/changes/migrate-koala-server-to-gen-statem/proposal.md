## Why

`D20.KoalaRescueClub.Server` currently models phase-bound automatic rolls with `Process.send_after/3` and a private `roll_token` used to reject stale timer messages. Koala Rescue Club already has explicit game phases, so migrating its process wrapper to `:gen_statem` will express the roll deadline as a state timeout, remove manual timer correlation state, and establish a simpler base for later game-server refactoring.

## What Changes

- Run `D20.KoalaRescueClub.Server` through the `:gen_statem` adapter provided by `D20.Game.Server`.
- Align the server state name with the current Koala Rescue Club game phase while retaining the existing live session as state data.
- Replace `Process.send_after/3`, `roll_token`, and stale-roll message handling with a `state_timeout` that is active only in the roll phase.
- Preserve the existing server-owned roll behavior, projected `roll_due_at`, Presence-driven membership flow, session publication, registry lookup, temporary restart policy, and idle expiration.
- Add focused tests for phase transitions, automatic roll timing, stale-timeout prevention, channel-level exclusion of client rolls, Presence events, and idle timeout behavior under `:gen_statem`.

## Capabilities

### New Capabilities

- `koala-server-runtime`: Defines the phase-aligned Koala Rescue Club session process, automatic roll timeout, and compatibility with the shared game-server API and session lifecycle.

### Modified Capabilities

- None.

## Impact

- Affected backend modules: `D20.KoalaRescueClub.Server`, `D20Web.SessionChannel`, and, only if required for adapter parity, `D20.Game.Server`.
- Affected tests: Koala Rescue Club server tests, the shared session channel test, and targeted shared game-server or session tests.
- Public `D20.Sessions` APIs, Channel topics, Presence semantics, projections, game rules, routes, iframe module contracts, schemas, and persisted data remain unchanged.
- No database migration, frontend dependency, or runtime service dependency is required.
- Rollback is a code revert to the current GenServer-backed Koala server; no data migration or compatibility window is required because session state is volatile.
