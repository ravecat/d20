# frontend-code-quality-tooling Specification

## Purpose
TBD - created by archiving change replace-biome-with-eslint-oxfmt. Update Purpose after archive.
## Requirements
### Requirement: Svelte-aware frontend linting

The frontend package SHALL lint JavaScript, TypeScript, and Svelte sources with ESLint using the recommended JavaScript, TypeScript, and Svelte rule sets and the repository's Svelte and TypeScript project configuration.

#### Scenario: Run the frontend linter

- **WHEN** a developer runs `mix assets.lint` or the package `lint` script
- **THEN** ESLint analyzes the supported frontend source files and returns a non-zero status for lint violations

### Requirement: Dedicated frontend formatting

The frontend package SHALL use Oxfmt with a 100-column print width, two-space indentation, and Svelte formatting support.

#### Scenario: Check formatting without writes

- **WHEN** a developer runs `mix assets.format.check` or the package `format.check` script
- **THEN** Oxfmt checks formatting without modifying files and returns a non-zero status for unformatted supported files

#### Scenario: Apply frontend formatting

- **WHEN** a developer runs `mix assets.format` or the package `format` script
- **THEN** fixable ESLint findings are applied before Oxfmt formats supported files

### Requirement: Stable repository command boundary

The migration SHALL preserve the existing Mix aliases and top-level just recipes used for frontend linting, formatting, tests, typechecking, and aggregate checks.

#### Scenario: Run the aggregate package check

- **WHEN** a developer runs the package `check` script
- **THEN** formatting and linting are both checked through Oxfmt and ESLint

#### Scenario: Run the repository check

- **WHEN** a developer runs `just check`
- **THEN** the existing frontend and backend validation sequence remains available without Biome

### Requirement: Tooling source boundaries

The lint and format configurations SHALL exclude dependencies, generated output, vendored frontend JavaScript, and the existing CSS source area that was outside Biome's formatting scope.

#### Scenario: Check frontend tooling scope

- **WHEN** lint or format commands traverse the frontend package
- **THEN** they do not report or rewrite files under excluded dependency, generated, vendor, or CSS paths

### Requirement: Biome removal

The repository SHALL NOT retain Biome as a frontend dependency, configuration, command implementation, or tracked inline suppression after the migration.

#### Scenario: Inspect tracked tooling references

- **WHEN** the migration is complete
- **THEN** tracked frontend tooling files and documentation reference ESLint and Oxfmt instead of Biome

### Requirement: Behavior-focused frontend tests

Frontend unit, component, integration, and browser tests SHALL prioritize application logic and user-observable behavior such as content, accessibility semantics, state transitions, permissions, focus, enabled state, and interaction outcomes. Frontend test sources MUST NOT directly read computed styles, element rectangles, or element width and height dimension properties to assert visual presentation. The frontend lint command SHALL enforce this test boundary without restricting production source code.

#### Scenario: Verify application behavior

- **WHEN** a frontend test covers an authentication, application shell, game launch, or workspace workflow
- **THEN** it asserts the relevant content, semantic state, focus, permission, or interaction outcome without reading computed styles or element geometry

#### Scenario: Reject computed-style presentation assertions

- **WHEN** a frontend test source directly calls `getComputedStyle`
- **THEN** the frontend lint command returns a non-zero status with a diagnostic for the restricted global

#### Scenario: Reject geometry presentation assertions

- **WHEN** a frontend test source directly calls an element rectangle method or reads an element width or height dimension property
- **THEN** the frontend lint command returns a non-zero status with a diagnostic for the restricted property

#### Scenario: Preserve production measurement APIs

- **WHEN** production frontend code requires a browser measurement API to implement application behavior
- **THEN** the test-scoped lint restriction does not reject that production source solely for using the measurement API
