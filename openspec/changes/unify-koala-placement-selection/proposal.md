## Why

Koala Rescue Club currently stores an uncommitted primary selection in the authoritative game aggregate and broadcasts a new caller-specific projection for every cell click. The selection exists only to drive one player's interface. Keeping it in the aggregate adds transient mutations and reconnect semantics to shared state without adding an authoritative game fact.

The server must still own placement legality. The client therefore needs a stateless preview request that evaluates its complete local draft against the latest committed game, while `submit` remains the only command that commits the turn.

## What Changes

- Add a synchronous `draft` request carrying the complete primary candidate: `mark`, `die_value`, and `selected_cells`.
- Return caller-specific derived guidance from `draft`: selected and available cells, required cells, volunteer cost, submit readiness, resolution, and bonus options.
- Keep `draft` outside the aggregate mutation path: it does not store state, publish a session projection, or change any committed fact.
- Make `submit` carry the same complete primary candidate plus ordered `bonus_actions`, revalidate all inputs against current state, and commit the turn atomically.
- Remove primary `selection` from the game aggregate and normal session projection.
- **BREAKING** Remove `select`, `deselect`, and `reset` from the public protocol together with the already removed direct placement events.
- Keep mark-keyed initial options in the normal caller projection so the client can start a local draft without reproducing game rules.
- Add a reusable synchronous game preview boundary to D20 sessions and game servers.
- Update the separate Koala Rescue Club client to own its ephemeral primary draft, consume server preview replies, and clear the draft after reconnect.

## Capabilities

### New Capabilities

- `koala-rescue-club-unified-turn-selection`: Defines local draft ownership, stateless authoritative preview, complete atomic submit, state-machine boundaries, visibility, and coordinated client behavior.

### Modified Capabilities

None.

## Impact

- Affects shared `D20.Game`, `D20.Sessions`, `D20.Sessions.Session`, `D20.Game.Server`, and `D20Web.SessionChannel` preview boundaries.
- Affects `D20.KoalaRescueClub.Command`, `Rules`, `Game`, `Projection`, the Koala AsyncAPI document, and focused tests.
- Breaks clients that send `select`, `deselect`, `reset`, or expect `selection` in normal projections.
- Requires a coordinated change in `ravecat/koala-rescue-club` types, root state machine actor, pure turn draft reducer, fixtures, and browser tests.
- Active in-memory sessions are incompatible across deployment and must be restarted. No database migration is required.
- Tracked by [ravecat/d20#84](https://github.com/ravecat/d20/issues/84).
- The sheet-specific hospital identifier correction remains tracked by [ravecat/d20#86](https://github.com/ravecat/d20/issues/86).
