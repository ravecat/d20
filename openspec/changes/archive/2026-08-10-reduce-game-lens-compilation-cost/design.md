## Context

`D20.Game.__using__/1` automatically configures Pathex map paths, imports `all/0`, and injects a private `lens/1` macro into every game engine. The macro wraps `path(field)`, but Pathex only selects its operation-specific inline generation when the operation receives a direct `path(...)` expression. A `lens(...)` call therefore takes Pathex's generic path-closure branch, and the nested macro expands that complete closure at every call site.

This cost is concentrated in `D20.KoalaRescueClub.Game`, which has 28 Pathex operations. A profiled full compilation attributed 35.45 seconds to that module and produced an 879 KB BEAM file, while the other game aggregates compiled in less than one second and produced 41-42 KB files. An isolated comparison of the unchanged macro DSL against a private runtime helper reduced compilation from 28.7 seconds to 3.0 seconds and generated module size from 899 KB to 248 KB. These single-run measurements establish the direction and provide a baseline for repository-level validation.

The engine-facing requirement remains unchanged in intent: any game module that calls `use D20.Game` must receive one private, field-agnostic `lens(field)` vocabulary without declaring its fields twice or adding game-local setup.

## Goals / Non-Goals

**Goals:**

- Preserve automatic lens availability through `use D20.Game` for every current and future engine.
- Preserve the existing `lens(field)` reducer syntax for arbitrary map or struct fields.
- Define the generic Pathex path closure once per consuming module instead of once per lens call site.
- Preserve `:map` path semantics, composition, `all/0`, bang failures, and existing game transitions.
- Keep `lens/1` private and absent from each engine's exported runtime API.
- Verify the improvement with focused behavior tests and repeatable compiler profiling.

**Non-Goals:**

- Replace Pathex with `Access`, direct struct updates, or another optics library.
- Validate requested fields against Ecto schema metadata or a separate field registry.
- Change Koala reducer expressions, game callbacks, projections, protocols, or stored aggregate state.
- Add a public `D20.Game.lens/1` function or macro.
- Optimize Pathex collection composition beyond the shared field helper.

## Decisions

### Inject a private function from `D20.Game`

The quoted block returned by `D20.Game.__using__/1` will define:

```elixir
defp lens(field), do: path(field)
```

Every consuming engine retains the same unqualified `lens(field)` call shape and receives the helper automatically. `path(field)` is compiled once in the helper body, while each Pathex operation calls the returned closure with its required operation. The helper remains private, so no runtime API is exported.

Alternative considered: replace `lens(...)` call sites with direct `path(...)`. Pathex would generate only the requested operation and compile faster than the current macro, but this removes the shared vocabulary requested for all game engines and still repeats generated code at each path operation.

Alternative considered: put a public function in `D20.Game.Lenses` and import it. This would compile the generic closure once for the whole application, but it adds a new module and exported API. The injected private helper is the smallest change that preserves the current ownership and privacy contract. A shared module can be reconsidered only if per-engine helper compilation remains material after this change.

### Keep field selection unconstrained

`lens/1` will accept the field value supplied by reducer code and pass it directly to Pathex's map path. It will not enumerate Ecto fields or validate literals at compile time. This keeps the helper usable for Ecto structs and plain map aggregates owned by any game.

Invalid bang traversals remain programmer errors. Adding schema checks would duplicate authoritative field declarations and would not cover plain map state consistently.

### Preserve the rest of the shared Pathex setup

`use Pathex, default_mod: :map` and the restricted `Pathex.Lenses.all/0` import remain in `D20.Game`. Existing field and collection compositions therefore keep their runtime results and error behavior. No Koala source change is required.

### Validate behavior and compilation separately

`D20.GameTest.TestGame` will expose a test-only operation that accepts a field argument, proving the injected helper is not restricted to a predetermined field. Focused assertions will exercise both a plain map and a struct, retain collection composition coverage, and verify that `lens/1` is not exported.

Compilation validation will run `mix compile --force --profile time` and record the `D20.KoalaRescueClub.Game` timing plus its BEAM file size. Behavioral validation will run the focused Game and Koala tests before the complete backend suite.

## Risks / Trade-offs

- [Runtime field paths add a function call compared with Pathex's direct inline fast path] -> Keep the same generic closure semantics already selected by the macro wrapper and validate game behavior; tabletop commands are not a throughput-sensitive loop.
- [Every engine receives the private function even when it does not use lenses] -> Keep the helper to one definition and retain the existing automatic DSL contract.
- [Compiler timings vary with host load and caches] -> Compare module-attributed profile output and BEAM size, report the environment and exact commands, and treat the existing order-of-magnitude difference as the acceptance signal rather than a narrow threshold.
- [Changing a macro to a function could alter name resolution inside Pathex composition] -> Exercise direct field access and `lens(...) ~> all() ~> path(...)` through focused tests and existing Koala transitions.

## Migration Plan

1. Update focused `D20.Game` tests to express the arbitrary-field and struct cases.
2. Replace the injected private macro with the private function without changing engine call sites.
3. Run focused tests, format checks, compiler profiling, and the complete backend suite.
4. Sync the delta specification and archive the completed change.

Rollback restores the private macro body. No state, database, configuration, or deployment migration is required.

## Validation Results

The repository-level comparison used Elixir 1.20.0 with Erlang/OTP 28 on the same 8-scheduler development host and the command:

```text
mix compile --force --profile time --long-compilation-threshold 1
```

- Before: `D20.KoalaRescueClub.Game` compiled in 35,451 ms and its BEAM file was approximately 879 KB.
- After: `D20.KoalaRescueClub.Game` compiled in 8,148 ms and its BEAM file was 248,348 bytes.
- Result: module compilation was approximately 4.35 times faster and generated module size fell by approximately 72 percent.

The focused isolated comparison recorded during diagnosis moved from 28,701,534 microseconds and 899,492 bytes with the macro helper to 3,045,490 microseconds and 248,228 bytes with an equivalent private runtime helper. Absolute timings vary with compiler load, while both measurements show the same order-of-magnitude direction and generated-code reduction.

## Open Questions

None.
