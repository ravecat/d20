## Why

D20's backend validation currently relies on formatting and tests, so success-typing defects, architecture-boundary violations, structural duplication, and high-signal generated-code problems can reach release verification without a dedicated check. Issue [#179](https://github.com/ravecat/d20/issues/179) tracks adding a reproducible backend quality gate while the related release-workflow task [#113](https://github.com/ravecat/d20/issues/113) remains responsible for deciding when published images consume that gate.

## What Changes

- Integrate the VibeKit quality stack as development/test-only tooling: Credo, Dialyxir, ExDNA, ExSlop, and Reach.
- Add one Mix backend quality command that runs warnings-as-errors compilation, backend formatting checks, tests, Credo/ExSlop, Dialyzer, ExDNA, and Reach with D20-specific configuration.
- Calibrate existing-code findings with explicit configuration or a reviewed baseline instead of blanket suppression or an unexplained zero-finding assumption.
- Configure Reach to enforce that the `D20.*` domain boundary does not depend on `D20Web.*`, while retaining useful architecture, code-flow, and OTP analysis.
- Compose the backend gate into `just check` without removing the OpenSpec lifecycle check, frontend formatting, linting, tests, type checking, or Storybook build and without repeating backend formatting or tests.
- Document local use, first-run Dialyzer cost, finding review, and the handoff to release workflow task #113.
- Keep the standalone Vibe agent, Vibe web UI, Phoenix Replay, Exograph, application supervision, and production dependencies outside this change.

## Capabilities

### New Capabilities

- `backend-code-quality-gate`: Defines the backend validation suite, dependency/runtime isolation, project-specific analyzer policies, and actionable failure behavior.

### Modified Capabilities

- `project-command-interface`: Changes the retained `just check` composition so it delegates backend verification to the new Mix gate while preserving every existing frontend check.

## Impact

- Affected files include `mix.exs`, `mix.lock`, `justfile`, new analyzer configuration files, analyzer-driven backend and test corrections, and developer workflow documentation.
- Development and test dependency resolution grows; the production application and release dependency graph remain unchanged.
- The first Dialyzer run will build its PLT and take materially longer than subsequent runs; local and automated caches may need follow-up integration under #113.
- Existing backend code may require focused corrections or reviewed analyzer configuration before the gate can pass. No public API, route, Phoenix channel, persistence, session runtime, game-module contract, iframe integration, database migration, or user-visible behavior changes.
- Rollback consists of removing the development/test dependencies, analyzer configuration, Mix alias, and `just check` delegation; no data or runtime rollback is required.
