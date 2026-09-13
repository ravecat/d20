# frontend-test-performance Specification

## Purpose

Define evidence-based frontend test acceleration through supported tool interfaces while preserving coverage, native commands, diagnostic semantics and explicit adoption decisions.

## Requirements

### Requirement: Performance claims use reproducible equivalent workloads

Frontend acceleration evaluation SHALL measure complete command wall time on a named source state and stable reference corpus, distinguish execution time from shutdown time, and classify every gain as measured, conditional, or unmeasured.

#### Scenario: Compare an optimization with the current configuration

- **WHEN** a candidate is evaluated after a separate request authorizes experiments
- **THEN** baseline and candidate use the same source and reference state, selected tests, hardware, OS, and locked runtime/browser versions except for the explicitly tested dependency change
- **AND** the record includes native commands, hashes, cache conditions, competing workloads, selected case/project identities, pass/fail/skip counts, exit status, and startup-to-exit duration
- **AND** at least three alternating samples per condition report their median and range
- **AND** warm and cold cache observations are identified separately when relevant
- **AND** a candidate with inconclusive timing or changed outcomes is not reported as an established speedup

#### Scenario: Reuse the historical failing-run audit

- **WHEN** the 2026-09-13 audit informs prioritization
- **THEN** its dirty favorites source, failing cases, changing reference availability, single samples, and competing processes remain explicit
- **AND** the 1.22-second tracing observation is not generalized into the contended full-run multiplier
- **AND** the potential 10-second shutdown saving is recorded once per affected process as conditional arithmetic
- **AND** historical test counts do not become acceptance counts for a different source state

### Requirement: Acceleration preserves the accepted coverage and environment

Execution optimizations SHALL retain the existing machine and OS by default, the relevant unit responsibilities, Chromium and Firefox behavior checks, every light/dark by desktop/tablet/mobile visual cell, and the accepted semantic, interaction, accessibility, and screenshot contracts.

#### Scenario: Select an implementation mechanism

- **WHEN** an optimization candidate is proposed or evaluated
- **THEN** its changes use documented configuration, native CLI flags, or public APIs of the tools
- **AND** dependency patches, forks, monkey-patching, and private internal APIs are excluded, even when the patch distribution mechanism is documented
- **AND** an internal defect without an eligible public mechanism or verified supported release fix is deferred rather than modified locally

#### Scenario: A candidate appears faster by doing less verification

- **WHEN** a candidate skips a browser, matrix cell, meaningful assertion, story interaction, or accessibility check, clips captured content, or weakens screenshot acceptance or timeout budgets
- **THEN** it is rejected as a coverage-preserving acceleration
- **AND** references are not regenerated merely to make the candidate pass
- **AND** a current matching reference is not treated as proof that the open below-viewport capture issue is solved

#### Scenario: A candidate requires another environment

- **WHEN** a candidate introduces extra machines, changes the unit environment, or depends on the independently tracked standalone-browser migration
- **THEN** its additional scope and unmeasured benefit are recorded explicitly
- **AND** it does not become a prerequisite for the same-environment candidates
- **AND** no extra-machine or test-migration implementation is inferred from this strategy

### Requirement: Automatic selection retains the native command constraint

Any proposed reduced development workflow SHALL use Vitest's dependency analysis through supported native behavior, preserve one existing command surface, and accurately distinguish reduced selection from complete verification. It SHALL NOT introduce new aliases, custom selection wrappers, manual impact manifests, or an unsupported affected-or-full fallback.

#### Scenario: Evaluate changed-source selection

- **WHEN** `--changed` is evaluated on a dirty checkout
- **THEN** Git supplies changed files without requiring staging and Vitest selects related test files through its statically discoverable module graph, including analyzable dynamic imports
- **AND** all configured visual cells of each selected story remain selected
- **AND** component, shared module, CSS/asset, story/setup, manifest/config, backend-contract, and new-file cases are checked for selection completeness on the actual worktree path
- **AND** runtime-computed dependencies and failed full-rerun triggers are treated as uncovered until verified

#### Scenario: There are no changed files or no related tests

- **WHEN** native one-shot selection produces an empty set
- **THEN** its successful empty exit is not represented as a complete suite run
- **AND** `passWithNoTests` is not represented as a fallback mechanism
- **AND** if no supported native affected-or-full behavior satisfies the accepted constraints, that candidate remains deferred and the existing unfiltered command remains unchanged

#### Scenario: Evaluate native watch mode

- **WHEN** a persistent watcher is considered as an alternative
- **THEN** the strategy identifies its initial full run, subsequent dependency-driven reruns, and process lifetime
- **AND** it does not claim watch mode provides the requested one-shot fallback
- **AND** native source-file arguments and manually named tests remain diagnostic options rather than the required routine workflow

### Requirement: Diagnostic savings preserve assertion and timeout semantics

Tracing and shutdown candidates SHALL reduce diagnostic overhead or release unused resources while preserving ordinary errors, screenshot comparisons and failure evidence, and effective time limits for genuinely stalled operations.

#### Scenario: Disable routine traces

- **WHEN** a trace-default change is evaluated
- **THEN** comparison results and reference/actual/diff evidence remain available
- **AND** the supported native trace option is validated for focused failure investigation
- **AND** the changed availability of retained failure traces is reconciled with its authoritative requirement before adoption

#### Scenario: Fix screenshot timeout cleanup

