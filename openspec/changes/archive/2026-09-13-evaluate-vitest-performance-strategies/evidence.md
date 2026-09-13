# Historical Vitest benchmark evidence

Tracking: [D20 #282](https://github.com/ravecat/d20/issues/282). Strategy and interpretation: [design](design.md). This evidence supports candidate selection; it does not establish a successful full-suite performance baseline.

## Provenance and limits

- Audit date: 2026-09-13.
- Source checkout: `/home/max/apps/d20/.worktrees/game-favorites`, based on `577c5c34ed1fa5dbb873f90c99b3e747d2cfb0ee`, with uncommitted favorites implementation, tests, and screenshot work.
- Environment: Linux, 8 logical CPUs, approximately 32 GiB RAM, Node 24.14.1, Bun 1.3.13, Vitest 4.1.7. Existing caches and background application state were retained.
- This specification is authored in the separate `vitest-performance-strategy` worktree at the same committed base. The dirty benchmark source was not copied into it. The base commit alone cannot reproduce the measured test inventory or failures.
- Durations are individual observations, not medians. Wall time includes command startup and process exit, measured with `/usr/bin/time`. Vitest's own duration excludes some of that overhead.
- The complete matrix had failures, different concurrent workloads, and changing reference availability. No clean, passing, repeated full-suite benchmark was established.
- Fresh experiments must pin a new complete source revision, lockfile, browser versions, screenshot inventory, machine load, and cache conditions. These historical counts must not become acceptance targets for a different checkout.

## Completed run observations

Native commands below were run from `assets/`. Historical filtered commands are diagnostic evidence, not a proposed routine workflow requiring manual test lists.

| Run | Invocation | Wall seconds | Total / passed / failed / skipped | Conditions |
| --- | --- | ---: | --- | --- |
| H1 | Existing `bun run test` | 1346.39 | 585 / 357 / 226 / 2 | Default tracing; externally owned full runner; brief unit probes overlapped; missing screenshot references were created |
| H2 | `bun run test:unit` | 12.03 | 81 / 81 / 0 / 0 | Separate run after H1 exited |
| H3 | `bun run test:browser` | 35.76 | 126 / 116 / 8 / 2 | Chromium and Firefox; all eight failures were screenshot comparison errors |
| H4 | `bun run test:visual --browser.trace off` | 354.81 | 378 / 184 / 194 / 0 | Six visual projects; multiple externally owned visual runs overlapped |
| H5 | Existing `bun run test --browser.trace off` | 183.80 | 585 / 380 / 203 / 2 | Externally owned runner; an owned duplicate overlapped for 36.22 seconds before cancellation |
| H6 | GameCard, visual-light-mobile, trace off | 16.80 | 12 / 10 / 2 / 0 | Only one Vitest runner observed; same source/reference hashes and failures as H7 |
| H7 | GameCard, visual-light-mobile, default trace | 18.02 | 12 / 10 / 2 / 0 | Only one Vitest runner observed; same source/reference hashes and failures as H6 |
| H8 | PlayerCountLabel, visual-light-mobile, trace off, hanging-process reporter | 16.96 | 4 / 4 / 0 / 0 | Successful diagnostic with a trailing 10-second close timeout |

The separate H2-H4 runs used `CI=true` to prevent writing new screenshot references. The H6-H8 focused runs used `--update none` explicitly. Interrupted runs are excluded: the owned duplicate exited 143 after 36.22 seconds; the earlier external `full.log` exited 143 after 1648.72 seconds.

H1 versus H5 is an approximately 7.3x observed difference, not evidence that disabling tracing accelerates the suite 7.3x. Failure counts, reference creation, concurrent load, and cache conditions differ. H4 is also contended and cannot be compared to H5 to infer project scheduling speed.

## Matrix inventory

The dirty checkout had 12 unit files containing 81 tests, 7 browser files run in both Chromium and Firefox containing 126 test instances, and 15 story files run in six visual projects containing 378 test instances. Total: 116 file/project combinations and 585 test instances, including 2 skipped browser instances.

Each visual project ran 63 cases. These are sums of file durations inside H4, not independently measured project wall times. Parallel project durations must not be added to estimate elapsed time.

| Visual project | Cases | Failed | Sum of file durations, seconds |
| --- | ---: | ---: | ---: |
| visual-light-desktop | 63 | 33 | 254.958 |
| visual-light-tablet | 63 | 32 | 257.713 |
| visual-light-mobile | 63 | 32 | 244.813 |
| visual-dark-desktop | 63 | 31 | 257.929 |
| visual-dark-tablet | 63 | 30 | 249.159 |
| visual-dark-mobile | 63 | 36 | 250.487 |

## Controlled tracing comparison

H6 and H7 used the same story file, project, and references:

```sh
bun run test --project visual-light-mobile stories/widgets/game-card.stories.ts --browser.trace off --update none
bun run test --project visual-light-mobile stories/widgets/game-card.stories.ts --update none
```

| Metric | Trace off | Default retain-on-failure |
| --- | ---: | ---: |
| Wall time | 16.80 s | 18.02 s |
| Vitest duration | 4.40 s | 5.67 s |
| Test bodies | 2.41 s | 3.68 s |
| Outcome | 10 passed, 2 failed | 10 passed, 2 failed |

The observed wall saving is 1.22 seconds, or 6.8%, from one sample per setting. Both runs still incurred a 10-second shutdown timeout. Installed Playwright/Vitest code records screenshots, DOM snapshots, and sources, exports traces, and then removes successful traces under `retain-on-failure`. Disabling this diagnostic recording leaves screenshot assertions enabled, but conflicts with the current requirement to retain failure traces. A broader, repeated controlled benchmark and an explicit specification decision are needed before changing the default.

## Shutdown diagnosis and conditional gain

H8 ran:

```sh
bun run test --project visual-light-mobile stories/shared/player_count_label.stories.ts --browser.trace off --update none --reporter default --reporter hanging-process
```

All four tests passed. Test bodies took 815 ms, Vitest reported 4.32 seconds, total wall time was 16.96 seconds, and the process exited 0. The log still included:

```text
close timed out after 10000ms
```

The hanging-process diagnostic reported 241 handles, including pending `Timeout` handles pointing to installed `@vitest/browser/dist/index.js:2191` and `:2420`, plus file and PNG decoder handles. Installed `asyncTimeout()` starts a normal `setTimeout()`; `waitForStableScreenshot()` races it against capture completion without cancelling or unref-ing the timeout when capture wins. The repository's screenshot stability timeout is 15000 ms.

This is a concrete root-cause candidate, not proof that this timer accounts for every remaining handle or every second of shutdown. The 10 seconds are a runner close timeout after the run, not an intentional sleep after each test. A verified upstream update or a managed dependency patch could remove a lingering timer. Editing `node_modules`, reducing screenshot stability time, or shortening teardown merely to hide the message is not the proposed remedy.

If a fix eliminates exactly 10 seconds of trailing wall time:

- H8 would change from 16.96 to 6.96 seconds: approximately 59.0% less time, or 2.44x faster.
- H5 would change from 183.80 to 173.80 seconds: approximately 5.4% less time.

These are conditional arithmetic scenarios, not measured post-fix results. The saving is once per affected process invocation, not multiplied by 585 tests. Independent candidate gains cannot simply be added.

## Selection and worker observations

`bun run vitest list --filesOnly --changed` selected 97 of 116 file/project combinations: 13 story files in all six variants, 5 unit files, and all 14 browser combinations. That omits 16.4% of combinations but does not establish a 16.4% time saving; selected file costs differ and discovery/startup still run.

In the audited Vitest 4.1.7 implementation, `--changed` uses Git changes, not the preceding successful test execution. Without a reference it considers staged, unstaged, and new nonignored files. The statically discoverable module graph, including analyzable dynamic imports and transitive dependencies, selects whole test files. A clean checkout selects no tests and normally exits successfully. Repeating the command with unchanged uncommitted edits repeats the selection. `--changed HEAD~1` or a branch reference can include committed changes since the comparison merge base as well as local changes.

No native one-shot affected-or-full fallback was found in the audited version. `passWithNoTests` controls empty-selection exit behavior; it does not request the full suite. Native watch performs an initial run and later graph-based reruns, with a persistent process lifecycle. Runtime-computed dependencies, public assets, shared configuration, and backend contracts need conservative treatment before reduced selection can replace routine full execution.

A minimal matcher check found that default `forceRerunTriggers` use picomatch without `dot: true` against absolute paths, causing the package trigger to miss paths inside `.worktrees`. The installed config trigger's trailing `/**` also failed against this repository's `vite.config.mjs`. Ordinary import selection still worked; the global-change safety net cannot be assumed reliable here. This was not patched during the audit.

Under concurrent full-suite load, unit defaults took 17.92 seconds, `--maxWorkers 2` took 22.50 seconds, and a focused 19-test file took 9.59 seconds. These contended single samples do not identify an optimal pool or worker count. Browser and visual projects already run concurrently; `fileParallelism: false` serializes files within each project, and `--maxWorkers 1` does not serialize all projects globally.

## Evidence retention and source anchors

The tables and diagnosis above are the durable evidence record. The original audit artifacts remain in `/tmp/d20-vitest-benchmark-20260913/` as local supporting material; that temporary location is not required to understand this proposal and is not a permanent artifact store. Raw logs, local harnesses, and process inventories are not new repository commands or committed application artifacts.

Audit preservation checks found zero content changes to files present at the start. The externally owned H1 run created missing screenshot references; a midpoint inventory found 18 new paths. Those references were preserved. They were not blindly accepted or copied into this planning worktree.

Repository anchors at the planning base:

- `assets/package.json`: `test` is `vitest run`; existing project scripts forward native options.
- `assets/vite.config.mjs`: jsdom units, Chromium/Firefox browser instances, six visual projects, separate caches, retained failure traces, and sequential files within browser/visual projects.
- `assets/.storybook/vitest.setup.ts`: all declared font faces are loaded, then a screenshot assertion runs with a 15000 ms stability timeout.
- `.github/workflows/release.yml`: master pushes build and publish an image; the workflow has no test step. Full release testing is a future gate, not established current behavior.
- `openspec/specs/storybook-visual-regression/spec.md` and `openspec/specs/project-command-interface/spec.md`: existing coverage and command contracts remain authoritative until a later approved delta.

Reference documentation consulted with installed code during the audit:

- [Vitest 4 CLI](https://v4.vitest.dev/guide/cli): run, changed, related, and watch selection.
- [Vitest 4 performance guide](https://v4.vitest.dev/guide/improving-performance): isolation, pools, and performance tradeoffs.
- [Vitest 4 browser trace](https://v4.vitest.dev/config/browser/trace): diagnostic recording modes.
- [Vitest 4 browser instances](https://v4.vitest.dev/config/browser/instances): instance configuration and sharing.
- [Storybook Vitest integration](https://storybook.js.org/docs/writing-tests/integrations/vitest-addon): story testing and setup integration.
- [Vitest issue #11054](https://github.com/vitest-dev/vitest/issues/11054): force-rerun matching caveat. Its future resolution must be verified against any proposed dependency version.

### Local artifact integrity references

These hashes identify the local files underlying this record; they do not make the uncommitted source checkout reproducible or imply that logs are published.

| Local artifact | SHA-256 |
| --- | --- |
| `report.md` | `f65e454707e91b362cd6e55c12c419c3ab546e866d27e6f1c384ca2248b69fd1` |
| `summary.json` | `be101eb920866be9719706b10fd6241f714663a65a4fc34283223a2e9646a2d0` |
| `observed-full-default.log` | `05beaed2aaab4b3f0a42706632e7dd9e774a8a276c9b4cf618961b1bf8601c75` |
| `observed-full-no-trace.log` | `7a994d2dce7d2b91097875731a9ec83d9318ede73e2a98bf0ea5eeb043ce9a10` |
| `card-single-no-trace.log` | `cc94102e1508b33b1c0083cc005e9e625c49754e844d089e148829b3baa204a3` |
| `card-single-trace.log` | `8923085019f1f07d7b61819df182c0da817dde7f9f88a625f8f51d0f3ac6aebe` |
| `cleanup-diagnostic.log` | `7db0869fafa79aa4929b2e85b6dbe8574f0892fa0bc4f92b536df06c7b8b3934` |
