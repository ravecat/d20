## 1. Dependent Client Consumer

- [x] 1.1 Update `/home/max/apps/koala-rescue-club` session and browser fixtures to represent complete games without `order`, and add coverage that participant controls render every `game.players` entry without positional assumptions
- [x] 1.2 Remove `Game.order` from `src/types/session.ts` and migrate `src/components/participants.svelte` to unsorted `Object.entries(game.players)` traversal keyed by participant id
- [x] 1.3 Replace positional participant fallback labels with participant ids and make multiplayer result rows use the same id fallback when member display metadata is missing
- [x] 1.4 Run `just check`, `just test`, and `just build` in `/home/max/apps/koala-rescue-club`

## 2. Backend Unordered Roster

- [x] 2.1 Update focused Koala aggregate, rules, session, and server tests to remove order assertions and cover players-map capacity, pre-start `left`, frozen mode, simultaneous badge awards, and complete final scoring
- [x] 2.2 Remove the `order` schema field and type entry from `D20.KoalaRescueClub.Game`, and make `join` and `left` mutate only `players`
- [x] 2.3 Ensure readiness and player-count validation use `map_size(game.players)` and no roster count or mode rule reads an order list
- [x] 2.4 Migrate solo and multiplayer badge evaluation and final scoring to map entries while preserving simultaneous award and score behavior without sorting players

## 3. Projection And Public Contract

- [x] 3.1 Update projection tests to construct Koala games without order and assert caller-specific game maps omit the field in pre-start, active, finished, and reconnect-equivalent renders
- [x] 3.2 Remove `order` from the Koala projection type and rendered game map while preserving the complete `players` read model
- [x] 3.3 Remove `order` from the required fields and properties of `priv/specs/koala-rescue-club.yaml`, then validate the contract with `npx -y @asyncapi/cli@latest validate priv/specs/koala-rescue-club.yaml`

## 4. Validation And Release Review

- [x] 4.1 Format-check touched Elixir files and run focused game, rules, server, session, and projection tests with `mix test`
- [x] 4.2 Run `just check` in `/home/max/apps/d20` because the change crosses aggregate behavior, the public protocol, and a separately deployed client
- [x] 4.3 Search both codebases to confirm Koala aggregate, projection, AsyncAPI, TypeScript, fixtures, and participant rendering no longer define or consume player order, while leaving unrelated chronological, result-ranking, and other-game order concepts intact
- [x] 4.4 Review both worktrees for unrelated changes and document client-first deployment with backend-first rollback
- [x] 4.5 Run `openspec validate remove-koala-player-order --strict`