- **WHEN** a dependency fix is proposed for the lingering screenshot timeout
- **THEN** pending-handle diagnostics and command wall time are compared before and after the fix
- **AND** successful capture no longer requires an unnecessary active timer to finish
- **AND** a stalled screenshot still fails within its effective comparison budget
- **AND** installed dependency files and timeout limits are not directly modified to hide the shutdown symptom

### Requirement: Browser reuse and project restructuring prove independence

Isolation or visual-project consolidation candidates SHALL preserve per-test independence, complete story lifecycle, theme and viewport selection before rendering and interactions, and stable uniquely owned report and screenshot paths.

#### Scenario: Reuse the browser across visual files

- **WHEN** isolation is disabled for an experiment
- **THEN** normal and altered file orders and repeated runs produce equivalent results against the same references
- **AND** DOM, global/module state, mocks, subscriptions, timers, fixtures, storage, focus, theme, and viewport do not leak between scenarios
- **AND** a candidate that needs broad replacement cleanup infrastructure is not accepted as a minimal configuration optimization

#### Scenario: Share one visual project between six instances

- **WHEN** project consolidation is evaluated
- **THEN** each discovered story still executes once in every required theme and viewport cell
- **AND** supported APIs establish instance-specific globals before render and play
- **AND** references and generated evidence retain correct paths without collisions
- **AND** a candidate depending on a private Storybook injection key is rejected under the public-interface constraint

### Requirement: Scheduling and preparation savings preserve deterministic work

Concurrency, font readiness, and repeated-work candidates SHALL be judged by stable wall-time gains and equivalent rendered and behavioral results, with meaningful work preserved.

#### Scenario: Tune parallel execution on the existing machine

- **WHEN** worker or file concurrency changes are evaluated
- **THEN** project-level overlap and independent competing runners are recorded
- **AND** memory use, screenshot stability, failures, and total wall time are compared with defaults
- **AND** lower per-project worker counts are not assumed to serialize all projects globally
- **AND** unrelated processes are not terminated to improve a result

#### Scenario: Reduce font or repeated story preparation

- **WHEN** the evaluation avoids unused font loading or duplicates of invariant work
- **THEN** all rendered fonts, supported-language and mathematical glyphs, visual cells, and meaningful play/a11y checks remain correct
- **AND** the candidate does not remove production font assets or theme/viewport-dependent accessibility checks
- **AND** a faster comparison caused by missing font readiness or incomplete story state is rejected

### Requirement: Reduced development selection has a full delivery gate

A reduced development policy SHALL NOT be treated as sufficient delivery validation until complete frontend execution is preserved at completion and before release publication, including on a clean checkout.

#### Scenario: Evaluate the release workflow

- **WHEN** release validation is prepared for later implementation
- **THEN** the plan identifies that the current image publication workflow has no frontend test step
- **AND** the future gate runs the full required unit, Chromium/Firefox, and six-cell visual suite without changed/related filters
- **AND** publication depends on the full gate succeeding
- **AND** the required locked toolchain, browser/font environment, and reference validity are verified before claiming the gate exists

### Requirement: Candidate adoption follows specification and authorization gates

Specification preparation SHALL remain a strategy-only delivery until a separate request authorizes experiments or implementation. Each candidate SHALL be recorded as measured and adopted, rejected, or deferred with its evidence and tradeoffs, and only selected candidates SHALL alter their owning runtime contracts.

#### Scenario: Complete specification preparation

- **WHEN** proposal, design, specification, evidence, and future tasks are prepared and strictly validated
- **THEN** source, tests, references, dependencies, CI, and runtime configuration remain unchanged
- **AND** future experiment and implementation tasks remain unchecked
- **AND** the active change is retained without claiming delivered runtime acceleration or archiving incomplete work

#### Scenario: Adopt a candidate later

- **WHEN** an authorized evaluation establishes a useful candidate
- **THEN** its issue and affected proposal, design, tasks, and authoritative requirement deltas are reconciled before lasting implementation
- **AND** the selected combination is measured rather than adding unrelated candidate savings
- **AND** the relevant native tests, lint/type checks, Storybook build, and broader validation pass according to touched scope
- **AND** rollback restores the prior candidate configuration or supported dependency state without changing unrelated work or accepting new reference pixels

#### Scenario: Evaluate candidates sequentially after authorization

- **WHEN** the user authorizes the first screenshot shutdown cleanup experiment
- **THEN** only that candidate and its baseline and regression validation are performed, preserving default tracing, selected test identities, references, and screenshot timeout budgets
- **AND** any correction uses an eligible documented setting, public API, or verified supported upstream release; the rejected internal patch remains evidence only and is removed from the runtime and package manifests
- **AND** if an eligible cleanup is adopted, successful capture and early failure release the unused timer while stalled capture preserves its effective timeout and abort behavior; rejected or deferred cleanup retains the original runtime and reports the remaining shutdown delay
- **AND** repeated before/after results and any full-suite validation limitations are presented for user review
- **AND** research iterations use a small representative file/project scope, with identical selected cases before and after; broad validation is deferred to the selected combination before final delivery
- **AND** a subsequent explicit request may authorize a complete sequential sweep without per-candidate approval, while retaining the same public-interface, measurement, and coverage constraints
- **AND** when the user requests an uncommitted review state, the combined implementation and evidence remain in the owning worktree without a commit or integration until a later explicit request authorizes delivery
