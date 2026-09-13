## Context

The existing `assets/package.json` command is `test: vitest run`; `mix assets.test` delegates to it and `just check` includes that boundary. `assets/vite.config.mjs` defines a jsdom unit project, a Chromium/Firefox browser project, and six independent Chromium Storybook projects for light/dark and desktop/tablet/mobile. The visual projects already progress concurrently, with `fileParallelism: false` inside each project and separate ignored Vite caches. Browser isolation is currently enabled by the installed defaults.

Visual projects use `retain-on-failure` tracing. This records successful executions too, then discards their traces. `assets/.storybook/vitest.setup.ts` loads every declared font and runs the native screenshot assertion against the document root with a 15-second budget after each story. Storybook play functions and accessibility checks also execute in each matrix cell.

The historical audit in [evidence.md](evidence.md) used Vitest 4.1.7 and a dirty favorites checkout at base `577c5c34`. Its 585 tests included 81 unit, 126 browser, and 378 visual cases. Those counts and timings are historical; the clean strategy worktree does not include the uncommitted favorites implementation. Full and browser measurements had failures, some runs competed with other processes, and one full run created missing references. There is no established clean, successful full-suite baseline.

`.github/workflows/release.yml` currently builds and publishes the application image without executing frontend tests. A complete release test gate is desired future behavior, not an existing guarantee.

## Goals / Non-Goals

**Goals:**

- Find the greatest repeatable reduction in end-to-end feedback time on the existing hardware and OS, preferring configuration or small supported dependency changes.
- Preserve reviewed screenshots, all meaningful test assertions, Chromium/Firefox behavior coverage, and all six visual combinations.
- Keep one familiar native command surface without new aliases, scripts that choose tests, manually maintained impact lists, or selection based on a contributor's interpretation.
- Separate execution optimizations that run the same suite from dependency selection that runs a smaller suite.
- Record evidence and adoption gates so a later implementation request can choose or reject candidates without treating estimates as commitments.

**Non-Goals:**

