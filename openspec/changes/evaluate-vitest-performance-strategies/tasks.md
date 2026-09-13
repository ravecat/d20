This is the future evaluation and implementation backlog, not work authorized by the strategy request. All tasks remain unchecked for this planning delivery. Start experiments or implementation only after a separate request. A candidate can be completed as rejected or deferred with evidence; this list does not require implementing every option.

## 1. Establish an equivalent measurement baseline

- [ ] 1.1 After an experiment request, record its scope in issue #282 and these artifacts; pin the current committed source, lockfile, reference hashes, runtime/browser versions, machine, cache conditions, and case/project inventory without importing uncommitted favorites work.
- [ ] 1.2 Review current failures and the ownership of #280 browser migration and #281 screenshot clipping; record their impact on baseline validity without absorbing those outcomes or accepting changed references for speed.
- [ ] 1.3 Coordinate non-overlapping runs and establish a passing small visual probe and complete suite with existing `bun run test` plus native diagnostic/project flags and `--update none`; record at least three baseline samples and distinguish wall time, Vitest duration, test execution, and shutdown.

## 2. Evaluate the lowest-cost execution candidates

- [ ] 2.1 Compare `--browser.trace off` with the current trace mode in alternating paired runs; record median/range, identical results, screenshot failure evidence, and native trace re-enablement before deciding adopted, rejected, or deferred.
- [ ] 2.2 Reproduce the shutdown handles with the native `hanging-process` reporter and identify a narrowly supported timer cleanup fix or compatible dependency update; record its source, scope, and maintenance tradeoff before changing dependencies.
- [ ] 2.3 If a timer fix is suitable and within the later authorized scope, verify successful exit and real stalled-capture timeout behavior without reducing the screenshot or teardown budgets; measure actual short/full-run savings rather than subtracting 10 seconds as a result.

## 3. Select larger opportunities using the measured bottleneck

- [ ] 3.1 Profile repeated initialization, transforms, story lifecycle, fonts, and resource contention; select only justified next experiments and record the remaining candidates as deferred or rejected in the strategy ledger.
- [ ] 3.2 If selected, evaluate visual isolation changes with unchanged references, repeated runs, altered file order, and explicit cleanup/independence verification; reject any leakage or broad compensating harness work.
- [ ] 3.3 If selected, establish a supported six-instance Storybook configuration before benchmarking consolidation; verify initial theme/viewport, all six story executions, existing baseline/diff paths, report identities, and cache correctness without silently using private injection contracts.
- [ ] 3.4 If selected, compare a small native worker/file-concurrency range and font-readiness alternatives separately; preserve sequential interactions, all glyphs and languages, full capture contracts, and exact accepted images while recording memory, failures, and wall time.
- [ ] 3.5 Record decisions for repeated play/a11y work, persistent watch, unit pools/environment/cache, separately owned #280 migration, and extra-machine sharding; reject coverage reduction and keep unsupported or out-of-scope options deferred without implementing them.

## 4. Resolve automatic selection and full delivery semantics

- [ ] 4.1 Verify native `--changed`, reference-based selection, and watch behavior against the pinned version using `bun run vitest list --filesOnly --changed` and representative source/setup/asset/config/backend-change cases; record actual selected unit, browser, and story-project identities and the `.worktrees` full-rerun trigger caveat.
- [ ] 4.2 Verify clean-tree and empty-related-set behavior and record whether a supported one-command affected-or-full fallback exists; if it does not, preserve `bun run test` unchanged and defer reduced default selection without adding aliases, wrappers, or manual impact lists.
- [ ] 4.3 If reduced development selection remains a candidate, specify how the same command surface preserves unfiltered completion/release verification and minimal locked release setup; record the required publication dependency and resolve its implementation scope before adopting that policy.

## 5. Adopt only verified candidates and reconcile delivery

- [ ] 5.1 Before lasting implementation, update issue #282 and every affected proposal, design, task, and authoritative requirement delta for the selected candidates, including trace/font/project/command contracts where applicable; record explicit rejected/deferred outcomes for other candidates.
- [ ] 5.2 Apply only candidates covered by the later implementation request, preserving source and reference ownership; if reduced development selection is adopted, implement and verify the required full release gate before treating the policy as delivered.
- [ ] 5.3 Measure the selected combination against the fixed baseline with the complete native suite; report repeated wall-time savings, outcome/coverage parity, diagnostic behavior, remaining limitations, and rollback verification without adding independent estimates together.
- [ ] 5.4 Run applicable native validation for the actual touched scope: `bun run test`, `mix assets.lint`, `mix typecheck`, `bun run storybook:build`, and `just check` for broad or release changes; release-gate work must also demonstrate that failed validation prevents publication.
- [ ] 5.5 Reconcile all adopted, rejected, and deliberately deferred tasks and linked contracts with the verified result; only when required work is complete synchronize and archive through OpenSpec, run `openspec validate --all --strict --no-interactive`, and confirm the change is absent from `openspec list --json`.
