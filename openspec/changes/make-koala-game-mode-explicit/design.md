## Context

`D20.KoalaRescueClub.Game` currently determines mode-dependent behavior by inspecting `game.order`: badge awarding checks whether the order has one player, and final scoring assigns a solo rank only when the order matches one player. The dependent Svelte module independently decides which final results UI to render by checking whether `standings` contains one score. The aggregate already stores the actual roster in `game.players`, so `order` must not become a second roster authority merely to derive mode.

These checks currently agree because Koala Rescue Club freezes its gameplay roster at start and produces one score per player. The relationship is implicit, however, so the client duplicates a domain decision and a future partial score or projection change could select the wrong UI. The aggregate is process-owned and ephemeral, and the public iframe contract is the caller-specific projection documented in `priv/specs/koala-rescue-club.yaml`.

## Goals / Non-Goals

**Goals:**

- Make solo or multiplayer mode an explicit authoritative fact in the Koala Rescue Club aggregate.
- Resolve mode at the start transition from the accepted, frozen player roster.
- Use the stored mode for backend rules that differ between solo and multiplayer games.
- Expose the mode through every caller-specific game projection and the AsyncAPI contract.
- Make the dependent client choose its final results presentation from the projected mode only.
- Preserve current behavior for valid one-player and multi-player games.

**Non-Goals:**

- Letting callers choose or change mode independently of player count.
- Adding mode to the generic `D20.Game` behavior, generic session envelope, or unrelated games.
- Changing player limits, post-start join and leave behavior, score calculation, score shape, badge values, rankings, or result presentation.
- Removing the temporary `order` field; that breaking contract change belongs to `remove-koala-player-order`.
- Persisting sessions or adding a database migration.
- Adding a compatibility fallback that makes the new client infer mode from players, order, or scores.

## Decisions

### Store a nullable enum and freeze it at start

The embedded game schema will add `mode` as an `Ecto.Enum` with `:solo` and `:multiplayer` values. Its initial value will be `nil` during `:setup` and `:ready`, because the roster is still open and no durable mode decision has been made. During those phases, `game.players` is the accepted roster: join adds the actor and leave removes the actor. The phase is recalculated after either mutation so an empty roster returns to `:setup`. The accepted `start` transition will use `map_size(game.players)` to set `:solo` for exactly one player and `:multiplayer` for two or more players in the same state update that moves the game to `:roll`.

The existing player-count validation remains the gate before mode resolution, but it will count `game.players` for the same single-source invariant. Until `remove-koala-player-order` is implemented, pre-start join and leave will also update `order` as a compatibility field. After start, Koala Rescue Club ignores game roster mutations, so mode and the accepted roster remain unchanged for the full game and through reconnections or session membership changes.

Updating mode after every join was rejected because it would represent a provisional classification as authoritative and introduce synchronization logic that is unnecessary for gameplay. Deriving mode through a helper without storing it was rejected because it would preserve the current duplicated inference and would not make mode an aggregate fact.

### Use mode as the backend source for mode-specific rules

Badge awarding will branch on `game.mode`, and final score calculation will assign a solo rank only for `:solo`. Multiplayer scores will continue to contain `rank: nil`. `game.players` is authoritative for roster membership and mode calculation. The existing `order` field remains temporarily available only for behavior and public compatibility that the separate `remove-koala-player-order` change will migrate.

This makes the field meaningful domain state rather than projection-only metadata. Keeping the old player-count branches beside the new field was rejected because the two sources could diverge and the aggregate would not have a single mode invariant.

### Project mode inside the game read model

`D20.KoalaRescueClub.Projection` will render `mode` beside `sheet`, `phase`, `round`, and `turn` inside `game`. The field will be present on every projection, encoded as `null` before start and as `"solo"` or `"multiplayer"` after start. The AsyncAPI `game` schema will require the property and define the same nullable enum contract.

Mode belongs inside `game` because it controls game-specific rules and is identical for every caller. A top-level session field was rejected because the generic session lifecycle does not own this distinction. Omitting the property before start was rejected because a stable required key produces a simpler wire shape and TypeScript contract.

### Make client rendering depend on mode, not result cardinality

The dependent client will define a `GameMode` union and type `Game.mode` as `GameMode | null`. `results.svelte` may still build and sort `standings` from the score map for display content, but it will select the solo score card only when `game.mode === "solo"` and the standings list only when `game.mode === "multiplayer"`. It will not fall back to score, player, or order counts.

Browser coverage will assert the existing solo and multiplayer presentation and include a mode-authority case whose score cardinality does not imply the selected presentation. This protects the purpose of the change rather than only reproducing the currently consistent fixtures.

### Use an ordered backend-first release

The field is additive for the existing client, which ignores it, but required by the new client. Deployment will therefore publish the backend aggregate, projection, and contract first, verify both modes, and then publish the client. Rollback reverses that order.

No dual field or inference fallback is needed. Such a fallback would hide an incorrectly ordered deployment and retain the duplicated client decision this change removes.

## Risks / Trade-offs

- [A game reaches an active phase with `mode: nil`] - Set mode atomically in the validated start transition and add aggregate and server tests that assert every active and finished state has a mode.
- [A player leaves before start but still affects mode] - Remove accepted pre-start leavers from `game.players`, recalculate readiness, and test that the remaining roster alone determines mode.
- [Backend and client releases are ordered incorrectly] - Deploy the additive backend field first and only then deploy the client that requires it; roll back the client first.
- [Tests keep deriving mode through realistic score counts and miss a regression] - Add a client test where explicit mode, rather than collection cardinality, determines the rendered result variant.
- [Direct test fixtures construct active `%Game{}` values without mode] - Update affected focused fixtures and keep setup fixtures nullable only where the phase is pre-start.
- [Unrelated dirty work exists in the dependent client] - Restrict implementation to the named type, results component, and necessary fixtures, and review the client diff before validation.

## Migration Plan

1. Add mode to the aggregate and start transition, migrate mode-dependent backend branches, and verify one-player and multi-player state transitions.
2. Add mode to the projection and AsyncAPI schema, then validate caller projections in pre-start, active, and finished phases.
3. Deploy the backward-compatible backend producer and verify live projections contain the expected mode.
4. Update and validate the dependent Svelte type, fixtures, results logic, and browser coverage, then deploy the client.
5. If rollback is required, restore the previous client first, then revert the backend and contract changes.

No data backfill or database rollback is required because running sessions are ephemeral. Sessions that started on an old backend process should be allowed to expire or be restarted before the new client is deployed, since their in-memory aggregate cannot gain a mode retroactively.

## Open Questions

None for this scoped change.
