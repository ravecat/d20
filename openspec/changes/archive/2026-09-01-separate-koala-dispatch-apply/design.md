## Context

`D20.KoalaRescueClub.Game` is an ephemeral Ecto embedded aggregate behind the existing `D20.Game` interface. Its public `dispatch/2` already routes string-named `D20.Command` values through `Command.validate/1` and `Rules`, but accepted state changes then fan out through `apply_command/2`, `apply_command/3`, and `maybe_*`, badge, scoring, and player-update helpers that can each return a new `Game.t()`.

Pathex is already supplied by `use D20.Game`, and the current command application clauses use its map paths. The refactor primarily changes `lib/d20/koala_rescue_club/game.ex`; removing its non-contractual player-lookup proxy also updates the internal `Rules` consumer and removes the proxy's obsolete unit test. The public command, Session, custom server, channel, projection, and AsyncAPI boundaries must not observe an internal transition representation or any behavioral change. Issue [#265](https://github.com/ravecat/d20/issues/265) excludes running tests and requires formatting and warning-free compilation.

## Goals / Non-Goals

**Goals:**

- Keep public `dispatch/2` as a thin adapter over private command execution and state application.
- Put phase routing, validation, state-dependent decisions, and randomness resolution in private `execute/2` clauses that return transition data without changing the aggregate.
- Represent accepted work as private, already-resolved transition data before changing the authoritative aggregate.
- Make private `apply/2` the only function whose interface accepts a `Game.t()` and returns a transformed `Game.t()`.
- Make join, leave, start, roll, submit, badge, round, advance, and finish mutations directly discoverable as Pathex-based `apply/2` clauses.
- Inline one-use command orchestration and retain only meaningful leaf calculation helpers that do not delegate through other local helpers.
- Remove the public `Game.fetch_player/2` proxy so player lookup remains an implementation detail inside `Rules`.
- Preserve clause routing, validation order, random-roll timing, transition order, results, errors, and game facts exactly.

**Non-Goals:**

- Change `D20.Game`, `D20.Command`, `D20.Sessions.Session`, either Session or Koala server, channels, projections, permissions, AsyncAPI, or the dependent iframe client.
- Add a public event model, Commanded, persistence, an event store, replay, serialization, or a reusable transition framework.
- Change command names or payloads, aggregate fields or types, phase behavior, scoring, badge rules, or error values.
- Add or run tests or fixtures; the obsolete test for the deleted lookup proxy is removed rather than replaced.
- Refactor other game engines or move decision logic into another module.

## Decisions

### Use private data-only transitions, not public domain events

`Game` will define private transition shapes for the resolved facts needed by state application:

- `{:player_joined, players, setup_phase}`
- `{:player_left, players, setup_phase}`
- `{:game_started, mode}`
- `{:die_rolled, value}`
- `{:turn_submitted, player_id, player}`
- `{:badges_awarded, players}`
- `{:round_scored, players}`
- `{:turn_advanced, round, turn}`
- `{:game_finished, scores}`

The exact private type can be documented with `@typep`, but it is not added to any public callback or protocol. Each tuple carries decisions that would otherwise have to be recomputed while mutating: resolved roster and setup phase, start mode, rolled value, resolved player, post-award players, post-round players, next round/turn, or final scores.

Alternative considered: pass validated `D20.Command` structs to `apply/2`. That retains command decoding, random resolution, and completion decisions inside the mutation seam. Alternative considered: introduce structs or Commanded events. The tuples are local, short-lived implementation data and do not justify a public module, dependency, persistence semantics, or replay contract.

### Make dispatch a thin adapter over execute and apply

Public `dispatch/2` keeps the existing `D20.Game` callback and result contract. It calls private `execute/2`, propagates an error unchanged, or reduces the returned ordered transition list over the source aggregate through direct `apply/2` calls. It contains no command-specific routing, validation, randomness, or transition decisions.

Private `execute/2` retains the existing command clause order and guards:

