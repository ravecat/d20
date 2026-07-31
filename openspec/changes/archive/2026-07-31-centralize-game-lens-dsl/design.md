## Context

`D20.Game.__using__/1` is the existing compile-time boundary for game engine modules. It installs the behaviour, default server callback, default preview callback, and overridable definitions. Koala Rescue Club separately calls `use Pathex`, imports `Pathex.Lenses.all/0`, and defines a private `lens/1` macro before using those operations throughout its aggregate transitions.

Only Koala currently defines `lens/1`; no `D20.Game` consumer defines a conflicting `all/0` function or macro. Pathex is already an application dependency, so the change centralizes existing setup rather than introducing a new runtime or package boundary.

## Goals / Non-Goals

**Goals:**

- Make the supported aggregate lens vocabulary part of `use D20.Game`.
- Preserve the existing private, literal-field `lens/1` expansion and `:map` path modifier.
- Supply the `all/0` collection lens needed for map-value mutations.
- Remove the corresponding Koala-local setup and verify the shared DSL directly.

**Non-Goals:**

- Make `lens/1` a public runtime or macro API callable as `D20.Game.lens/1`.
- Import unrelated helpers such as `Function.identity/1` into every game engine.
- Migrate Qwinto, Fliptown, or Next Station London transitions to lenses.
- Change any game callback, server selection, aggregate state, projection, or public contract.

## Decisions

### Inject Pathex setup from the existing game DSL

The quoted block returned by `D20.Game.__using__/1` will call `use Pathex, default_mod: :map` before defining engine callbacks. This gives each consumer the same compiled `path/1`, composition operators, and Pathex requirements that Koala currently configures locally.

Alternative considered: create a second `D20.Game.Lenses` module that every engine must also `use`. That would preserve two setup calls in Koala and make lens support optional through a parallel DSL even though `D20.Game` already owns aggregate compile-time conventions.

### Keep the aggregate lens private to each consumer

`D20.Game` will inject the existing `defmacrop lens(field)` definition into the caller. Each literal field is still expanded inside the game module, the resulting macro remains private, and no runtime function or new exported API is introduced.

Alternative considered: expose `D20.Game.lens/1` as a public macro and import it. That would unnecessarily enlarge the module API and weaken the current property that the helper exists only inside game engine implementations.

### Import only the established collection lens

The shared quote will import `Pathex.Lenses` with `only: [all: 0]`. This preserves the exact collection surface already exercised by Koala and avoids importing `any/0`, `star/0`, filtering lenses, or unrelated functions without a demonstrated engine use case.

`Function.identity/1` remains imported by Koala. It is selected by one reducer to preserve an existing player during `force_over!/4`; it is not part of field addressing or collection traversal.

Alternative considered: import all Pathex lenses and `Function.identity/1` from `D20.Game`. That would create a broader implicit namespace and increase future conflict risk without reducing currently repeated lens setup.

### Verify both field and collection paths in D20.Game tests

The existing `D20.GameTest.TestGame` fixture will expose small test-only functions compiled with `lens/1`, `path/1`, the composition operator, and `all/0`. Tests will verify reading a map field and updating every nested player status while preserving actor-id keys. Existing Koala tests will verify that removal of its local declarations does not change aggregate behavior.

Alternative considered: rely only on Koala compilation. Direct `D20.Game` coverage makes the shared DSL contract explicit and catches later changes even if Koala eventually changes its internal lens usage.

## Risks / Trade-offs

- [Every game engine now expands Pathex setup even when unused] -> Keep the injected surface minimal and verify full warnings-as-errors compilation; accept the compile-time cost as the price of one consistent engine DSL.
- [Injected names could conflict with future engine-local definitions] -> Limit collection imports to `all/0`, keep `lens/1` private, and treat those names as reserved by the documented `D20.Game` DSL.
- [Nested quoting could expand `lens/1` in the wrong module] -> Compile a direct `D20.GameTest` consumer and exercise the generated field path.
- [Moving setup could subtly alter Koala paths] -> Preserve the same Pathex modifier and macro body byte-for-byte, then run the complete Koala aggregate test module.

## Migration Plan

1. Add Pathex setup, `all/0`, and the private `lens/1` macro to the `D20.Game` quote.
2. Add direct shared DSL coverage to `D20.GameTest`.
3. Remove the duplicated setup from Koala.
4. Run focused game and Koala tests, full warnings-as-errors compilation, and strict OpenSpec validation.

Rollback restores the three Koala-local declarations and removes the injected declarations and focused test helpers from `D20.Game`. No data, deployment, or protocol migration is required.

## Open Questions

None.
