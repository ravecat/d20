## Why

Koala Rescue Club has no rule that gives players a turn order, yet the aggregate and public projection expose an `order` array and the client treats it as an ordered roster. Keeping both `order` and `players` creates two sources of roster truth, adds synchronization work on `join` and `left`, and encourages client behavior that the game does not define.

## What Changes

- Make `game.players` the only authoritative Koala Rescue Club roster before and after start.
- Remove the `order` field from the Koala aggregate and migrate player-count validation, badge evaluation, and final scoring to the players map.
- **BREAKING** Remove `game.order` from every caller-specific Koala projection and from the public AsyncAPI schema.
- **BREAKING** Remove `Game.order` from the dependent `/home/max/apps/koala-rescue-club` TypeScript contract and migrate participant rendering and tests to `game.players`.
- Do not introduce a replacement ordering or sorting rule. Player roster iteration is unordered; only final standings retain their existing score-based ranking.
- Keep display names for participant labels and use the stable participant id as the non-positional fallback instead of generated labels such as `Player 1`.

## Capabilities

### New Capabilities

- `koala-rescue-club-unordered-roster`: Defines the players map as the sole roster authority and removes the unused player-order contract from the backend, projection, protocol, and dependent client.

### Modified Capabilities

None.

## Impact

- Backend aggregate and rules: `lib/d20/koala_rescue_club/game.ex`, `rules.ex`, and focused game, rules, session, and server tests.
- Public projection and protocol: `lib/d20/koala_rescue_club/projection.ex`, projection tests, and `priv/specs/koala-rescue-club.yaml` stop emitting or documenting `game.order`.
- Dependent iframe client: `/home/max/apps/koala-rescue-club/src/types/session.ts`, `src/components/participants.svelte`, and related browser fixtures and tests stop requiring or consuming `order`.
- Runtime compatibility: this removes a public field. Deploy the tolerant client that ignores `order` first, then the backend that stops producing it. Rollback restores the backend field before restoring an older client.
- Persistence and migrations: no database migration or backfill is required because Koala session aggregates are process-owned and ephemeral.
- Dependencies: implementation depends on the accepted-roster correction in `make-koala-game-mode-explicit`, which derives frozen mode from `game.players`.
