# Public API acceleration sweep

## Scope and delivery authorization

The user authorized the remaining compatible candidates as one autonomous sweep, superseding the earlier per-candidate review pause. The sweep originally kept code and evidence uncommitted in the existing worktree for review. After the README and inline-configuration corrections, the user authorized two semantic commits and local `master` integration: the trusted fullscreen story prerequisite first, then the environment optimization. No push or publication is requested. This is an equivalent-workload acceleration: no tests, stories, matrix cells, browser coverage, accessibility checks, assertions, timeout budgets, or reference pixels are removed. Only documented settings, CLI flags, and public APIs are eligible.

Experiment 1 remains rejected. Its 47.23% internal-patch saving is excluded from every baseline and aggregate claim below.

## Measurement method

- Source baseline: `592f1403`, original package manifest/lock and unpatched Vitest 4.1.7. Same worktree and machine as [experiment 1](experiment-01-shutdown.md).
- Installed addon-vitest, a11y, docs and svelte-vite: 10.5.7; addon-themes: 10.5.10. No dependency upgrade is part of this sweep.
- Native `bun run test` with focused file/project arguments and `--update none`; warm comparisons alternate three baseline/candidate pairs. Cold startup observations are separate.
- Only one timing/validation test runner is started at a time; the later changed-list and empty-related discovery probes are excluded from timing evidence. Independent repository reads and upstream research may overlap; no unrelated processes are stopped.
- Wall time includes process startup and shutdown. Internal duration, outcomes and maximum process RSS are retained separately. RSS is not total aggregate browser memory.
- Raw local logs, timing files and JSON: `/tmp/d20-vitest-public-api-sweep-20260913/`. The durable record below retains all decision-relevant samples; temporary diagnostic probes are removed after validation.

## Tracing

Four PlayerCountLabel stories in `visual-light-mobile`:

```sh
bun run test --project visual-light-mobile stories/shared/player_count_label.stories.ts --update none
bun run test --project visual-light-mobile stories/shared/player_count_label.stories.ts --update none --browser.trace off
```

| Pair | Retain-on-failure wall | Trace off wall | Outcome in each run |
| ---- | ---------------------: | -------------: | ------------------- |
| 1    |                16.49 s |        15.61 s | 4 passed            |
| 2    |                16.49 s |        14.87 s | 4 passed            |
| 3    |                16.60 s |        14.87 s | 4 passed            |

