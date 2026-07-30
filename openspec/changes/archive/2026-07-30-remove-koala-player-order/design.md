## Context

Koala Rescue Club is a simultaneous-play game. Every accepted player acts against the same roll, turn completion checks every player status, badge achievers in the same resolution receive the same award, and final scores are keyed by participant id. No rule consumes a first player, cursor, seat, or join position.

Despite that model, `D20.KoalaRescueClub.Game` stores both `order: [player_id]` and `players: %{player_id => player}`. `join` and pre-start `left` must synchronize both structures. Badge and scoring helpers iterate `order`, the projection publishes it, and the dependent Svelte client uses it to render participants and invent positional fallback names. This makes an incidental join sequence appear to be a domain contract.

The accepted-roster correction in `make-koala-game-mode-explicit` already establishes `game.players` as the source for readiness, player-count validation, and mode capture. This change completes that direction across the backend and dependent client. Koala aggregates are ephemeral, but the projection is a public iframe contract, so removing its field requires coordinated deployment.

## Goals / Non-Goals

**Goals:**

- Make `game.players` the sole authoritative Koala roster.
- Remove `order` from the aggregate type, projection, AsyncAPI schema, TypeScript type, fixtures, and tests.
- Preserve simultaneous badge and score behavior without introducing order-dependent iteration.
- Let the client render and select every projected player directly from `game.players` without sorting them.
- Preserve the existing score-descending final standings because that is result ranking, not roster order.
- Define a non-positional participant label fallback that remains unique and accessible.

**Non-Goals:**

- Removing or changing order fields in Qwinto or any other game.
- Adding seats, a first player, turn rotation, join sequence, alphabetical sorting, or any replacement roster ordering.
- Changing Koala player limits, mode semantics, rolls, turn completion, badge values, scoring, rankings, or result layout.
- Persisting sessions or migrating stored aggregate data.
- Keeping a deprecated `order` alias or making the client accept both contract shapes indefinitely.

## Decisions

### Use the players map as the only roster representation

The Koala embedded schema and `t()` type will remove `order`. Accepted `join` will add only to `players`; accepted pre-start `left` will delete only from `players`. Readiness and player-count validation will use `map_size(players)`, and the start transition will continue to freeze mode from that same map. Active-phase `join` and `left` behavior remains unchanged, so the gameplay roster and mode stay frozen after start.

A second list keyed by the same ids was rejected because the game has no ordering invariant to justify synchronization or conflict resolution. Replacing the map with a list was rejected because game commands, permissions, projections, and client selection all require direct lookup by participant id.

### Express simultaneous rules as map transformations

Solo badge evaluation will extract the single map entry guaranteed by `mode: :solo`. Multiplayer badge evaluation will select all satisfying player ids from `players` and update the full set together; map traversal position will not affect who receives a large or small badge. Final scoring will build the score map directly from every player entry.

No code may sort players by join time, participant id, display name, or map enumeration position to emulate the removed field. Incidental enumeration order is acceptable only where results are keyed or where every selected player receives identical treatment. Score-descending final standings remain explicitly sorted because they represent ranking by result.

### Remove order from the public read model in one contract version

`D20.KoalaRescueClub.Projection` will omit `game.order` from its type and rendered map. The AsyncAPI `game` schema will remove the required entry and property while retaining `players` as a participant-id-keyed object. Projection and contract tests will assert the field is absent rather than nullable or empty.

A deprecation period with both fields was rejected because the new client can be deployed first and already tolerates extra JSON properties at runtime. A nullable compatibility field was rejected because it preserves ambiguity about which roster is authoritative.

### Render client participants from players without sorting

The dependent client will remove `Game.order` and build participant controls from `Object.entries(game.players)` without calling `sort` or reconstructing an array from session membership. Members remain optional presentation metadata and cannot define gameplay membership. Each player remains keyed and selected by stable participant id.

For labels, a non-blank member display name remains preferred. When it is absent, the stable participant id will be shown and used in the radio's accessible name. Generated `Player N` labels are removed because their number falsely communicates order and can change when object enumeration changes.

Multiplayer results continue to sort `game.scores` by total descending. Result rows use `You` for the caller, otherwise a non-blank member display name or participant id, so missing member metadata does not produce an empty accessible label.

### Deploy the consumer before the breaking producer

The new client ignores an extra `order` field, so it can run against the old backend. The old client calls `.map` on `game.order` and cannot run after the field disappears. Deployment therefore publishes and verifies the client first, then publishes the backend and AsyncAPI removal. Rollback restores the backend producer first, then restores the old client if needed.

No aggregate data migration is required. A normal backend restart discards process-owned sessions; if deployment preserves processes through hot upgrades, existing sessions may still contain an ignored struct field but all new projections use the new schema and read model.

## Risks / Trade-offs

- [A backend deployment precedes the client] - Deploy the client first and verify it renders a projection that still contains the extra field before removing the backend field.
- [Map iteration is mistaken for a stable UI ordering contract] - State explicitly in the spec and tests that no roster ordering is guaranteed, and do not assert DOM positions for participant controls.
- [Badge behavior accidentally becomes sequential] - Select every achiever from the same pre-award game state before applying identical updates, and retain simultaneous-achiever tests.
- [A player lacks member metadata] - Use the stable participant id as the visible and accessible fallback label in participant controls and result rows.
- [Broad searches confuse unrelated order concepts] - Scope removal checks to Koala aggregate and projection fields; retain chronological turn values, manual bonus choice order, score ranking, and other games' order fields.

## Migration Plan

1. Update and validate the dependent client type, participant component, fixtures, and browser coverage while the backend still emits `order`.
2. Deploy the client and verify participant switching, missing-member labels, and multiplayer standings against the current backend.
3. Remove backend aggregate and rules dependencies, projection output, AsyncAPI property, and order-specific test fixtures.
4. Deploy the backend and verify pre-start `join` and `left`, solo and multiplayer start, simultaneous badge awards, final scores, projections, and reconnection.
5. For rollback, restore and deploy the backend field and projection first, then restore the previous client.

## Open Questions

None.
