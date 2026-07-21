## Context

The `assets/` package currently resolves TypeScript 5.9.3. Its stable command boundary is `bun run typecheck`, exposed as `mix typecheck`, and the command runs `tsc --noEmit` before `svelte-check`. The TypeScript project is strict, uses bundler module resolution, explicitly limits ambient types to `vite/client`, and has `noEmit` enabled.

TypeScript 7.0.2 is the current stable release as of 2026-07-21. It replaces the JavaScript compiler with a native implementation and exposes the `tsc` CLI, but TypeScript 7.0 does not expose the compiler API expected by the current `typescript-eslint` and Svelte tooling. The latest `typescript-eslint` line still declares `typescript >=4.8.4 <6.1.0`, so the canonical `typescript` package must remain on the supported TypeScript 6 line while TypeScript 7 is installed under a second alias.

The current `tsconfig.json` cannot be consumed unchanged because TypeScript 7 reports `baseUrl` as removed. The existing `paths` values are already relative to the config file and a diagnostic TypeScript 7 run passed after removing only `baseUrl`. A directional local probe of the same project configuration reported 0.446-0.476 seconds for TypeScript 7 and 2.10-6.36 seconds for TypeScript 5.9 across three invocations. The variance makes these observations unsuitable as formal acceptance data, so implementation needs a controlled benchmark.

