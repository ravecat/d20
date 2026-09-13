# Experiment 1: screenshot shutdown cleanup

Tracking: [D20 #282](https://github.com/ravecat/d20/issues/282). Status: rejected during user review because the implementation changes internal dependency code. No gain is adopted. The measurements below are retained as diagnostic evidence, not an acceptable implementation recommendation.

## Scope and baseline

- Source: committed `592f1403`, branch `worktree/vitest-performance-strategy`, unchanged application and screenshot sources.
- Candidate: cancel the unused `@vitest/browser@4.1.7` screenshot stability timer after capture settles. Preserve the 15000 ms screenshot budget, default tracing, test selection, references, and timeout/failure semantics.
- Research scope: the user explicitly requested fast, limited iterations after the initial full baseline. All remaining timed comparisons use only PlayerCountLabel in visual-light-mobile (four tests), plus tiny regression probes. No candidate full-suite run is authorized for this step; broad validation is deferred to the eventual selected combination.
- Setup: native `mix deps.get` and `bun install --frozen-lockfile` in this isolated worktree. No PostgreSQL or Phoenix startup, shared mutable dependencies, or reference updates.
- Environment: Linux x86_64, approximately 32 GiB RAM, eight logical CPUs, Node 24.14.1, Bun 1.3.13, Vitest 4.1.7, Playwright 1.59.1, Chromium headless shell 147.0.7727.15 (cached revision 1217). Existing browser binaries reused; initial worktree Vite caches were cold.
- Independent outcomes #280 (browser migration) and #281 (below-viewport capture) remain open and are not incorporated. Current accepted reference hashes are held fixed; matching them does not resolve #281.

## Initial diagnosis

Run from `assets/`:

```sh
bun run test --project visual-light-mobile stories/shared/player_count_label.stories.ts --update none --reporter default --reporter hanging-process
```

| Run                                | Outcome            | Vitest duration | Startup-to-exit | CPU user/system |    Max RSS |
| ---------------------------------- | ------------------ | --------------: | --------------: | --------------: | ---------: |
| Initial cold-cache diagnostic      | 4/4 passed, exit 0 |          7.00 s |         20.05 s |    10.96/1.18 s | 819440 KiB |
| Warm repeat, default reporter only | 4/4 passed, exit 0 |          3.89 s |         16.56 s |     7.36/1.01 s | 661964 KiB |

Both runs report `close timed out after 10000ms`. The diagnostic identifies four timeout handles created by `asyncTimeout` in the installed browser matcher and retained after `waitForStableScreenshot` completes. These are initial observations, not an alternating before/after result. No competing test runners were observed.

## Candidate provenance and maintenance

- The [Vitest 4.1.7 matcher](https://github.com/vitest-dev/vitest/blob/v4.1.7/packages/browser/src/node/commands/screenshotMatcher/index.ts) races capture against the [uncancelled timeout helper](https://github.com/vitest-dev/vitest/blob/v4.1.7/packages/browser/src/node/commands/screenshotMatcher/utils.ts). When capture settles first, its losing timer remains active.
- The [4.1.11 matcher](https://github.com/vitest-dev/vitest/blob/v4.1.11/packages/browser/src/node/commands/screenshotMatcher/index.ts) retains the same race; no compatible released fix for this specific defect was identified. A patch-version upgrade is therefore not the selected experiment.
- The candidate retains a timer handle in `waitForStableScreenshot` and clears it in `finally`; the timeout callback still aborts capture and resolves to `null`. The zero-timeout bypass remains, and the now-unused helper is removed. This follows [Node timer cancellation semantics](https://nodejs.org/api/timers.html#class-timeout).
- [Bun managed patches](https://bun.sh/docs/pm/cli/patch) apply the version-locked artifact during dependency installation. The patch is authored outside installed dependencies and recorded through `patchedDependencies`, avoiding direct edits to linked/cache-backed package files.
- Rejection reason: the user requires documented settings, native CLI flags, and public tool APIs. A package manager's documented patch distribution mechanism does not make a change to Vitest internals admissible. The patch is removed; this direction remains deferred until an eligible upstream fix or public API exists.

## Measured focused comparison

All six samples use the same native command from `assets/`, with default tracing and the existing four stories:

```sh
bun run test --project visual-light-mobile stories/shared/player_count_label.stories.ts --update none
```

Each command is measured from startup through process exit with `/usr/bin/time -v`. Order is A1, B1, A2, B2, A3, B3; A is the original dependency and B the managed patch. Dependency installation and warmups are separate from timed samples. Cache invalidation following metadata changes is warmed before each subsequent sample. Runtime file hashes verify which package is installed before measurement. No other test runners overlap; normal desktop and IDE activity remains. Language-server indexing after reinstalls is a source of variability, not a proven explanation for every timing difference. The slower B1 sample is retained.

| Pair                 |  A wall |  B wall |     Wall saving | A Vitest duration | B Vitest duration |
| -------------------- | ------: | ------: | --------------: | ----------------: | ----------------: |
| 1                    | 16.12 s | 13.95 s |          2.17 s |            3.69 s |            7.40 s |
| 2                    | 16.62 s |  8.33 s |          8.29 s |            4.10 s |            5.27 s |
| 3                    | 16.75 s |  8.77 s |          7.98 s |            4.32 s |            5.48 s |
| Median per condition | 16.62 s |  8.77 s | 7.85 s (47.23%) |            4.10 s |            5.48 s |

- Every sample passes 4/4 tests with exit 0: 24 successful measured story executions, with no skips.
- The original reports `close timed out after 10000ms` in all 3 samples; the candidate reports it in 0/3.
- Wall-time ranges: A 16.12-16.75 s; B 8.33-13.95 s. This small sample establishes a repeatable focused startup-to-exit improvement on this machine, not a universal percentage or faster test bodies. Internal durations and CPU time are higher in B samples; the removed shutdown delay dominates the observed wall saving.
- CPU user/system seconds by pair: A1 7.43/1.07, B1 16.18/2.04; A2 8.09/1.17, B2 10.36/1.46; A3 8.32/1.28, B3 10.77/1.54. Maximum RSS ranges: A 658260-689020 KiB; B 688896-774212 KiB.
- Excluded from this comparison: initial cold diagnostic/reporting run, warmups, an invocation from the wrong working directory that never started tests, and one invalid A2 warmup whose runtime hash was still the candidate. The hash guard caught the unsuccessful rollback before any valid A2 sample was taken.

## Earlier full-baseline observation

Before the user restricted research scope, `bun run test --update none` ran once: 683.24 s wall, 679.69 s Vitest duration, exit 1, 98/100 file/project combinations passed. Of 483 test instances, 478 passed, 3 failed, and 2 were skipped. Inventory: 12 unit files, five browser files in two browsers, and 13 story files in six visual projects. All visual cases passed. Failures existed before the patch:

- Chromium Home reduced-motion keyboard traversal exceeded the 15000 ms test timeout.
- Firefox Home keyboard traversal exceeded the 15000 ms test timeout.
- Chromium Home reduced-motion screenshot differed from its reference (104835 pixels, reported ratio 0.13).

This mixed cold/warm, failing run is not a successful full-suite benchmark. It had no 10-second close warning; work later in the run allowed screenshot timers to expire before shutdown. No candidate full run was performed after the scope correction. There is no measured full-suite speedup and no claim of complete delivery validation.

## Regression validation

- A temporary diagnostic harness executes the exact installed `waitForStableScreenshot` and `getStableScreenshot` functions with controlled capture inputs and timer observation. The same no-live-timer assertion fails on the original dependency and passes on the candidate. This is an internal-function diagnostic seam, not a new permanent application test runner.
- Six candidate checks pass: fast success clears its timer; early capture rejection retains the original error and clears its timer; pending capture reaches its deadline and aborts; a capture that will reject later first returns the timeout result at its deadline; its later rejection produces no unhandled rejection; timeout zero creates no timer. Positive deadline timers remain referenced while pending.
- A temporary native Chromium probe passes two tests against the real screenshot matcher: intentional image mismatch remains a mismatch, and continuously changing pixels still produce the specified stability-timeout error. Its 150 ms diagnostic deadline does not change the application's 15000 ms budget. It reads an existing reference, writes only temporary attachments, and was removed afterward.
- `bun install --force --frozen-lockfile` successfully reapplies the candidate, verified by installed source hash.
- `bun x --no-install oxfmt --check package.json` and scoped `git diff --check` pass. Broader application checks are deferred with final validation, following the limited research scope.
- `openspec validate --all --strict --no-interactive` passes all 86 items after scope and evidence reconciliation.
- All 441 originally tracked asset/source/reference files outside the intentionally changed package and lock manifests retain their hashes. All dependency versions are unchanged; no reference is regenerated.

## Integrity and rollback

SHA-256 values:

| Artifact                             | Hash                                                               |
| ------------------------------------ | ------------------------------------------------------------------ |
| Original package.json                | `902dcdf6f555751f697c1c792febe554d8b5c108127e6cae2f71ef9d5c3ed073` |
| Original bun.lock                    | `5fe18b9b7fc25576c438abfc36fd5e75b4671e55e8be455042b3e63398b61f19` |
| Candidate package.json               | `90703d46a0b9d3166ffa20e119d9b78020e5d0e2d6aefa6f0d381637e661efc3` |
| Candidate bun.lock                   | `9d0f8ada19091bf322a3b9f37d2f69f76c9b8ea317d3fb07607ab350a76f3017` |
| Managed patch                        | `e78de05f8bcf0f773a548400123ce1a6aaa400c5acb1bcced8dfec50cd928551` |
| Original installed browser bundle    | `f4bb6b88d8eec984d39f2ca2188a7c3cef0c9af78f8bd8d4d42ed2f7152713e3` |
| Candidate installed browser bundle   | `9cd553161b466dab894acfbcc49186cde27615b265ebbfbea211b3732184db0a` |
| Original 441-file integrity manifest | `43e0773d9b1c9c31bafbc9045442ee94563f448bd16e5267da32ac0434726c9f` |
| Raw timing results JSON              | `9695c98fb293e2471715cfb55e2cc9866fc90a96706b8fb52868de329c99745b` |

Rollback restores the original package and lock manifests, removes this candidate's patch artifact, and runs `bun install --force --frozen-lockfile` from `assets/`. A plain frozen install did not reliably remove the already installed patched runtime during this experiment; forced installation plus runtime-hash verification did. Repeated original-state samples verified restoration of both the source hash and the original close-timeout symptom.

Raw logs, timing files, temporary probe sources, and machine-readable results remain under `/tmp/d20-vitest-shutdown-20260913-baseline-agent/` as supporting local material. This document is the durable result record and does not depend on that temporary directory remaining available.

## Review decision

The user rejected dependency patching and clarified the public-interface-only constraint. The patch and its manifest/lock registrations were removed. `bun install --force --frozen-lockfile --cwd assets` restored the original installed dependency in 2.06 seconds; the verified browser bundle hash is `f4bb6b88d8eec984d39f2ca2188a7c3cef0c9af78f8bd8d4d42ed2f7152713e3`.

One focused rollback verification ran the original four tests: 4/4 passed, exit 0, wall time 17.48 seconds, Vitest duration 4.88 seconds, with the original `close timed out after 10000ms` symptom. All 441 source/reference hashes remain unchanged, and `git diff -- assets` is empty. Supporting rollback evidence is `/tmp/d20-vitest-shutdown-20260913-baseline-agent/rollback.json`.

No implementation commit was created. The measured 47.23% reduction is not adopted and must not serve as the baseline for later experiments. The overall change stays active; subsequent experiments begin from the restored original dependency and use documented settings, CLI flags, or public APIs.