1. Setup/ready `join` still runs `Command.validate/1` and `Rules.validate/2` in that order.
2. In-progress `join` and `left` still return `{:ok, []}` without validating the command or creating a transition.
3. Setup/ready `left` remains the existing unvalidated, idempotent roster removal.
4. `start` and `roll` still validate command then rules.
5. Submit-phase commands still validate first and call `Rules.resolve_turn/2` exactly once.
6. Finished and invalid-phase fallbacks retain their current ordering and errors.

For join and leave, their execute clauses directly derive the prospective players map and then resolve `:ready` or `:setup` from that map's size and `Ruleset.player_count_range/0`, the same invariant used by `Rules.ready_to_start?/1`. A duplicate join uses the existing player value; a missing leave leaves the map unchanged. The one-use player initialization is inlined in the lazy join insertion so the complete command decision reads top-to-bottom in one clause.

After roll validation, `Dice.roll!/1` runs in execute so `{:die_rolled, value}` is deterministic when applied. It is still called exactly once and only after the same validation succeeds.

Every successful execute clause returns `{:ok, transitions}`. Commands with one resolved effect return a one-element list, submit may return an ordered multi-transition list, and accepted in-progress join or leave commands return an empty list. Dispatch performs the only reduction and returns `{:ok, game}`. There is no `apply_all`, `maybe_*`, or other aggregate-returning orchestration helper.

Alternative considered: leave command-specific clauses in dispatch. That preserves behavior but keeps the public adapter responsible for both command execution and application. Alternative considered: mutate the roster first and then decide its phase from the intermediate aggregate. That makes transition selection depend on state already applied and leaves decision work on the application side. Alternative considered: keep rolling inside `apply/2`. That makes an ostensibly resolved transition nondeterministic.

### Resolve the complete submit progression from field values before applying it

The submit `execute/2` clause directly uses the original aggregate facts, normalized command, and the player already returned by `Rules.resolve_turn/2` to build transition data, never `Game.t()`.

The clause appends the accepted adjusted die value to the resolved player's turn list and creates the prospective players map. If not every prospective player is submitted, the result is only `{:turn_submitted, player_id, player}`. If the shared turn is complete, the same clause derives the full ordered sequence before the first transition is applied:

1. `:turn_submitted` stores the resolved player and accepted turn value.
2. `:badges_awarded` stores players after the existing solo or multiplayer badge rules.
3. `:round_scored` is included only when `Ruleset.round_end_turn?/1` is true and stores players after appending that round's score.
4. `:game_finished` is selected for the final turn and carries scores derived from the post-award, post-round players; otherwise `:turn_advanced` carries the existing next round and turn.

This preserves the current order `submit -> badges -> optional round score -> finish or advance`, including turn 30 scoring before final totals. The decision functions inspect player maps, `mode`, `round`, `turn`, and the rulesheet; they do not construct or return an intermediate `Game.t()`.

Alternative considered: have each `apply/2` clause decide and recursively call the next clause. That hides the completed transition sequence in the mutation seam and reproduces the current nested reducer chain. Alternative considered: collapse completion into one large submitted transition. Separate tags make badge, round, advance, and finish mutations independently discoverable as required by the issue.

### Make every aggregate write occur directly in a Pathex apply clause

Each private `apply/2` clause pattern-matches one transition and performs only its described writes with `Pathex.set!/3`, `Pathex.over!/3`, `Pathex.force_over!/4`, and composed player collection paths as appropriate. Bang operations remain intentional because missing schema paths are programmer defects, not domain errors.

The clauses preserve the current writes:

- joined/left: replace the already-resolved players map and setup phase;
- started: set `:roll`, captured mode, round and turn `1`, and reset each player's status, rounds, badges, and turns;
- rolled: set `:submit`, store `%{value: value}`, and mark every player pending;
- submitted: store the resolved player with the accepted turn value;
- badges/round: replace players with the corresponding already-derived map;
- advanced: set `:roll`, next round/turn, clear roll, and mark every player ready;
- finished: set `:finished` and store final scores without a next-turn reset.

