## 1. State Model and Static Invariants

- [x] 1.1 Cross-check every changed command, transition, aggregate field, predicate, projection field, and client stimulus against the reviewed state, transition, command, predicate, and visibility tables before editing runtime code
- [x] 1.2 Add the bounded tree-or-koala mark domain to `Ruleset` and focused tests proving every supported die shape contains at least two cells
- [x] 1.3 Add focused Rules tests for initial mark targets, one-cell submit readiness with and without continuations, partial shape prefixes, complete shapes, invalid continuations, and derived volunteer cost

## 2. Command and Aggregate Migration

- [x] 2.1 Update command normalization and tests so first or replacement `select` accepts `mark`, `die_value`, and `target_cell`, continuation `select` accepts only `target_cell`, and client-supplied `volunteers_used` is rejected or discarded intentionally
- [x] 2.2 Replace the stored action-and-volunteer selection with canonical mark, adjusted value, and cells in `Game` and its types
- [x] 2.3 Update select, deselect, last-cell clearing, reset, replacement, idempotency, and rejection-preservation transitions with focused aggregate tests
- [x] 2.4 Make `submit` classify and atomically resolve one-cell or full-shape selections, derive and spend volunteers, apply ordered bonuses, record the adjusted value, clear the selection, and preserve the complete source state on failure
- [x] 2.5 Remove direct `circle_tree` and `circle_koala` command validation, Rules resolution, Game routing, turn-value handling, server fixtures, and obsolete tests while retaining tree and koala bonus effects as internal rule operations

## 3. Projection and Public Contract

- [x] 3.1 Replace action-keyed turn options with mark-keyed options and project the complete caller-ready selection fields, including non-exclusive `submit_ready` and `available_cells`
- [x] 3.2 Add projection and permission coverage for empty, single extendable, single final, partial shape, complete shape, submitted, other-player, spectator, reconnect, and finished states
- [x] 3.3 Update channel and session integration tests to prove accepted edits publish caller-specific projections, rejected edits do not publish, direct legacy commands are unsupported, and the final submit remains atomic
- [x] 3.4 Update `priv/specs/koala-rescue-club.yaml` to remove direct primary commands and action identifiers and document mark options, select payload variants, selection resolution, submit readiness, bonus payloads, replies, and stable errors
- [x] 3.5 Verify contract serving and all backend fixtures use only the unified command and projection shapes

## 4. Separate Client Coordination

- [x] 4.1 Create or reuse a linked `ravecat/koala-rescue-club` issue in Project 6 and a repo-local OpenSpec change before editing that repository
- [x] 4.2 Rebase the client migration on its current `centralize-client-state-machine` work and preserve unrelated local changes
- [x] 4.3 Update `src/types/session.ts` and `src/store/session.svelte.ts` for mark-keyed options, unified selection fields, the reduced select payload, and removal of direct single-cell command methods and processing states
- [x] 4.4 Update `src/store/client.store.ts`, `src/store/turn.svelte.ts`, and `src/game/turn.ts` so every primary cell is server-owned, every target edit dispatches select or deselect, Confirm always dispatches submit, and only ordered bonus preview remains client-owned
- [x] 4.5 Update `turn_controls.svelte`, Dharug and Yugambeh widgets, accessible mark choices, server-shaped fixtures, command mocks, and focused browser scenarios without changing calibrated map geometry or startup boundaries
- [x] 4.6 Verify reconnect, retry, stale projection, both sheets, keyboard interaction, focus, forced colors, narrow and wide layouts, embedded mode, and standalone mode against the migrated contract

## 5. Validation and Coordinated Release

- [x] 5.1 Format touched Elixir and contract-adjacent files with the repository-native formatter and run `git diff --check`
- [x] 5.2 Run `mix test test/d20/koala_rescue_club/command_test.exs test/d20/koala_rescue_club/rules_test.exs test/d20/koala_rescue_club/ruleset_test.exs test/d20/koala_rescue_club/game_test.exs`
- [x] 5.3 Run `mix test test/d20/koala_rescue_club/server_test.exs test/d20_web/projection_test.exs test/d20_web/channels/session_channel_test.exs test/d20_web/plugs/async_api_test.exs`
- [x] 5.4 Run the broader D20 validation required by the final diff, including `mix test` and `just check`
- [x] 5.5 In the separate client, run focused Vitest Browser Mode scenarios, `just check`, `just test`, `just build`, `git diff --check`, and strict validation of its linked OpenSpec change
- [x] 5.6 Run `openspec validate unify-koala-placement-selection --strict` and cross-check the final D20 AsyncAPI schemas against the client TypeScript fixtures and command calls
- [ ] 5.7 Deploy the compatible backend and client versions together, restart active Koala Rescue Club sessions, and retain a paired rollback path for both artifacts
