## Context

D20 currently exposes `just check` as its cross-stack validation workflow. It runs backend formatting, frontend formatting, frontend linting, frontend tests, frontend type checking, and backend tests, but it has no success-typing, backend lint, structural duplication, or architecture-policy stage. The release workflow tracked by issue #113 publishes separately and is not changed here.

VibeKit is an Igniter installer that generates a conventional `mix ci` alias and configures Credo, Dialyxir, ExDNA, ExSlop, and Reach. D20 already depends on Igniter and has project-specific Mix aliases, Recode policy, a root `justfile`, and repository guidance that defines domain, runtime, and web boundaries. The generated result therefore needs review and calibration rather than unconditional adoption.

The gate serves contributors and release automation. It must work in the repository's Nix environment, retain the declared Elixir 1.18 compatibility floor, keep PostgreSQL-backed test setup intact, and add no production application behavior or dependency.

## Goals / Non-Goals

**Goals:**

- Provide one reproducible Mix command for comprehensive backend validation.
- Preserve `just check` as the complete backend and frontend gate without duplicate backend work.
- Make architecture, typing, duplication, and high-signal code-quality findings reviewable and capable of blocking regressions.
- Encode a real D20 domain-to-web boundary without flagging the application composition root or runtime adapters that intentionally publish through web-owned processes.
- Keep tool dependencies outside production runtime and document their operational cost and maintenance policy.

**Non-Goals:**

- Embedding the standalone Vibe agent, its web UI, sessions, storage, provider credentials, or supervision tree in D20.
- Adding Phoenix Replay, Exograph, or any other Elixir Vibe package outside the VibeKit quality stack.
- Changing release workflow triggers or publication behavior owned by issue #113.
- Replacing Recode, changing production frontend tooling, or removing any existing frontend check.
- Changing public APIs, routes, channel payloads, persistence, session semantics, game rules, iframe contracts, or user-visible behavior.

## Decisions

### Use VibeKit as an audited one-time bootstrap

Run `mix igniter.install vibe_kit` without agent-document flags, then review and adapt the generated edits. Commit the resulting tool dependencies, Mix configuration, and analyzer files as D20-owned configuration. Do not retain `vibe_kit` itself merely to keep the installer available.

This uses the ecosystem's supported integration path while preventing future installer defaults from silently changing D20 policy. Manually recreating every generated edit was rejected because it would bypass the integration being adopted; retaining VibeKit as a permanent dependency was rejected because D20 does not need the installer during normal development or runtime.

### Make `mix ci` the backend gate and `just check` the cross-stack gate

The generated `mix ci` alias will run, in order:

1. compilation with warnings as errors;
2. backend formatting verification;
3. backend tests through the existing test alias;
4. Credo in strict mode with ExSlop;
5. Dialyzer;
6. ExDNA with the reviewed project clone budget;
7. Reach architecture and smell analysis.

`def cli/0` will select `MIX_ENV=test` for `ci`, preserving access to ExUnit and the existing database-setup test alias. `just check` will invoke `mix ci` once, followed by the existing frontend formatting, linting, tests, and type checking in that order. This replaces the current interleaving of backend formatting and tests, but retains every check and avoids running either backend stage twice.

Keeping separate ad hoc analyzer commands in `just check` was rejected because it would create two backend gate definitions. Replacing `just check` with `mix ci` was rejected because the Mix alias does not cover Svelte and TypeScript.

### Calibrate each analyzer according to its evidence model

- Credo runs in strict mode with ExSlop's recommended high-signal checks. Existing Recode rules remain authoritative for rewriting and formatting-oriented policy; overlapping or contradictory checks are reconciled explicitly in `.credo.exs`.
- Dialyzer includes `:ex_unit` in its test PLT and starts without a blanket ignore file. A narrow warning filter is permitted only for a demonstrated false positive or external incompatibility and must identify the exact warning and rationale.
- ExDNA analyzes the maintained backend source scope using a checked-in configuration. Implementation records the reviewed current clone count as an explicit `--max-clones` budget instead of assuming zero duplication. A higher count fails the gate, and the budget is reduced when accepted cleanup lowers the baseline.
- Reach uses `.reach.exs` to classify pure domain and game-policy modules separately from `D20Web.*`. The application composition root and runtime adapters with intentional publication responsibilities are not placed in the pure domain layer. Direct pure-domain dependencies on the web layer are forbidden. `mix reach.check --arch --smells` makes architecture policy blocking while initially keeping heuristic smell findings advisory.

Zero-tolerance settings for every analyzer were rejected because D20 is an existing codebase and some structural repetition or heuristic output may be intentional. Blanket exclusions were rejected because they hide future regressions rather than encode the reviewed current state.

### Treat analyzer output as source-fix evidence first

Implementation will run each analyzer independently before composing the final gate. Findings are resolved by correcting the underlying code when that can be done without changing public behavior. A suppression, exclusion, or baseline entry is accepted only when it is narrow, reviewable, and justified by an intentional pattern or analyzer limitation.

This avoids mixing tool installation failures with code findings and keeps any incidental cleanup traceable to the gate. Broad formatting, unrelated refactoring, and public contract changes remain outside scope.

### Preserve production dependency and runtime isolation

Credo, Dialyxir, ExDNA, ExSlop, and Reach are declared only for `[:dev, :test]` with `runtime: false`. The standalone `vibe` package is not added. Production dependency resolution and application startup must not include or start any of these tools.

## Risks / Trade-offs

- [Risk] The first Dialyzer run is slow because it builds a PLT. - Document the first-run behavior and let issue #113 decide automated cache strategy.
- [Risk] ExDNA's numeric budget can allow a removed clone to be replaced by a different clone. - Review the report, lower the budget when cleanup lands, and prefer narrow source exclusions over increasing the budget.
- [Risk] Credo, ExSlop, and Recode can express overlapping policy. - Keep Recode in place and explicitly disable only duplicated or contradictory Credo checks with rationale.
- [Risk] A broad Reach domain pattern would flag `D20.Application` and `D20.Game.Server`, which currently depend on web-owned runtime modules intentionally. - Define the pure domain layer with explicit module patterns and test both an allowed adapter dependency and a forbidden domain dependency.
- [Risk] Running backend analysis before frontend checks increases `just check` time before a frontend failure is reported. - Keep the order deterministic and provide individual native commands for focused validation.
- [Risk] Tool upgrades can change findings or defaults. - Pin resolved versions in `mix.lock`, review dependency updates, and keep project policy in checked-in configuration.

## Migration Plan

1. Run the VibeKit installer without agent-document generation and review its diff against the existing Mix and Recode configuration.
2. Run Credo/ExSlop, Dialyzer, ExDNA, and Reach independently to characterize current findings.
3. Fix in-scope findings and add only narrow, justified configuration or the measured ExDNA clone budget.
4. Define `mix ci`, its preferred test environment, and the explicit Reach domain/web policy.
5. Replace the separate backend format and test steps in `just check` with one `mix ci` invocation while retaining all frontend steps.
6. Document local use and validation, then run focused tool checks, `just check`, and strict OpenSpec validation.
7. Hand the stable command to issue #113 for release-workflow gating and caching.

Rollback removes the new dev/test dependencies, analyzer configuration, `mix ci` alias, preferred environment entry, and `just check` delegation, then restores the prior explicit backend format and test steps. No database, runtime, protocol, or client rollback is required.

## Open Questions

None.
