## Context

`D20.KoalaRescueClub.Game.dispatch/2` normalizes and checks `join`, `start`, and `roll` before passing each command to `apply_command/2`. Submit differs: `Rules.resolve_turn/2` both checks state-dependent legality and derives the updated player, after which `dispatch/2` calls `apply_submit/3`.

The separate helper was introduced when turn selection became stateless so submit resolution would run once. The refactor must preserve that single evaluation because resolving once avoids duplicated rule work and guarantees that the player committed by the reducer is the same player accepted by Rules.

## Goals / Non-Goals

**Goals:**

- Make every accepted state-changing public Koala command reach an `apply_command` reducer clause.
- Keep submit resolution in `Rules` and execute it exactly once before aggregate mutation.
- Commit the resolved player and turn history through Pathex paths.
- Preserve submit atomicity, turn completion, scoring, public contracts, and errors.

**Non-Goals:**

- Move submit legality or player derivation from `Rules` into `Game`.
- Migrate `left`, scoring, badge awards, round completion, or automatic next-turn reducers to Pathex.
- Introduce a generic transition struct or change `D20.Command`.
- Change session runtime, projections, payloads, persistence, or protocols.

## Decisions

### Pass the resolved player to an `apply_command/3` clause

The submit dispatch clause will retain its current `Command.validate/1` and `Rules.resolve_turn/2` sequence, then call `apply_command(game, command, resolved_player)`. The three-argument reducer keeps the validated command available for actor id and die value while consuming the exact player value produced by the single Rules evaluation.

Alternative considered: call `Rules.validate/2` and resolve the turn again inside `apply_command/2`. This repeats the full candidate, volunteer, placement, and bonus evaluation and recreates the duplication removed by the stateless-selection change.

Alternative considered: place the resolved player in `D20.Command.attrs`. This would mix internal transition data with the normalized external payload and weaken the command boundary solely to preserve function arity.

Alternative considered: introduce a generic resolved-transition struct. One submit clause does not justify a new abstraction or changes to the other reducer clauses.

### Apply submit state through Pathex paths

The reducer will append the accepted die value to the resolved player's turn history with a Pathex path, set that player under the actor id through the aggregate players lens, and then call the existing `maybe_resolve_turn/1` pipeline. This removes `apply_submit/3` and the now-unused `record_turn/2` helper while retaining the existing default for a missing turns path.

The reducer owns aggregate mutation. Rules continues to own state-dependent legality and derived player facts, and the existing post-submit functions continue to own shared automatic transitions after every player has submitted.

### Preserve existing aggregate tests as the regression boundary

The focused game tests already prove successful submit state, turn history, repeated-submit rejection, unchanged committed state after invalid bonuses, and shared turn advancement. The refactor will rely on those behavioral assertions rather than adding a test coupled to a private function name.

## Risks / Trade-offs

- [The extra `apply_command/3` arity is less visually uniform than only `apply_command/2`] -> Prefer one Rules evaluation and an explicit resolved argument over hiding internal data in the command or duplicating rule work.
- [A Pathex update could change missing-turn-history behavior] -> Use a force operation with `[value]` as the missing-path default, matching the existing `Map.get(player, :turns, []) ++ [value]` behavior.
- [Post-submit helpers still use direct aggregate updates] -> Keep them outside this focused command-routing change and document that they remain separate internal transitions.

## Migration Plan

1. Add the submit delta requirement and preserve existing submit regression coverage.
2. Route accepted submit dispatch to `apply_command/3`.
3. Replace the command-specific helper with Pathex player and turn-history mutations.
4. Run focused Koala game tests, the Koala namespace, compiler warnings validation, and strict OpenSpec validation.

Rollback restores the prior `apply_submit/3` call and helper. No data, protocol, deployment, or compatibility migration is required.

## Open Questions

None.
