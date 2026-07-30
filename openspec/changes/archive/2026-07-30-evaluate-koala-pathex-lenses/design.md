## Context

`D20.KoalaRescueClub.Game` is an Ecto embedded schema and deterministic reducer. Its command application clauses currently combine Pathex in `join`, direct struct updates and `Map.new/2` in `start`, and a struct update plus `set_player_statuses/2` in `roll`. Pathex 2.6 is already a runtime dependency.

This experiment must preserve the existing `D20.Game.dispatch/2` result and error contracts. A missing aggregate field is a programming error, not a new domain error, and authoritative readiness must remain in `Rules.ready_to_start?/1`.

## Goals / Non-Goals

**Goals:**

- Provide one private compile-time Pathex lens macro for Koala aggregate field references without maintaining a second field list.
- Express every `apply_command/2` aggregate read and mutation through Pathex paths.
- Preserve join initialization and idempotency, start initialization and roster reset, and roll status behavior.
- Produce a small implementation sample from which the lens approach can be evaluated.

**Non-Goals:**

- Migrate `left`, `apply_submit/3`, turn resolution, scoring, or any reducer outside `apply_command/2` in this experiment.
- Move rule validation or invariants out of `Command` and `Rules`.
- Add a public lens API, a generic reducer framework, or another dependency.
- Change the aggregate schema, command payloads, projections, errors, persistence, or game protocol.

## Decisions

### Define one private compile-time lens macro without a field whitelist

`Game` will `use Pathex` with the `:map` modifier. An unconstrained private `lens/1` macro will inline `path(field)` at each reducer call. Calls such as `lens(:players)` and `lens(:phase)` stay close to reducer logic, do not allocate a separate public lens module, and retain Pathex's generated path code without repeating the embedded-schema field names in another attribute.

Alternative considered: validate fields at runtime with `__schema__(:fields)`. That would turn constant paths into runtime path closures and give up Pathex's inline expansion. Alternative considered: read Ecto's compile-time `@ecto_fields` attribute. That attribute is an internal implementation detail rather than a supported Ecto API and would couple the game reducer to Ecto internals.

The embedded schema remains the only field declaration. A misspelled lens field is a programmer defect detected when the corresponding bang operation traverses the aggregate, matching the existing decision that invalid internal paths do not become domain errors.

### Use `force_over!` for idempotent player insertion

The join reducer will compose `lens(:players)` with a map path for `actor_id`, then call `Pathex.force_over!/4` with identity as the update and the newly initialized player as the missing-path default. An existing entry therefore passes through unchanged, while a missing entry receives the complete player value without a preceding membership branch.

Alternative considered: `Pathex.force_set!/3`. It would replace state on duplicate joins and violate the existing idempotency contract. Alternative considered: retaining `join_player/2` around a lens call. That would not test whether the mutation can be understood directly from the reducer clause.

### Derive phase from the post-insertion aggregate and set it through its lens

After player insertion, the reducer will call `Rules.ready_to_start?/1` on the updated aggregate and use `Pathex.set!/3` with `lens(:phase)` for the resulting `:ready` or `:setup` value. Player creation, insertion, and readiness refresh will remain visible in one `apply_command/2` clause without calls to join-specific mutation helpers.

The bang operations are intentional. All traversed fields are compile-time schema invariants, so a missing or incompatible path is a code defect. Converting that defect to `:error` would introduce an undocumented dispatch result and hide schema drift.

`refresh_setup_phase/1` remains available to the out-of-scope `left` path. The experiment removes `join_player/2` and keeps the join transition self-contained while the separate start and roll decision below completes the `apply_command/2` migration.

### Express start and roll with field and collection lenses

The `start` clause will view the players map through `lens(:players)`, derive mode from its size, set `phase`, `mode`, `round`, and `turn` through field lenses, and use `Pathex.Lenses.all/0` to transform every player value. This preserves actor-id keys while resetting each accepted player to the existing ready state.

The `roll` clause will retain the server-owned dice effect, then set `phase` and `roll` through field lenses. A composed `players`, `all()`, and `status` path will set every player status to `:pending` without rebuilding the map in command application.

Alternative considered: wrap existing struct updates and helpers around only the player lens. That would retain multiple mutation vocabularies inside `apply_command/2` and would not test the requested uniform reducer shape. Alternative considered: use `alongside/1` for all top-level fields. `alongside/1` applies one value to every focus and cannot express the different values required by `start`.

`game_mode/1` will be removed because mode derivation is used only by the lens-based `start` clause. `set_player_statuses/2` remains for out-of-scope automatic turn advancement in `maybe_finish/1`.

## Risks / Trade-offs

- [Lens pipelines are longer than direct struct updates] -> Keep the experiment limited to `apply_command/2` and evaluate readability and compile cost before migrating any other reducer function.
- [A misspelled lens field is not rejected while compiling the macro call] -> Keep reducer lens arguments as literals and use bang operations so an invalid internal path fails rather than becoming an undocumented domain result.
- [`force_over!` accidentally replaces an existing player] -> Use identity for the present-path update and add an equality regression test after mutating existing player state.
- [Lens syntax gives a false impression that rules are generic mutations] -> Keep command validation and readiness derivation in `Command` and `Rules`; lenses only address and update state.
- [A missing path raises instead of returning a domain error] -> Treat schema-path failure as a programmer defect and retain existing domain error semantics.
- [`all()` silently changes roster keys or skips a player] -> Use the map collection lens, retain multi-player start and roll assertions, and add focused coverage that every player is reset on start.
- [Generated path expansion increases aggregate compile time] -> Record that full `apply_command/2` migration pushed `game.ex` beyond Mix's 10-second compilation notice and measure or reduce repeated generated paths before expanding the pattern to other reducer functions.

## Migration Plan

1. Add the Pathex setup and private compile-time lens macro to `Game` without duplicating schema metadata.
2. Add a focused duplicate-rejoin regression test.
3. Replace the `join` reducer body and remove the now-unused `join_player/2`.
4. Rewrite `start` and `roll` through field and collection lenses and remove the now-unused `game_mode/1`.
5. Format the touched files and run the focused Koala game tests followed by the complete Koala namespace.

Rollback restores the helper-based `join`, direct `start` and `roll` reducers, and their superseded helpers, then removes the experimental lens definitions and regression tests. No data or protocol migration is required.

## Open Questions

None.