No nested helper accepts and returns `Game.t()`. Pure helpers may still update an individual player or players map while calculating a resolved transition, because those values are transition facts rather than authoritative aggregate application.

Alternative considered: retain `maybe_resolve_turn/1`, `maybe_score_round/1`, `maybe_finish/1`, and aggregate-shaped badge/scoring helpers around calls to `apply/2`. Those functions would remain additional state-transforming seams and would defeat locality.

### Refactor calculations around explicit facts without changing formulas

Only three meaningful leaf calculations remain behind local function names:

- mode-specific `award_badges/4` clauses take rulesheet, mode, round, and players and perform badge satisfaction, achiever selection, and player updates directly;
- `score_round/2` takes rulesheet and players and computes area, hospital, and round totals directly;
- `score_players/3` takes mode, rulesheet, and players and computes badge points, totals, and optional solo rank directly.

These leaf functions call project rules APIs and standard-library functions but no other local helpers. Join initialization, roster readiness, game mode, submit completion, and transition sequencing remain inline in their execute clauses. This removes proxy methods and multi-level navigation without creating temporary `%Game{}` values.

Alternative considered: create temporary `%Game{}` copies during decision derivation. Although immutable, those copies blur the requested rule that `apply/2` is the aggregate transformation seam and encourage helpers to keep broad aggregate interfaces.

### Keep player lookup inside Rules rather than Game's public API

`Game.fetch_player/2` is not a `D20.Game` callback and only forwards to `Map.fetch(game.players, player_id)`. Its production callers are four rules paths that already depend on the Koala aggregate shape: submit availability, turn options, pending-player resolution, and join/start player-count validation. Those call sites use `Map.fetch/2` directly, and the redundant public function and its dedicated unit test are removed.

Alternative considered: retain the method as an aggregate query. It adds a public API outside the intentionally small game behavior without adding validation, authorization, or representation independence for its only consumer.

## Risks / Trade-offs

- [Precomputing a transition list could accidentally use pre-submit rather than post-submit facts] → Build one prospective players value, thread its post-badge and optional post-round successors through the submit execute clause, and preserve the explicit transition order there.
- [Replacing a whole players map in badge and round clauses could overwrite the submitted player] → Derive each successive map from the prior prospective map, and apply the transitions in exactly that same order.
- [Setup readiness could drift from `Rules.ready_to_start?/1`] → Resolve it inline from `Ruleset.player_count_range/0`, the same static source used by Rules.
- [Moving randomness could change rejection behavior] → Keep `Dice.roll!/1` after the same `Command.validate/1` and `Rules.validate/2` chain; rejected rolls never call it.
- [Private transition names could be mistaken for durable events] → Keep the type and clauses private, do not serialize or publish transitions, and state explicitly that only the final aggregate leaves `dispatch/2`.
- [No test execution leaves behavioral regressions less directly detected] → Keep the diff to one module, preserve validation/decision ordering explicitly, inspect the focused diff, format the file, and compile with warnings as errors as requested.

## Migration Plan

1. Add the private transition type and explicit command decision logic in `D20.KoalaRescueClub.Game`.
2. Replace command-specific public `dispatch/2` clauses with one adapter that reduces transition lists returned by private `execute/2`.
3. Move the existing command guards, validation order, no-op results, randomness, and transition decisions into private `execute/2` clauses.
4. Add Pathex `apply/2` clauses for command and completed-turn transitions.
5. Inline one-use orchestration and flatten badge, round-score, and final-score calculations into leaf helpers that do not call other local helpers; remove superseded `apply_command/*`, `maybe_*`, and proxy helpers.
6. Format `lib/d20/koala_rescue_club/game.ex`, compile with warnings as errors, strictly validate the OpenSpec change, and inspect the focused diff. Do not run tests.

Rollback restores the previous private reducer/helper layout in the same module. The aggregate is process-local and ephemeral, so no migration, replay, persisted-data conversion, protocol version, or coordinated deployment step is required.

## Open Questions

None.
