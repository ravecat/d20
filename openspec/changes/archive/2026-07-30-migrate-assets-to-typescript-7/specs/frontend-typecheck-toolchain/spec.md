## ADDED Requirements

### Requirement: Native TypeScript 7 command-line checker
The frontend package SHALL resolve the stable TypeScript 7 native compiler as the `tsc` executable used for project-wide command-line checking.

#### Scenario: Resolve the command-line compiler
- **WHEN** a developer installs the locked frontend dependencies through the repository asset setup command
- **THEN** `bun run tsc --version` reports TypeScript 7.0.x
- **AND** the resolved `tsc` executable is provided by the native TypeScript 7 dependency

### Requirement: TypeScript 6 compiler API compatibility
The frontend package SHALL expose TypeScript 6 under the canonical `typescript` package name for tools whose supported peer range or programmatic API does not include TypeScript 7.

#### Scenario: Resolve compiler API consumers
- **WHEN** ESLint and Svelte checking load their TypeScript peer dependency
- **THEN** they resolve the supported TypeScript 6 compiler API
- **AND** importing `typescript` reports version 6.0.x
- **AND** dependency installation does not report an unsupported TypeScript peer for the configured `typescript-eslint` toolchain

### Requirement: TypeScript 7-compatible project configuration
The frontend TypeScript configuration SHALL be accepted by TypeScript 7 without deprecated or removed compiler options and SHALL preserve the existing strictness, included files, ambient type scope, and import alias mappings.

#### Scenario: Check the project configuration
- **WHEN** native `tsc` checks `assets/tsconfig.json`
- **THEN** the configuration contains no `baseUrl` option
- **AND** every existing `paths` alias resolves to the same `assets/js` location as before the migration
- **AND** the current strict, bundler-oriented, no-emit project check completes without errors

### Requirement: Stable typecheck commands
The migration SHALL preserve `bun run typecheck` and `mix typecheck` as the frontend and repository command boundaries, with native TypeScript checking followed by Svelte-aware checking.

#### Scenario: Run frontend type checking
- **WHEN** a developer runs `bun run typecheck` from `assets/`
- **THEN** native TypeScript 7 checks the configured project without emitting files
- **AND** `svelte-check` validates the Svelte component set through its supported TypeScript API

#### Scenario: Run repository type checking
- **WHEN** a developer runs `mix typecheck` from the repository root
- **THEN** it delegates to the same successful frontend typecheck command

### Requirement: Measured typecheck performance
The migration SHALL compare TypeScript 5.9 and TypeScript 7 under identical local conditions using a warm-up, at least five serial samples per case, and median elapsed time.

#### Scenario: Validate the native compiler benefit
- **WHEN** pre-migration and post-migration standalone compiler measurements are compared
- **THEN** the TypeScript 7 median for `tsc --noEmit -p tsconfig.json` is at least two times faster than the TypeScript 5.9 median
- **AND** the raw samples and medians are reported with the implementation handoff

#### Scenario: Measure the complete command
- **WHEN** the complete `bun run typecheck` command is benchmarked before and after migration
- **THEN** its raw samples and median are reported separately from the standalone compiler result
- **AND** the result accounts for `svelte-check` remaining on the TypeScript 6 compatibility API

### Requirement: Vite build isolation
The TypeScript migration SHALL preserve the Vite 8 Oxc/Rolldown build pipeline and SHALL NOT claim TypeScript compiler improvements as Vite build improvements.

#### Scenario: Build production assets
- **WHEN** a developer runs `mix assets.build` after the migration
- **THEN** Vite emits the existing JavaScript and CSS production entries successfully
- **AND** the build does not invoke `tsc` as its TypeScript transpiler
- **AND** any timing comparison is reported as a non-regression observation separate from typecheck performance

### Requirement: Migration isolation
The migration SHALL preserve browser targets, runtime behavior, public interfaces, and existing validation coverage while limiting intentional direct dependency changes to the TypeScript compiler layout.

#### Scenario: Review the migration
- **WHEN** the manifest, lockfile, configuration, and generated asset behavior are reviewed
- **THEN** no unrelated direct dependency upgrade or source reformat is included
- **AND** frontend linting, tests, typechecking, and the production build pass
- **AND** application routes, payloads, session behavior, and iframe module contracts remain unchanged
