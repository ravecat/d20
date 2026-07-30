## Why

Koala Rescue Club currently infers whether a game is solo or multiplayer from roster and score collection sizes in both the backend and the dependent Svelte client. Making the mode an explicit authoritative game fact removes duplicated inference and lets the client select the correct final results UI directly from the session projection.

## What Changes

- Add a `mode` field to the Koala Rescue Club game aggregate with `solo` and `multiplayer` values.
- Keep the pre-start `game.players` roster synchronized with accepted joins and leaves, then resolve and freeze `mode` from that roster when the game starts, before mode-dependent badge and final-score rules run.
- Use the stored mode for backend solo and multiplayer badge awarding and solo-rank calculation instead of re-counting players.
- Add `game.mode` to every caller-specific Koala Rescue Club projection and to the public AsyncAPI contract.
- Update focused aggregate, projection, server, and contract coverage for both modes and for the pre-start unset state.
- Update the dependent `/home/max/apps/koala-rescue-club` session type, fixtures, and results component to select solo score or multiplayer standings from `game.mode` instead of the number of score entries.
- Preserve existing commands, score shapes, the temporary player-order compatibility field, results copy and layout, and post-start session lifecycle. Removing player order is specified separately by `remove-koala-player-order`.

## Capabilities

### New Capabilities

- `koala-rescue-club-game-mode`: Defines how Koala Rescue Club determines, stores, projects, documents, and consumes an explicit solo or multiplayer mode.

### Modified Capabilities

None.

## Impact

- Backend aggregate and rules: `lib/d20/koala_rescue_club/game.ex` and focused game and server tests.
- Public projection: `lib/d20/koala_rescue_club/projection.ex`, `test/d20_web/projection_test.exs`, and `priv/specs/koala-rescue-club.yaml` gain `game.mode`.
- Dependent iframe client: `/home/max/apps/koala-rescue-club/src/types/session.ts`, `src/components/results.svelte`, and related session and browser fixtures and tests.
- Runtime compatibility: the new client requires the new backend projection, while the existing client can ignore the additive field. Release the backend first and then the client.
- Persistence and migrations: no database migration is required because sessions and game aggregates are process-owned and ephemeral.
- Dependencies: none.
- Rollback: restore the client first and then remove the backend field and contract update.