Median: 16.49 to 14.87 seconds, 1.62 seconds / 9.82% reduction. Ranges: 16.49-16.60 versus 14.87-15.61 seconds. All exits zero, references unchanged. The original close-timeout warning remains in both conditions. Native trace recording is documented in [Vitest 4.1.7](https://github.com/vitest-dev/vitest/blob/v4.1.7/docs/config/browser/trace.md). The diagnostic tradeoff is loss of automatic traces on ordinary failures; actual/diff screenshot evidence remains required, with native trace re-enablement validated before retaining the default.

## Candidate ledger

The following sections retain sequential measurements and corrections; the final combined result and delivery state below state the retained decisions.

## Visual isolation

Three files in visual-light-mobile, 11 stories: PlayerCountLabel, Workspace, and AccountSettings. Keep retain-on-failure tracing constant and compare native browser isolation true/false. The installed browser-specific flag works but is deprecated; the supported nondeprecated alternative would use project `isolate: false`. It is not retained in the final configuration.

Median wall time: 23.33 to 21.46 seconds, 1.87 seconds / 8.02%. Ranges: 22.23-24.23 versus 20.85-21.81 seconds. All six runs passed 11/11, original close-timeout warning retained. The later combined screen below did not reproduce a useful gain, so default isolation is retained.

## Consolidation setup corrections

The first smoke configuration put screenshot and trace options in browser instances. Installed public instance types do not support these fields; screenshot paths were ignored. `--update none` prevented reference writes. The measured shared browser-level screenshot resolvers used the documented callback project name and a configuration-owned map. The later reviewed inline refactor replaces that map with public `project.getProvidedContext()` without changing paths.

The corrected trace-enabled smoke exposed `tracing.stopChunk` stream-size errors with concurrent instances in a shared trace directory. No supported per-instance trace setting exists in the locked public instance type. Matched consolidation comparisons therefore use trace-off in BOTH configurations, following the independent trace result. Invalid smokes are excluded from timing claims. Focused single-instance, single-file native tracing must be verified; concurrent multi-instance tracing is a retained limitation if consolidation is adopted.

## Shared Storybook project

Use one `storybookTest` plugin/Vite server and six native browser instances with unchanged names. Public per-instance `provide`/`inject` values and framework `setProjectAnnotations` establish theme and viewport before render/play. Explicit public previews preserve Svelte docs, docs, a11y, themes and the repository preview; the existing plugin continues to own lifecycle hooks. The measured screenshot resolvers mapped the public project name to the original theme/viewport reference and diff paths; the accepted inline refactor reads those same globals through public `project.getProvidedContext()`.

The matched comparison selects PlayerCountLabel in all six cells, 24 tests, with `--browser.trace off --update none` in both conditions. One shared ignored Vite cache replaces six independently owned project caches.

| Pair | Six projects wall | Shared project wall | Outcome in each run |
| ---- | ----------------: | ------------------: | ------------------- |
| 1    |           22.67 s |             17.26 s | 24 passed           |
| 2    |           23.99 s |             17.39 s | 24 passed           |
| 3    |           23.95 s |             17.29 s | 24 passed           |

Median: 23.95 to 17.29 seconds, 6.66 seconds / 27.81%. Ranges: 22.67-23.99 versus 17.26-17.39 seconds. No reference updates. This is the consolidation gain with tracing already off, not the sum of two independent improvements.

Public sources: [Vitest browser instances](https://v4.vitest.dev/config/browser/instances), [provide/inject](https://github.com/vitest-dev/vitest/blob/v4.1.7/docs/config/provide.md), [Storybook initialGlobals](https://storybook.js.org/docs/writing-tests/integrations/vitest-addon#initialglobals), [public screenshot resolver arguments](https://github.com/vitest-dev/vitest/blob/v4.1.7/packages/browser/src/shared/screenshotMatcher/types.ts).

## Unit execution screening

The current clean source collects 79 unit tests in 12 files (native JSON inventory retained), all passing. The historical dirty-favorites audit's 81 unit tests do not define this checkout's acceptance count; all 441 baseline asset/source hashes were verified before the story-harness correction.

| Screening condition                    | Wall time | Outcome / decision         |
| -------------------------------------- | --------: | -------------------------- |
| Original forks/default workers         |    6.74 s | 79 passed, retain          |
| Threads/default workers                |    7.17 s | 79 passed, slower          |
| Forks/maxWorkers 2                     |    9.59 s | 79 passed, slower          |
| Forks/maxWorkers 4                     |    8.84 s | 79 passed, slower          |
| Experimental fsModuleCache, population |    6.88 s | 79 passed, cold cache      |
| Experimental fsModuleCache, warm       |    7.03 s | 79 passed, no observed win |

These are single screening samples, not causal regression percentages. No candidate demonstrated a reason for more repeated testing or a lasting unit-config change. Unit `isolate:false` is rejected from the safe sweep because existing prototype replacements are not restored across files. jsdom is retained; a separate Node-only project would require test/setup restructuring beyond the measured dominant visual bottleneck.

## Fullscreen activation prerequisite

The first 66-case consolidated interaction check had 60 passes and six Workspace AutoSelection fullscreen failures. A single consolidated instance reproduced the failure. The restored original configuration with trace-off also reproduced it, so consolidation alone is not established as the cause. Trace-on original isolation comparisons passed. The existing story uses synthetic Testing Library events; production catches failed fullscreen requests. A public native-click diagnostic and a narrowly scoped test-harness correction are evaluated before retaining trace-off. The four-case timing samples do not establish interaction parity.

The activation probe established `isTrusted:false` and `navigator.userActivation.isActive:false` for the synthetic click followed by `fullscreenerror`. Native Vitest Browser click produced `isTrusted:true` and active user activation; every fullscreen/play assertion completed. It initially left a hover-only 668-pixel drift at the fullscreen button. Native `unhover` after clicking restored the original reference without changing pixels, CSS, timeouts or comparisons. The clean corrected four-story Workspace probe passed 4/4. Temporary instrumentation was removed. All subsequent configuration A/B comparisons hold the corrected story fixed; only the fullscreen entry uses native input in the documented test mode, while keyboard navigation, fullscreen exit, and every existing assertion remain.

Sources: [Vitest native interactivity](https://v4.vitest.dev/api/browser/interactivity), [Vite public mode](https://vite.dev/guide/env-and-mode), [Vitest default test mode](https://v4.vitest.dev/config/mode), [browser user activation](https://developer.mozilla.org/en-US/docs/Web/Security/Defenses/User_activation). Normal Storybook builds keep their portable interaction path. This does not claim synthetic Storybook playback can bypass fullscreen activation policy.

After the clean trusted-click correction, the original trace-off 11-story probe passed 11/11 and the consolidated three-file six-cell matrix passed 66/66 (13.01 seconds internal duration). Every existing reference remains unchanged. This resolves the observed interaction failure without a dependency patch, production change or removed assertion.

## Font readiness

With consolidated configuration and trace-off fixed, compare the existing eager `Promise.all(font.load())` with public rendered-font readiness plus propagation of attempted-face failures. Three alternating pairs use the same four PlayerCountLabel stories and unchanged references.

Median 14.33 to 14.31 seconds, just 0.02 seconds / 0.14%, with overlapping ranges. All runs pass 4/4. This does not establish a meaningful gain. The candidate is rejected and restored to the original eager all-face load; no font contract change, resource removal or readiness weakening is retained. Additional multilingual/error tests were adoption gates, and were not run for this rejected candidate.

## Other strategy decisions

| Direction from the strategy                          | Sweep decision                                                                                                                                                                                                                   |
| ---------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Coordinate independent runners                       | Applied operationally: one owned test process at a time; no global lock or terminated external process. No standalone percentage claimed.                                                                                        |
| Shutdown timer cleanup / dependency upgrade          | Deferred: no verified eligible released fix for the identified timeout leak. The internal patch stays rejected; timeout/teardown reductions are not used to hide it.                                                             |
| Reduced-detail retained traces                       | Not separately adopted: the selected trace-off direction is measured, with focused trace re-enablement. Multi-instance shared trace output has a reproduced limitation.                                                          |
| Play and accessibility duplication                   | Preserve all play functions and addon checks. Removing checks by matrix cell changes coverage and is rejected.                                                                                                                   |
| Fewer screenshots, themes, viewports or browsers     | Rejected as a coverage reduction. Pixel thresholds, dimensions, references and screenshot budgets stay fixed.                                                                                                                    |
| More aggressive transform/dependency cache tuning    | Keep native Vite caches and measured shared-project preparation; no unsupported browser module cache or speculative optimizer exclusions are added.                                                                              |
| Unit Node-only splitting, setup/barrel refactoring   | Deferred: the measured complete unit scope is 6.74 seconds and broad environment/setup changes have no established gain. Preserve jsdom and current project filters.                                                             |
| Standalone browser-to-Storybook migration            | Remains independently owned by #280; no test migration or multiplied long flows are imported into this sweep.                                                                                                                    |
| Extra-machine sharding                               | Deferred under the same-machine scope; no runners, cloud service or CI orchestration are provisioned.                                                                                                                            |
| Project group ordering                               | Required by the full-run config check: visual group 1 follows unchanged unit/browser group 0 because Vitest rejects different worker caps in one group. No independent speedup claimed.                                          |
| Reduced default dependency selection                 | Deferred: native changed/related selection does not provide the requested affected-or-full fallback. No aliases, wrappers, impact manifests or reduced default are introduced.                                                   |
| Release setup, caches and full test publication gate | No release workflow is changed. The existing unfiltered command remains full; a future reduced development policy still requires its separately specified complete release gate. No deploy speed is claimed from a local timing. |
| Persistent native watch                              | Optional development workflow; measure edit-to-rerun feedback separately from complete one-shot validation. It does not replace release verification or become a background process left running.                                |

The ledger covers the existing specification's direction groups and their major suboptions; a deferred option is not reported as implemented or benchmarked.

## Visual file concurrency

Use the corrected story and shared project, hold trace-off and eager fonts fixed, and select the same 11 stories in visual-light-mobile. Three matched pairs compare sequential files against `--fileParallelism --maxWorkers 2`.

Median 17.00 to 15.94 seconds, 1.06 seconds / 6.24%. Ranges: 16.97-17.03 versus 15.90-16.02 seconds. All 11 tests pass in every measured run. A four-worker screening sample took 16.03 seconds and showed no additional benefit; the lower tested cap is preferred. This is a per-derived-project cap, not a global limit across all six instances. Final full-suite validation must check the combined resource load.

The older isolation result used a different configuration. Its 8.02% is not added to the other gains; isolation is checked again against the retained scheduling configuration before its final decision.

Review found that a mode-based runtime check confuses build mode with the test runner. The retained design uses explicit public visual-project `test.env: { VITEST: "true" }` and `import.meta.env.VITEST === "true"`. This supports custom Vitest modes and keeps normal Storybook out of the Vitest-only branch. Both final comparison configurations include the same environment marker and corrected story. Sources: [documented Vitest environment marker](https://github.com/vitest-dev/vitest/blob/v4.1.7/docs/config/index.md), [public test.env](https://v4.vitest.dev/config/env).

## Combined isolation screen and review checks

On the shared, trace-off, two-worker configuration, a same-scope isolation screen measured 15.86 seconds with isolation and 15.77 without, only 0.09 seconds / 0.57%, both 11/11 passing. This is inconclusive; default isolation is retained. The earlier 8.02% observation is neither adopted nor added to other gains.

The public environment guard passed the four Workspace stories with `--mode staging`. Controlled screenshot drift failed with actual/diff evidence under both ordinary trace-off and focused trace-on, while the reference stayed unchanged. The focused trace archive passed CRC verification and contained 21 entries including `trace.trace`. A temporary nameless-button story in a11y error mode produced the expected `button-name` violation. Both temporary story changes were removed. Invalid earlier concurrent trace archives are excluded from the successful trace claim.

## Final combined measurement

Retained runtime changes: one shared visual project with six named instances and one Vite cache; trace recording off by default; two parallel isolated files per instance; explicit public instance globals and complete addon annotations. The fullscreen story uses trusted click/unhover in the visual runner. Fonts, unit settings, browsers, matrix, assertions, reference pixels, timeout budgets, dependencies and the unfiltered command remain unchanged.

Both compared configurations contain the same corrected story and explicit public runner environment marker. A otherwise uses the original six-project, retained-trace, sequential-file configuration. B uses the retained combination. This comparison measures the combination directly, rather than adding candidate percentages.

```sh
bun run test --project visual-light-mobile stories/shared/player_count_label.stories.ts stories/widgets/workspace.stories.ts stories/pages/authenticated/account_settings.stories.ts --update none
# Subsequent paired runs add --sequence.shuffle.files --sequence.seed 41, then 97.
```

| Pair / file order | Baseline wall | Final wall | Baseline internal | Final internal | Outcome each |
| ----------------- | ------------: | ---------: | ----------------: | -------------: | ------------ |
| 1 / normal        |       23.90 s |    16.04 s |           11.10 s |         4.14 s | 11 passed    |
| 2 / seed 41       |       23.84 s |    15.93 s |           11.42 s |         4.07 s | 11 passed    |
| 3 / seed 97       |       26.17 s |    15.98 s |           13.72 s |         4.17 s | 11 passed    |

**Median end-to-end: 23.90 to 15.98 seconds, 7.92 seconds saved / 33.14% faster.** Baseline range 23.84-26.17, final 15.93-16.04 seconds. Every exit is zero. Maximum process RSS ranges are 758020-831240 KiB versus 701976-762676 KiB; these are not aggregate browser memory totals. The original close-timeout warning persists in all samples, so the rejected timer patch contributes no saving.

Before complete validation, all 322 reference PNGs matched their original hashes; no temporary diagnostic story remained. Package manifest and lock hashes remain `902dcdf6f555751f697c1c792febe554d8b5c108127e6cae2f71ef9d5c3ed073` and `5fe18b9b7fc25576c438abfc36fd5e75b4671e55e8be455042b3e63398b61f19`. Original browser bundle remains `f4bb6b88d8eec984d39f2ca2188a7c3cef0c9af78f8bd8d4d42ed2f7152713e3`. Complete-run outcomes are recorded separately below; a focused improvement is not a measured full-suite multiplier.

## Unfiltered startup correction

The first full command exited in 1.75 seconds before executing tests: Vitest rejects unit/default workers and visual/maxWorkers=2 in the same native sequence group. This invalid no-test attempt is excluded from performance evidence. The visual project now uses documented `sequence.groupOrder: 1`, with original unit/browser settings in group 0. This preserves unit defaults rather than imposing the slower globally capped unit configuration. A focused mixed-pool run and one complete retry validate it. The single-project paired comparison does not measure the new full-run ordering effect.

The filename-filtered mixed validation passed 51 tests in 9 files across unit, Chromium/Firefox browser and all six visual cells, with 8.59 seconds internal duration. It verifies the worker-group correction before the complete retry; it is not a before/after benchmark.

## Complete validation and integrity

The sweep validation before the inline review correction ran unfiltered `bun run test --update none` and passed: **114.49 seconds wall, 108.32 seconds internal, 481 passed and 2 skipped across 100 passing files**. The inventory remains 483 cases: 79 unit, 110 browser including the two existing skips, and 294 visual (49 stories across six cells). The earlier home.browser failures did not recur. This is the earlier sweep full-run result, not a matched full-suite speedup: the historical 683.24-second run was failing, cold and unpaired. The controlled improvement remains the 33.14% scoped comparison above.

Full-run user/system CPU time was 191.08/30.34 seconds, with maximum process RSS 1126656 KiB. All 322 reference PNG hashes, package manifest, lockfile, and original browser dependency bundle were unchanged after full validation. No reference generation, dependency patch, reduced timeout or removed assertion contributes to the result.

## Native selection and persistent watch

`bun run vitest list --filesOnly --changed` on the actual modified worktree exited zero and selected Workspace in all six visual instances plus unit `tests/stories/page_layout.test.ts`. It did not select the full suite despite setup/configuration edits. This is concrete evidence against treating changed selection as complete verification in this checkout, consistent with the recorded `.worktrees` trigger caveat. It is a discovery probe, not a test pass or timing benchmark.

`bun run vitest related ../README.md --run --update none` exited zero with "No test files found". It did not fall back to the complete suite. Clean-tree behavior is documented/source-verified but was not empirically retested by hiding the user's review diff. The exhaustive setup/asset/backend/config/reference selection matrix is deliberately deferred because reduced default selection is not adopted. No supported one-command affected-or-full fallback was verified; `bun run test` remains unfiltered. Release setup and a new publication gate remain future work, not delivered CI behavior.

The existing native script supports optional persistent development feedback:

```sh
bun run vitest --watch --project visual-light-mobile stories/shared/player_count_label.stories.ts --update none
```

Initial four-case completion took 5.123 seconds. Three content-preserving source touches triggered four passing tests each in 1.056, 1.206 and 0.905 seconds, median **1.056 seconds edit-to-result**. These warm reruns amortize process startup and are not one-shot or release timings. They do not prove selection for every possible changed asset. The watcher was stopped with SIGINT (intentional exit 130, 0.114-second shutdown); the source hash and mtime were restored, with no watcher left running.

## Delivery state

The user authorizes two semantic commits and local `master` integration, superseding the earlier review-only hold. The trusted fullscreen story correction and explicit public test environment marker form the first commit; the inline shared visual environment, trace default, scheduling, public annotation setup/type declaration and finalized delivery records form the second. Authoritative specification synchronization, final validation and archival precede the environment completion commit. Integration and issue closure follow validated local delivery; no push or publication is requested. Reverting the environment commit restores the previous environment while leaving the independent trusted-input correction available; reverting both restores the previous environment and story harness. No dependency reinstall, reference rollback or data migration is required.

## Native quality checks

- `mix assets.lint`: passed; final `bun run lint` also passed after the declaration fix.
- `mix typecheck`: passed, including TypeScript and Svelte with zero errors/warnings.
- `bun run format.check`: passed, 105 files.
- `bun run storybook:build`: passed with the ordinary Storybook interaction branch.
- `openspec validate --all --strict --no-interactive`: 86 passed, zero failed.
- `git diff --check`: passed.

The first typecheck exposed a missing declaration for Storybook's public JS export `@storybook/svelte/entry-preview-docs`. A local ambient declaration types its actual `decorators` export through the public `Preview` type. This is type-only, with no suppression, runtime replacement or dependency edit; the successful full-suite runtime hashes remain unchanged. No backend/CI/release behavior is modified, so broad cross-stack `just check` and publication-failure tests were not run. These checks passed for the reviewed candidate. The later commit/integration request authorizes final source validation and lifecycle reconciliation; its verification is recorded separately from the measured sweep.

Review correction: remove the sweep-specific implementation details and tuning recommendations from both README files, keeping their general development guidance concise. Technical decisions, measurements and diagnostic commands remain in this report and design. This documentation-only correction does not alter the validated runtime or require another test run.

Inline configuration review correction: the visual project and six-instance matrix now live directly in `defineConfig.test.projects`, without separate visual helper variables. Both artifact path callbacks read `visualGlobals` through public `project.getProvidedContext()`. Focused `bun run test --project 'visual-*' stories/shared/player_count_label.stories.ts --update none` passed all 24 tests across six files; references were unchanged and the existing close-timeout warning persists. Focused formatting/ESLint, `bun run typecheck` (zero Svelte errors/warnings), strict change validation and `git diff --check` passed. This verifies equivalent behavior after a readability refactor; it is not a new speed measurement.

## Final commit-candidate validation

After review corrections, the trusted fullscreen prerequisite was committed separately as `f3c7015a` (`test(storybook): use trusted input for fullscreen assertions`). Its original six-project configuration, with the explicit public test marker and tracing disabled for the probe, passed the four Workspace stories in 4.71 seconds internal duration. This validates the prerequisite independently of project consolidation.

The final inline combined environment then passed the complete native `bun run test --update none`: **151.783 seconds wall, 143.56 seconds internal, 481 passed and 2 existing skips across all 100 files**. All 483 cases remain present. This is one delivery verification, not a repeated controlled benchmark; it supersedes 114.49 seconds as the latest full-run observation without establishing either a regression percentage or an additional speed gain. The matched 11-case three-pair result remains the acceleration evidence: 23.90 to 15.98 seconds median, 33.14% reduction.

All 322 tracked reference PNGs, two pre-existing ignored PNGs, the package manifest and the lockfile retain their hashes. Formatting of all 105 frontend files, ESLint, TypeScript/Svelte (zero errors and warnings), and the ordinary Storybook build pass. The full run emitted a Node `MaxListenersExceededWarning` for 11 SIGTERM listeners but had no test failures and no close-timeout warning. Earlier focused runs still establish the remaining shutdown-timeout limitation; this full-run outcome does not claim it is fixed.

The accepted deltas are synchronized to authoritative specifications and the change is archived for the environment completion commit. Local `master` integration and its verification remain the next delivery operations; this record does not claim they have already occurred. No push or publication is authorized.