Vite 8 is a separate compilation path. It strips TypeScript syntax with Oxc and deliberately does not type-check during `vite build`, so a TypeScript upgrade can improve static checking and CI time but is not expected to accelerate production bundling. See the official [TypeScript 7 release](https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/), [TypeScript 6 bridge release](https://devblogs.microsoft.com/typescript/announcing-typescript-6-0/), and [Vite TypeScript pipeline](https://vite.dev/guide/features.html#typescript).

The completed Vite 8, ESLint/Oxfmt, and browser-policy changes already touch the same package manifest and lockfile. This migration must be applied on top of their resolved state and keep its dependency diff attributable to TypeScript.

## Goals / Non-Goals

**Goals:**

- Use the stable native TypeScript 7 compiler for the repository's standalone TypeScript check.
- Preserve working TypeScript compiler API consumers through the official TypeScript 6 compatibility package.
- Remove TypeScript 7-incompatible configuration without changing import aliases, strictness, included files, browser targets, or command names.
- Demonstrate the compiler performance benefit with a reproducible same-machine benchmark.
- Keep linting, Svelte checking, tests, and production asset builds passing.

**Non-Goals:**

- Speed up Vite transpilation, Rolldown bundling, CSS compilation, or HMR through TypeScript.
- Convert JavaScript or Svelte files to TypeScript, change application types, or adopt new strictness flags unrelated to the migration.
- Force `typescript-eslint` or `svelte-check` to use an unsupported TypeScript 7 compiler API.
- Change editor configuration, browser support, runtime polyfills, public frontend interfaces, or backend behavior.
- Upgrade unrelated direct dependencies or reformat frontend source files.

## Decisions

### Run TypeScript 7 and the TypeScript 6 API side by side

Replace the direct TypeScript 5.9 dependency with a Bun-compatible side-by-side layout:

```json
{
  "devDependencies": {
    "@typescript/native": "npm:typescript@^7.0.2",
    "typescript": "^6.0.3"
  }
}
```

The TypeScript 7 alias contributes the `tsc` binary used by the existing typecheck script. The canonical `typescript` package exposes the 6.0 compiler API to peer consumers. Implementation must verify `bun run tsc --version`, the imported `typescript` API version, and Bun's bin link after resolving the lockfile rather than assuming bin-link precedence. The one-time TypeScript 6 bridge check invokes the canonical package binary directly because the public `tsc` name belongs to TypeScript 7.

Alternative considered: install TypeScript 7 directly as `typescript`. This leaves the current `typescript-eslint` peer range unsatisfied and provides no compiler API for tooling that imports `typescript`.

Alternative considered: install the official `@typescript/typescript6` wrapper under the `typescript` alias. Bun 1.3.13 resolves the wrapper's internal `@typescript/old` npm alias back to the wrapper itself, producing an empty API and a no-op `tsc6`; the direct TypeScript 6 package avoids that recursive resolution while preserving the required API.

Alternative considered: stop at TypeScript 6. TypeScript 6 is useful as a bridge and API compatibility layer, but it does not deliver the native compiler performance requested by this change.

### Remove `baseUrl` and preserve explicit aliases

Delete `baseUrl` from `assets/tsconfig.json` and retain every `paths` key and value unchanged. Each mapping already starts with `./` and therefore remains relative to the config file without `baseUrl`. Keep the explicit `target`, `module`, `moduleResolution`, `types`, `strict`, `noEmit`, include, and exclude settings so TypeScript 7 default changes do not silently redefine the project.

Run a TypeScript 6 bridge check with stable type ordering before the TypeScript 7 check. Source changes are allowed only for newly exposed real type errors and must be minimal and behavior-preserving.

Alternative considered: set a catch-all `"*": ["./*"]` mapping. The project does not use `baseUrl` for arbitrary bare imports, and a catch-all would preserve a broader resolution behavior that is neither needed nor desirable.

### Preserve the existing command boundary

Keep `bun run typecheck` as `tsc --noEmit -p tsconfig.json && svelte-check --tsconfig tsconfig.json` and keep the `mix typecheck` alias unchanged. The first stage resolves to native TypeScript 7. The second stage remains Svelte-aware and consumes the TypeScript 6 API through the `typescript` package name.

Alternative considered: replace both stages with native `tsc`. Native `tsc` does not replace Svelte component analysis, so that would reduce coverage.

Alternative considered: add type-checking to `vite build`. Vite intentionally separates transpilation from whole-program static analysis; combining them would change the current command contract and obscure which operation improved.

### Measure compiler and build performance separately

Capture measurements before and after the dependency change from the same source revision, machine, power profile, and installed dependency state. Run one unrecorded warm-up followed by at least five serial recorded runs for each case and compare medians:

- Standalone `tsc --noEmit -p tsconfig.json` compiler time.
- Complete `bun run typecheck` wall time, including `svelte-check`.
- `mix assets.build` wall time as a non-regression observation only.

The standalone native compiler median must be at least twice as fast as the TypeScript 5.9 baseline to validate the stated purpose. The complete command may show a smaller gain because `svelte-check` remains on the compatibility API. Vite build time is not a TypeScript success metric, but a repeatable regression greater than 10 percent must be investigated before acceptance.

Alternative considered: use a single timed run. Compiler startup, filesystem cache, and concurrent machine load make one sample too noisy for a migration decision.

### Keep the dependency and runtime change isolated

Regenerate `assets/bun.lock` with Bun and inspect direct and transitive changes. No direct packages other than the two TypeScript entries are intentionally changed. Vite output, browser targets, application source, manifest entry names, and Phoenix integration remain existing contracts.

## Risks / Trade-offs

- [Bun links the aliased binaries differently than expected] - Verify `bun run tsc --version` reports 7.0.x, the `tsc` bin link targets `@typescript/native`, and the imported `typescript` API reports 6.0.x before relying on the existing script.
- [A tool imports TypeScript 7 despite the compatibility alias] - Inspect the resolved dependency tree and run ESLint plus `svelte-check`; retain TypeScript 6 under the exact `typescript` package name.
- [TypeScript 6 and 7 report different diagnostics] - Run the TS6 bridge check with stable type ordering and both final checkers, then fix only demonstrated source incompatibilities.
- [Two compiler installations increase dependency size] - Accept the temporary duplication to preserve supported APIs, and remove TypeScript 6 in a later change only after all compiler API consumers declare TypeScript 7 compatibility.
- [Benchmark noise overstates or hides improvement] - Use warm-ups, at least five serial samples, medians, and identical source and machine conditions; report raw samples with the implementation handoff.
- [The TypeScript upgrade is assumed to accelerate production bundles] - Report Vite timing separately and describe the expected benefit as type-check and CI latency only.
- [Existing uncommitted toolchain work pollutes the lockfile diff] - Apply this change only after the prerequisite frontend toolchain state is committed or otherwise captured as the reviewed baseline.

## Migration Plan

1. Confirm the completed Vite 8, ESLint/Oxfmt, and browser-policy work is the accepted baseline, then record resolved compiler and peer ranges plus pre-migration checks and benchmarks.
2. Remove `baseUrl` while preserving every alias, install TypeScript 7 under its native alias and TypeScript 6 under the canonical package name through Bun, and inspect the scoped manifest and lockfile diff.
3. Verify the native `tsc` binary and TypeScript 6 API versions, run the TypeScript 6 bridge check through its package binary, and run native TypeScript 7 plus Svelte checking through both stable command boundaries.
4. Run frontend formatting checks, linting, tests, the production build, manifest assertions, and `just check`.
5. Repeat the controlled benchmark, report raw samples and medians, and confirm that only type-check performance is attributed to TypeScript 7.

Rollback restores TypeScript 5.9 as the direct `typescript` dependency, removes the native alias, restores `baseUrl`, and regenerates the lockfile. No data, protocol, deployment, or runtime rollback is required.

## Open Questions

None.
