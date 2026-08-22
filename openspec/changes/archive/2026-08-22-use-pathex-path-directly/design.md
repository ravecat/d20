## Context

`D20.Game.__using__/1` currently configures Pathex and injects a private runtime `lens/1` helper that only delegates to `path/1`. Koala uses that alias for aggregate transitions. Next Station: London, including the uncommitted rule-aligned phase model from issue #220, instead mixes struct updates, `Map.put/3`, `put_in/2`, and map rebuilding across the same state machine.

The existing `D20.GameTest` also executes generic Pathex traversals against maps and structs. Those assertions primarily verify Pathex and Elixir behavior rather than a D20-owned result. Concrete game transition tests already provide stronger coverage of the integration.

## Goals / Non-Goals

**Goals:**

- Use Pathex `path/1` directly in game aggregate reducers.
- Express Next Station authoritative state transitions through field, keyed-player, and collection paths.
- Keep the rule-aligned Next Station phase graph and all observable behavior unchanged.
- Keep `D20.GameTest` focused on callbacks, defaults, server selection, and initialization owned by D20.

**Non-Goals:**

- Replacing Pathex, changing Rules calculations, or moving legality out of Rules.
- Rewriting projections, permissions, commands, servers, AsyncAPI, or the separate client.
- Requiring Pathex for ordinary constructors, changesets, or read-only accessors.
- Preserving a compatibility alias for private `lens/1`.

## Decisions

### Retain shared Pathex configuration but remove the private alias

`D20.Game.__using__/1` will continue to call `use Pathex, default_mod: :map` and import only `Pathex.Lenses.all/0`. It will stop defining `lens/1`. Koala and Next Station will use the resulting `path/1` macro directly.

Keeping the alias was rejected because it adds no validation or domain meaning and hides the library primitive. Moving Pathex setup into each game was rejected because all game engines should share one map-path configuration.

### Use paths at the aggregate mutation boundary

Next Station `Game` helpers will mutate aggregate fields with `Pathex.set!/3`, `Pathex.over!/3`, `Pathex.force_over!/4`, composed actor-id paths, and `all/0`. Collection paths will replace full player-map rebuilds when every player receives the same update. First-round pencil offsets will reduce validated per-player assignments through keyed paths because each player receives a different value.

Rules will continue returning accepted player values. The aggregate will commit those values through a keyed player path and then run the existing completion transition. Read-only helpers and value constructors will retain the simplest native Elixir operations.

Rewriting Rules with Pathex was rejected because Rules derives legal values rather than owning aggregate transition commits. Forcing every map operation through Pathex was rejected because the objective is one mutation boundary, not replacing clear constructors or lookups.

### Test owned behavior instead of dependency mechanics

The Pathex-specific `D20.GameTest` fixture functions and traversal test will be removed. `D20.GameTest` will retain coverage for engine callback validation, default and custom servers, default preview, changesets, and initialization. Koala and Next Station game tests will remain the acceptance boundary for mutation behavior, while warnings-as-errors compilation verifies that the injected Pathex surface is available.

Keeping generic map, struct, bang, and `all/0` assertions was rejected because those are Pathex contracts and provide less useful regression evidence than complete game transitions.

## Risks / Trade-offs

- [Direct `path/1` macro expansion increases compile time compared with one runtime helper] -> Accept the explicit vocabulary, run forced compilation, and report the observed slow-module warning.
- [A partial Next Station rewrite could leave competing mutation styles] -> Search `Game` state-transition helpers for `Map.put/3`, `put_in/2`, direct game struct updates, and the removed status helper.
- [Path composition could change actor-key or collection semantics] -> Preserve validated inputs and run focused Koala and Next Station aggregate tests plus the complete backend suite.
- [The refactor shares files with uncommitted issue #220 work] -> Apply it in the current master checkout as requested and validate the combined state rather than isolating from the required phase baseline.

## Migration Plan

1. Remove the shared alias and update Koala direct paths.
2. Rewrite Next Station aggregate state mutations without changing command dispatch or Rules outputs.
3. Remove dependency-mechanics coverage from `D20.GameTest` and run focused and broad validation.
4. Synchronize the three capability deltas and archive the change.

Rollback restores the private helper and prior mutation expressions while retaining the phase vocabulary from issue #220. No data or protocol rollback is required.

## Open Questions

None.
