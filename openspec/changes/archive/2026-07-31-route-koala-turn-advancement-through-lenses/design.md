## Context

After every player submits, `maybe_resolve_turn/1` awards badges, optionally scores the round, and calls `maybe_finish/1`. That final step still reads `game.turn` directly, uses direct struct updates for final and next-turn state, and delegates the non-final player reset to `set_player_statuses/2`. The helper is called only there and reconstructs the complete players map solely to update each status.

Existing tests cover non-final multiplayer advancement, clearing the shared roll, resetting every accepted player to ready, final turn completion, solo scores, and multiplayer scores. The refactor must preserve those results and all intermediate authoritative facts.

## Goals / Non-Goals

**Goals:**

- Read the authoritative turn once through `lens(:turn)` in `maybe_finish/1`.
- Express final and non-final aggregate writes through the existing field lens macro.
- Reset every player status through the existing `all/0` collection lens.
- Remove `set_player_statuses/2` after its only call site is replaced.

**Non-Goals:**

- Change final-turn detection, next-round derivation, score calculation, or badge awarding.
- Rewrite `score_round/1`, badge helpers, score helpers, or rule queries.
- Change commands, projections, persistence, session runtime, or iframe contracts.

## Decisions

### Read turn once and reuse the accepted value

`maybe_finish/1` will obtain `turn` with `Pathex.view!/2` and `lens(:turn)`. The same value will drive `Ruleset.final_turn?/1`, the next turn, and `Ruleset.round/1`, preserving the current ordering while keeping aggregate field access in the lens vocabulary.

Alternative considered: keep direct `game.turn` reads and migrate only writes. That would remove the helper but leave mixed field-access styles inside the same transition.

### Set final state through separate field lenses

On the final turn, `score_players/1` will remain the authoritative score derivation. `maybe_finish/1` will compute scores from the unchanged post-turn aggregate, then set `phase` and `scores` through their field lenses. The scoring helpers remain separate because they encode domain calculations rather than mutation plumbing.

Alternative considered: calculate scores inside a lens callback. Scores depend on the complete aggregate rather than the existing scores field, so that would obscure the real dependency.

### Advance non-final state with field and collection lenses

On a non-final turn, `Ruleset.round(turn + 1)` will continue deriving the next round. A pipeline will set phase, round, turn, and roll through field lenses, then set every player status to `:ready` through `lens(:players) ~> all() ~> path(:status)`. All other player facts remain unchanged.

Alternative considered: retain `set_player_statuses/2` around only the collection lens. The wrapper would remain one-use mutation indirection and provide no additional rule boundary. The helper guard is unnecessary at its sole call site because `:ready` is a compile-time member of the declared player statuses.

## Risks / Trade-offs

- [A field pipeline could accidentally derive round from a mutated turn] -> Compute `next_turn` and `next_round` before the mutation pipeline.
- [The collection lens could rebuild player entries incorrectly] -> Set only the nested status path and retain the existing multiplayer advancement assertions for turns, sheets, and readiness.
- [Final score calculation could observe partially updated state] -> Compute scores before setting phase or scores, matching the current source aggregate used by `score_players/1`.

## Migration Plan

1. Replace direct `maybe_finish/1` reads and writes with the specified lens operations.
2. Remove `set_player_statuses/2`.
3. Run focused Koala aggregate tests, warnings-as-errors compilation, and strict OpenSpec validation.

Rollback restores the two direct struct update branches and the status helper. No data, deployment, or protocol migration is required.

## Open Questions

None.
