## Context

After `migrate-assets-to-vite-8`, the shell builds with Oxc and Rolldown but still inherits Vite's fixed Baseline snapshot and has no shared policy for compatibility tooling. The desired policy is a moving Baseline Widely Available query that includes downstream browsers while excluding Firefox versions below 128, which is the minimum officially targeted by the installed Tailwind CSS 4 line.

Browserslist can resolve that policy for linting and inspection, but Vite 8 does not read arbitrary Browserslist queries as `build.target`. Oxc accepts the same browser target values as esbuild, so the existing `browserslist-to-esbuild` converter can supply a compact minimum-version array that is also valid for Oxc. The package name describes its original consumer rather than limiting the returned target format.

## Goals / Non-Goals

**Goals:**

- Make one Browserslist declaration in `assets/package.json` the browser-support source of truth.
- Let developers inspect both the complete resolved browser set and the compact build targets.
- Fail the existing ESLint command when recognized Web or ES APIs are unsupported by any declared target, while respecting guarded feature detection and declared polyfills.
- Drive Vite 8 JavaScript lowering and its default CSS target from the same policy.
- Preserve existing `mix assets.*`, package `check`, and top-level `just` command boundaries.

**Non-Goals:**

- Add runtime polyfills, legacy bundles, user-agent blocking, or browser upgrade UI.
- Add CSS source compatibility linting or HTML attribute compatibility linting.
- Claim that static compatibility data replaces browser testing or covers browser-specific defects.
- Pin the Baseline query to a date; the requested policy intentionally advances as Browserslist data and time move forward.

## Decisions

### Store the exact policy in `assets/package.json`

Add:

```json
"browserslist": [
  "baseline widely available with downstream",
  "not Firefox < 128"
]
```

The first query selects the moving Baseline Widely Available core and downstream browser versions. The negative query removes Firefox versions below Tailwind's supported floor without manually duplicating the Chrome, Edge, Safari, iOS, Opera, or other downstream mappings.

Alternative considered: explicit fixed browser versions. That is more reproducible but contradicts the requested moving Baseline policy.

### Expose full and compiler-oriented inspection commands

Add `browsers` for the Browserslist CLI output and `browsers:target` for the compact converter output. These commands make policy review possible without reading lock internals and give validation a direct way to prove the Firefox floor and downstream mapping are active.

### Apply compatibility linting through the existing ESLint command

Add `eslint-plugin-compat` using its flat recommended configuration and set `lintAllEsApis: true`. The existing `lint`, Mix alias, and `just check` therefore enforce recognized Web API and ES API compatibility without a parallel lint command. Default guarded-feature behavior remains enabled; no polyfills are declared until the repository actually provides them.

Alternative considered: lint only Web APIs. That leaves `Array`, `Object`, `Promise`, and similar ES API compatibility outside the policy despite the user's request to detect unsupported implementation choices.

### Convert Browserslist output once for Vite 8

Load `browserslist-to-esbuild` in `vite.config.mjs`, resolve the project policy once, and assign the resulting compact array to `build.target`. Oxc officially accepts esbuild-compatible target values, including Chrome, Edge, Firefox, iOS, Opera, and Safari. Vite's default `build.cssTarget` inherits the same array, so Lightning CSS minification and syntax lowering follow the policy without separate duplicate configuration.

Alternative considered: hard-code the compact array next to the Browserslist query. That creates two sources of truth and allows lint and build targets to drift. Writing a local converter would duplicate browser alias, version range, and minimum selection logic.

### Keep browser support separate from runtime guarantees

The policy governs static compatibility data, syntax lowering, and CSS build targeting. It does not add polyfills or validate partial implementations, permissions, user settings, rendering differences, or browser defects. Existing tests remain required, and future cross-browser end-to-end coverage is a separate capability.

## Risks / Trade-offs

- [The moving Baseline result changes after dependency updates or with time] -> Expose the resolved commands, review their output in dependency-update changes, and keep the Firefox floor explicit.
- [Compatibility linting reports existing intentional or guarded APIs] -> Preserve recognized conditional checks, add narrowly scoped polyfill declarations only for installed polyfills, and avoid blanket rule suppression.
- [The converter was named for esbuild and is not maintained by Vite or Oxc] -> Rely only on its compact target output, which Oxc documents as supported, cover the resolved array through the inspection command and production build, and replace the converter if Vite gains native Browserslist query support.
- [Build lowering is mistaken for polyfilling] -> Document that the integration covers syntax and CSS targeting only; unsupported runtime APIs remain lint errors or require explicit guarded fallback/polyfill work.
- [Downstream browser compatibility differs from the mapped engine] -> Treat downstream mapping as a policy approximation and retain real-browser validation for product-critical flows.

## Migration Plan

1. Confirm the Vite 8 change is complete and validated before editing browser-policy files.
2. Add the exact Browserslist declaration, inspection scripts, and direct development dependencies through Bun.
3. Add the ESLint compatibility configuration, run lint, and resolve findings through compatible implementation, guarded fallback, or truthful polyfill declaration.
4. Derive Vite 8 `build.target` from the same policy and validate the compact targets, production build, manifest entries, and output warnings.
5. Run frontend checks, tests, strict OpenSpec validation, `just check`, and production Docker build, then review the complete scoped diff.

Rollback removes the Browserslist field, scripts, three dependencies, ESLint compatibility configuration, derived Vite target, documentation, and corresponding lockfile changes. Vite 8 remains installed because it is the prerequisite change.

## Open Questions

None.
