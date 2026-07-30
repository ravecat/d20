# frontend-shared-layer Specification

## Purpose
TBD - created by archiving change introduce-frontend-shared-layer. Update Purpose after archive.
## Requirements
### Requirement: Frontend exposes staged FSD boundaries

The frontend SHALL expose an App layer, page slices, and a Shared layer under `assets/js` while retaining the stable root build entry required by Phoenix and Vite.

#### Scenario: Application bootstrap runs

- **WHEN** the browser loads the `js/app.js` asset
- **THEN** the root adapter initializes the application through the App layer

#### Scenario: Inertia resolves a page

- **WHEN** the server provides an existing page name
- **THEN** the App layer resolves the corresponding page slice through its public API

### Requirement: Transitional Shared relocation preserves behavior

The migration SHALL move the existing root component, store, and type buckets into documented transitional Shared segments without changing their runtime or type contracts.

#### Scenario: Existing components move

- **WHEN** a component is relocated from the root component bucket
- **THEN** its props, markup, styles, accessible names, and rendered behavior remain unchanged

#### Scenario: Existing stores and types move

- **WHEN** a store or type module is relocated into Shared
- **THEN** its exported API, channel behavior, normalization, and data shapes remain unchanged

#### Scenario: Transitional ownership is evaluated later

- **WHEN** the structural migration is complete
- **THEN** page-local and domain-aware modules remain eligible for later movement into purpose-based FSD segments or slices

### Requirement: Shared segments expose public APIs

Each populated Shared segment SHALL expose its supported runtime values and types through a segment-level public API, and external consumers MUST use that public API.

#### Scenario: Runtime infrastructure is consumed

- **WHEN** a frontend module needs the connected Phoenix socket
- **THEN** it imports the named socket export from the `shared/api` public API

#### Scenario: Transport contracts are consumed

- **WHEN** a frontend module needs embedded-module connection or entry contracts
- **THEN** it imports those types from the `shared/api` public API

#### Scenario: Relocated modules are consumed

- **WHEN** a page, App module, test harness, or different Shared segment needs a relocated component, store, or type
- **THEN** it imports the supported export from that segment's public API

### Requirement: Legacy technical roots are retired

The frontend SHALL remove the superseded root component, store, and type directories and their dedicated aliases after consumers migrate.

#### Scenario: Import boundaries are inspected

- **WHEN** the migration is complete
- **THEN** no runtime or test module imports through `~actions`, `~components`, `~pages`, `~stores`, or `~types`

#### Scenario: Resolver configuration is inspected

- **WHEN** TypeScript and Vite aliases are evaluated
- **THEN** the root `~/*` alias addresses the FSD structure without legacy technical-bucket aliases

### Requirement: Shared extraction preserves compatibility

Extracting modules into Shared SHALL preserve existing Inertia page resolution, Svelte component contracts, Phoenix socket and channel behavior, iframe SDK bootstrap behavior, and supported frontend validation.

#### Scenario: Existing frontend workflows use relocated infrastructure

- **WHEN** session channels, workspace discovery, or embedded game frames use the relocated Shared modules
- **THEN** their observable behavior and external payload contracts remain unchanged

#### Scenario: Frontend validation runs after extraction

- **WHEN** the Shared extraction is complete
- **THEN** focused tests, the complete frontend tests, formatting checks, lint, type checking, and the production build pass without adding runtime dependencies