- This planning delivery does not run optimization experiments, change configuration, patch dependencies, migrate tests, edit references, or add release jobs.
- Do not reduce assertions, skip themes, viewports, browsers, or accessibility checks, weaken comparison thresholds, or reduce timeout budgets to obtain faster numbers.
- Do not require extra machines, cloud visual services, a new runner, or a custom orchestration layer.
- Do not absorb the separate browser-migration outcome tracked in [issue #280](https://github.com/ravecat/d20/issues/280).

## Decisions

### 1. Use controlled comparisons before selecting an optimization

Every later experiment starts from a named committed source state with stable reviewed references and a recorded test/project inventory. Preserve the historical audit as exploratory evidence; do not reuse its failing and contended full runs as a causal comparison.

Record the native command and flags, source and reference hashes, lockfile, Node/Bun/Vitest/Playwright/browser versions, OS, logical CPU count, memory, cache condition, concurrent workloads, test totals, skipped and failed cases, and exit status. Measure wall time from command startup through process exit separately from Vitest's internal duration and summed test time. Concurrent project durations are not additive wall time.

For each candidate, run a baseline and candidate with one intentional difference, then repeat at least three times per condition in alternating order. Compare equivalent warm-cache samples; measure a separate cold-cache series when startup or transform caching is the proposed saving. Do not destroy shared caches or stop another contributor's processes to arrange measurements. Coordinate non-overlapping runs instead.

The initial comparison includes a small passing visual file and the complete suite, using native Vitest flags through `bun run test` and `--update none` to preserve references. Extend with a deterministic failure probe when diagnostic or failure behavior changes. A candidate is not successful merely because it times out sooner, skips work, or turns a previous failure into a pass. Existing failures must be characterized and resolved by their owning outcome before claiming successful-suite performance.

Report medians and ranges with sample counts, absolute seconds saved, and relative improvement. Accept a candidate only when the improvement is repeatable beyond the observed run-to-run spread, coverage and results remain equivalent, and no new instability appears. If measurements are inconclusive, retain the current setting. Do not sum savings from separate experiments without measuring their combination.

### 2. Keep an explicit strategy and gain ledger

The order below prioritizes low-cost investigation and then larger structural opportunities. It is an evaluation order, not a commitment to ship every candidate.

| Candidate | Purpose and potential gain | Environment impact | Adoption evidence and main limitation |
| --- | --- | --- | --- |
| Coordinate independent runners | Avoid several complete browser matrices competing for the same CPUs and memory. Gain is unmeasured; earlier contended runs cannot quantify it. | No environment change; coordinate existing invocations. | Record competing workloads. Six visual projects already run concurrently. Do not introduce a global lock or terminate unrelated work. |
| Disable routine tracing | Reduce recording, serialization, and trace-file work. One focused pair observed 18.02 to 16.80 seconds: 1.22 seconds, about 6.8%. | Config-only candidate. Native tracing remains available for diagnosis. | Repeat with identical references and outcomes. Screenshot comparisons and actual/diff artifacts remain. Full-run 22-minute versus 3-minute observations do not prove a tracing multiplier. |
| Fix pending screenshot timeout cleanup | Remove the observed trailing `close timed out after 10000ms`. If the full delay disappears, 16.96 seconds could become 6.96 seconds on the small passing file, about 59% or 2.44x; 183.80 seconds could become 173.80 seconds on the observed full run, about 5.4%. These are conditional subtractions, not measured outcomes. | Prefer a narrowly verified upstream fix or compatible locked dependency update. A maintained patch requires a separate support decision. | The installed screenshot timeout race is a concrete candidate, not an exclusive proven root cause. Verify pending handles and successful process exit, retain the 15-second screenshot budget and useful failure timeout semantics. Never edit installed `node_modules`. |
| Disable visual file isolation | Reuse the browser environment instead of reinitializing modules and the Storybook harness between files. Potential magnitude is unmeasured. | Config-only change to execution semantics. | Compare all cases in normal and altered file orders, including repeated runs. Verify cleanup of DOM, globals, mocks, subscriptions, timers, transport fixtures, theme, viewport, focus, and storage. Reject state leakage. |
| Consolidate six visual projects into one project with six browser instances | Potentially share Vite startup and transforms while retaining six executions per story. Potential magnitude is unmeasured; six instances do not imply a sixfold speedup. | Modest configuration and setup restructuring. | Prove theme and viewport initialization before render/play, unique report identities, unchanged baseline and diff paths, cache correctness, and matrix parity. Current Storybook `initialGlobals` is project-wide. An internal injection key is not an accepted public configuration contract. |
| Tune native concurrency | Find a better number of simultaneous browser/file tasks on the same machine. More workers can reduce time or increase contention, instability, and memory. No optimal count or saving is established. | Native settings only. | Compare a small controlled range against defaults and record resources and failures. `fileParallelism: false` is per project; a low `maxWorkers` value does not establish a global cap across projects. Avoid oversubscription from separately invoked suites. |
| Wait for fonts actually needed by rendering | Avoid eagerly loading unused font faces in every document while preserving stable self-hosted rendering. Gain is unmeasured; cached faces may make it small. | Small Storybook setup change. | Preserve production font imports and supported languages, mathematical glyphs such as U+2264, and exact reference pixels across all six cells. `document.fonts.ready` is a candidate readiness mechanism, not accepted proof that every required glyph is ready. |
| Reduce repeated story or accessibility work where equivalent | Investigate whether setup or invariant work is duplicated across matrix cells. No safe saving is established. | Potential harness or test restructuring. | Play functions can establish the screenshot state; theme-specific contrast and viewport-dependent accessibility differ. Skipping repeated play/a11y by default changes coverage and is rejected. Any finer split must prove assertion and state equivalence and preserve every meaningful check. |
| Native dependency-graph selection | Avoid unrelated test files during development. The dirty audit selected 97 of 116 file/project combinations, retaining 83.6%; omitting 16.4% of combinations is not a measured wall-time reduction. Localized future edits may select far less. | No environment change, but changes which tests run. | Evaluate native selection across unit, browser, and generated stories. Preserve all visual cells for every selected story. A clean checkout and non-imported dependencies need the explicit command and coverage decision described below. |
| Native watch mode | Reuse a persistent process and automatically rerun affected graph dependencies after the initial complete run. Startup amortization and selection gains are unmeasured. | Requires a long-running process and clear process ownership. | This is a workflow alternative, not a one-shot fallback. Avoid multiple watchers and compare edited-module behavior across all projects before claiming savings. |
| Unit worker pool, environment, and filesystem module cache | Investigate unit startup only after the visual bottleneck. The historical isolated unit suite took 12.03 seconds, much less than the observed full suite; optimizing it alone has no demonstrated large full-suite benefit. Gains from pool changes or `experimental.fsModuleCache` are unmeasured. | Pool/cache settings are small changes; jsdom replacement changes the environment and migration scope. | Do not generalize the Node/SSR module cache to browser transform reuse. The previous contended worker samples establish no optimal setting. An experimental option needs repeatability and maintenance justification. |
| Move standalone browser tests into Storybook projects, issue #280 | Could reduce duplicated harness preparation and project overhead. Gain is unmeasured and can reverse if long flows are multiplied into all six visual cells. | Separately owned harness/project migration. | Preserve Chromium/Firefox, keyboard/focus, form payload/pending/error/retry, scrolling, reduced motion, and screenshots. Remove the standalone browser boundary only after parity. This does not migrate jsdom unit tests and is not a prerequisite for the other candidates. |
| Native sharding or project partitioning across extra machines | Reduce elapsed CI time by adding compute. Potential gain is unmeasured and bounded by startup and the slowest partition. | More machines and CI coordination. | Deferred under the current environment constraint. Splitting into extra processes on the same saturated machine does not create extra CPU capacity. |

### 3. Preserve one native command and document the fallback limitation

The default command remains `bun run test`, whose existing script invokes `vitest run`. No new alias or custom wrapper is proposed. Existing project-filter scripts need not be expanded. Native flags used for experiments do not become additional permanent command names.

Vitest supports the following distinct behaviors:

| Native operation | Source of selection | Clean checkout / initial behavior |
| --- | --- | --- |
| `vitest run` | Every configured project and discovered test unless filtered. | Runs the full suite. |
| `vitest run --changed` | Git identifies uncommitted files; Vitest follows their dependency graphs to test files. Staging is not required and selecting lines or functions is not supported. | With no changes, no tests are selected; this is not a full-suite fallback. |
| `vitest run --changed <ref>` | Vitest derives a Git comparison against the supplied reference and follows related imports. | Can select committed branch changes on a clean checkout; a suitable base is an explicit workflow choice. |
| `vitest --watch` | Initial discovery, then observed file changes and the live graph. | Starts with a full run, keeps running, and reruns affected tests on edits. |
| `vitest related <source-files> --run` | Explicit source paths plus automatic graph analysis. | Requires source-file input; recorded for completeness, not chosen as the user's normal workflow. |

There is no verified native Vitest 4.1.7 one-shot option for "run affected tests, otherwise run everything". `passWithNoTests` affects exit behavior, not fallback selection. Combining two shell commands, a Git-reading configuration function, a custom plugin, or separate developer/release aliases would be a policy/orchestration change and is not silently substituted for the user's native-only requirement.

The desired fallback has two cases: no changed source files, and changed files that produce an empty related-test set. Neither case should be confused with a full verification. The statically discoverable module graph includes analyzable dynamic imports, but runtime-computed imports and external effects are not guaranteed. Shared source imports can correctly select nearly every test. Shared CSS, URL-loaded assets, Storybook-generated tests, setup, dependency manifests, build configuration, and backend contracts require explicit validation of graph coverage. The audit also found a `forceRerunTriggers` matching caveat for absolute paths under `.worktrees`; configuration-change coverage cannot be assumed to work there.

Before adopting a default reduced policy, verify the pinned native behavior and selection against representative component, common module, CSS, font/asset, story/setup, manifest/config, backend-contract, new-file, clean-tree, and empty-selection cases. If the desired single-command fallback remains unavailable under the accepted constraints, record the candidate as deferred and retain the current full command. Native watch remains an optional alternative requiring a later workflow decision; its existence does not satisfy the one-shot request.

### 4. Full release validation is a separate correctness gate

Any future release validation must execute the complete unit, both-browser, and six-cell visual suite without a changed/related filter, including on a clean checkout. Image publication must depend on its successful completion. Reusing the same existing package command without selection satisfies the current command contract; an eventual reduced default must explicitly resolve how full release execution is preserved using supported native configuration.

The strategy records this missing gate without implementing it. Before adopting it, establish the existing locked toolchain and Linux/browser/font dependencies in the release environment, resolve baseline validity, and decide the minimal required setup and cache steps. Do not claim that the current release workflow tests the image or application merely because it builds successfully.

### 5. Amend authoritative contracts only for selected candidates

The current [storybook-visual-regression specification](../../specs/storybook-visual-regression/spec.md) requires retained failure traces, loading every declared font, six native project identities, sequential files within each project, separate project caches, and an unfiltered complete frontend command. The [project-command-interface specification](../../specs/project-command-interface/spec.md) preserves native dispatch and composed validation behavior. These constraints are intentional existing behavior.

This change adds an evaluation contract, not speculative replacements for those requirements. Before implementing an accepted candidate, update the owning issue and this proposal, design, tasks, and the complete affected requirement blocks as delta specifications. Record which contracts change and why coverage is preserved. Do not weaken the existing authoritative specifications simply to make an experiment appear compliant.

## Risks / Trade-offs

- [Historical failures and competing work distort timings] - Use the historical table only for prioritization. Establish a successful controlled baseline before promising an overall speedup.
- [Removing traces reduces post-failure evidence] - Preserve ordinary errors and screenshot differences; validate the existing native trace flag as an explicit diagnostic escape hatch before changing its default.
- [Timeout cleanup is an incomplete diagnosis] - Compare hanging-process diagnostics before and after the smallest supported fix. Preserve timeout behavior for a real stalled screenshot.
- [Shared browser state changes test semantics] - Exercise different file orders and repeated runs. Reject candidates requiring broad state-reset infrastructure just to recover the prior guarantees.
- [Project consolidation couples D20 to Storybook internals] - Prefer supported per-instance configuration; record a dependency on upstream support if only private keys can express theme/viewport initialization.
- [Graph selection can miss non-imported effects] - Prove the affected areas and full-run triggers on the actual `.worktrees` path. Preserve full completion and release validation; defer unsupported fallback rather than label no work as successful full verification.
- [Parallelism adds instability] - Judge median wall time together with memory, failures, screenshot stability, and the slowest project. Preserve sequential interactions.
- [A faster benchmark hides less coverage] - Compare selected case identities, project cells, skip counts, reference hashes, and assertions as well as time. Do not accept regenerated references as a performance fix.
- [Current screenshots can omit content below the viewport] - [Issue #281](https://github.com/ravecat/d20/issues/281) owns the capture-contract correction. A matching existing reference is not proof of full-document coverage; no candidate may accelerate comparison by clipping content. Re-establish timings and references under that outcome when its capture contract changes.
- [Many small optimizations create maintenance cost] - Retain only reproducible useful gains, combine candidates incrementally, and reject inconclusive or fragile changes.

## Migration Plan

1. Complete this documentation-only proposal and strict OpenSpec validation. Retain the active change with all future experiment tasks unchecked; no migration or application validation is performed for this planning delivery.
2. After a separate experiment/implementation request, pin the current source and reference baseline, account for the favorites and #280 outcomes, and characterize any failures under their existing ownership.
3. Evaluate coordination, trace recording, and shutdown handles, then isolate the larger initialization, project-consolidation, concurrency, and font hypotheses. Record lower-priority or coverage-reducing candidates as rejected or deferred when their prerequisites are unmet.
4. Reconcile selected candidates with affected authoritative contracts before making lasting implementation changes. Preserve the same source/reference baseline while measuring each candidate.
5. Validate the accepted combination with the full native suite and the relevant existing `mix assets.lint`, `mix typecheck`, Storybook build, and `just check` gates according to touched scope. Release-gate changes also require validation that failure blocks publication.
6. Revert an unsuccessful candidate's configuration or supported dependency change and rerun its focused validation. No reference regeneration, database rollback, or unrelated worktree rollback is needed for performance configuration alone.
7. Archive only after every adopted experiment, implementation, validation, release, or deliberately deferred task is accurately reconciled. Synchronize accepted deltas and run `openspec validate --all --strict --no-interactive`; specification preparation alone does not complete those future tasks.

## Open Questions

These are future experiment gates, not missing requirements for this strategy document:

- Which supported Vitest version or maintained fix eliminates the observed screenshot timeout handles without a broader toolchain migration?
- Does disabling visual isolation remain independent under changed file order and repeated execution?
- Can supported Storybook/Vitest APIs express per-instance theme/viewport globals while preserving all existing artifact paths?
- How much time is actually spent on transforms, story lifecycle, font readiness, tracing, and shutdown on a successful uncontended suite?
- What native concurrency level minimizes wall time on the current machine without additional failures?
- Does the user later choose persistent watch or revise the native-only constraint if one-shot affected-or-full fallback remains unavailable? Until then, preserve the current full command.
- Which changes from the independently owned browser migration #280, if any, are present when experiments begin?
- What minimal release setup reproduces the accepted Linux Chromium references and runs the full suite before publication?

No candidate has been adopted, and no implementation has started.
