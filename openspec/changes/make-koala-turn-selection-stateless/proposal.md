## Why

An unfinished shape selection is private interaction state for one client, but it is currently stored in every server-side `Game` player entry and processed as shared game state. Moving that draft out of `Game` keeps the aggregate limited to committed facts while preserving server-authoritative legality through caller-specific projections.

## What Changes

- **BREAKING** Remove `turn_selection` from the Koala Rescue Club game player state.
- **BREAKING** Replace the mutating `select_turn_cell`, `deselect_turn_cell`, and `reset_turn_selection` events with a stateless `project_turn_selection` request that accepts the full client draft and returns its derived selection projection without changing or broadcasting the game.
- **BREAKING** Make `submit_turn_selection` accept the full selection draft together with bonus actions and validate and apply it atomically against the current game.
- Remove `selection` from the regular session projection because the server no longer owns an unfinished selection; keep `options` caller-specific and derived from the current game.
- Move option and selection projection types and assembly into `D20.KoalaRescueClub.Projection`, using rule-level legality primitives from `Rules` and base domain types from `Ruleset`.
- Update the AsyncAPI contract and the dependent Svelte client so the current selection lives in client state and every shape-cell change sends the complete draft for server projection.
- Preserve shared sheet, status, score, badge, roll, and committed turn behavior for all players.

## Capabilities

### New Capabilities

- `koala-rescue-club-stateless-turn-selection`: Defines client-owned shape drafts, stateless server projection, atomic submission, and the committed-state boundary of the Koala game aggregate.

### Modified Capabilities

None.

## Impact

- Backend game and rules: `D20.KoalaRescueClub.Game`, `Command`, `Rules`, and their focused tests.
- Projection transport: `D20.KoalaRescueClub.Projection`, `D20Web.Projection`, `D20Web.SessionChannel`, and channel/projection tests.
- Public iframe contract: `priv/specs/koala-rescue-club.yaml` changes incompatibly and requires coordinated backend and client deployment.
- Dependent client: `/home/max/apps/koala-rescue-club` session types, transport calls, turn state, fixtures, and browser tests. Existing unrelated client work must be preserved.
- Persistence and migrations: no database migration; in-memory session shape changes and active drafts are intentionally discarded on reconnect or deployment.
- Dependencies: none.
- Rollback: revert backend, AsyncAPI, and client changes together; no data migration rollback is required.
