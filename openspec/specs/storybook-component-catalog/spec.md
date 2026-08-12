# storybook-component-catalog Specification

## Purpose

Define D20's isolated production-component catalog, deterministic story boundaries, inspection tooling, contributor commands, and repository validation.

## Requirements

### Requirement: Isolated Svelte component catalog

The frontend package SHALL provide a Storybook catalog for production Svelte components that starts and builds without starting Phoenix, PostgreSQL, live channels, workspace transports, or external game iframes.

#### Scenario: Start the catalog for local development

- **WHEN** a contributor runs the documented Storybook development command from the repository command boundary
- **THEN** Storybook serves the catalog on port 6006 when that port is available
- **AND** Storybook automatically uses the nearest available port without prompting when port 6006 is occupied
- **AND** the command reports the selected URL without opening a browser automatically
- **AND** optional development CLI arguments are forwarded unchanged to Storybook
- **AND** no Phoenix application or backend service is required to browse isolated stories

#### Scenario: Build the static catalog

- **WHEN** a contributor runs the documented Storybook static-build command
- **THEN** the frontend package emits the catalog under `priv/static/storybook` without opening a live backend connection
- **AND** Phoenix can serve the generated files under `/storybook/` when they exist
- **AND** the regular production asset deployment does not build Storybook implicitly

#### Scenario: Start the routed development workflow

- **WHEN** a contributor runs `just up` without an already-running D20 server
- **THEN** Docker Compose starts before Phoenix and Storybook
- **AND** the root Just workflow invokes the process supervisor supplied by the Nix development shell
- **AND** the frontend package exposes only the atomic Storybook command rather than the composite host workflow
- **AND** Phoenix and Storybook run concurrently in the foreground
- **AND** their combined output identifies each line as `phoenix` or `storybook`

#### Scenario: Reuse an existing D20 server

- **WHEN** `just up` finds the exact `d20` node already registered
- **THEN** the reuse helper triggers the existing watcher and exits successfully
- **AND** the supervised Storybook process continues running
- **AND** the existing server retains ownership of its original output stream

### Requirement: Production-style story rendering

Storybook SHALL reuse the frontend's Svelte and Vite integration, source aliases, global Tailwind and daisyUI styles, browser targets, and production components. The catalog MUST NOT substitute copied production markup solely for story rendering.

#### Scenario: Render the baseline production component

- **WHEN** Storybook loads the baseline smoke story
- **THEN** it renders the imported production Svelte component with the application theme and design tokens
- **AND** its source alias resolves through the shared frontend configuration

#### Scenario: Compile the application production bundle

- **WHEN** the regular frontend production build runs after Storybook is added
- **THEN** the existing Phoenix Vite integration and application asset entries remain available
- **AND** Storybook-only configuration does not enter the production runtime bundle

### Requirement: Deterministic story boundaries

Stories SHALL express meaningful component states through typed deterministic args or reusable fixtures. Stories for connected UI MUST replace production side-effect boundaries so catalog rendering does not depend on live Phoenix channels, Inertia submissions, workspace transports, external game clients, or mutable backend state.

#### Scenario: Review a prop-driven component state

- **WHEN** a contributor opens a prop-driven component story
- **THEN** its complete scenario is represented by typed story metadata and args using deterministic values

#### Scenario: Add a connected story

- **WHEN** a contributor adds a story for UI that normally starts a production connection or submission
- **THEN** the story replaces that boundary with a deterministic Storybook mock or fixture
- **AND** the story continues to import the real production presentation component

### Requirement: Catalog inspection tooling

The catalog SHALL provide generated documentation, controls, viewport selection, and accessibility inspection for discovered stories while preserving a path to add Storybook browser-backed interaction tests separately.

#### Scenario: Inspect the smoke story

- **WHEN** a contributor opens the baseline story in Storybook
- **THEN** they can inspect its generated documentation and editable controls
- **AND** they can select a narrow viewport and run the configured accessibility inspection

### Requirement: Storybook-aware frontend quality checks

The frontend type checker and linter SHALL include Storybook configuration and story sources using the repository's strict TypeScript settings and Storybook's recommended lint rules. Generated static Storybook output SHALL remain outside tracked source and static tooling scope.

#### Scenario: Reject an invalid story

- **WHEN** a story violates its component prop types or a recommended Storybook lint rule
- **THEN** the corresponding frontend typecheck or lint command exits unsuccessfully

#### Scenario: Ignore generated catalog output

- **WHEN** linting or formatting traverses the frontend package after a static catalog build
- **THEN** it does not report or rewrite generated files under `priv/static/storybook/`
- **AND** Git does not treat that generated Phoenix static subtree as source

### Requirement: Repository catalog validation

The repository aggregate validation workflow SHALL build the static Storybook catalog so broken configuration, unresolved imports, or non-buildable stories fail before the change is accepted.

#### Scenario: Run repository checks

- **WHEN** a contributor runs `just check`
- **THEN** the workflow performs the Storybook static build in addition to the established formatting, linting, frontend tests, type checks, and backend tests
- **AND** a failed catalog build causes the workflow to exit unsuccessfully

### Requirement: Documented contributor workflow

Repository documentation SHALL describe how to start and build Storybook, where stories and reusable fixtures belong, and which validation guarantees remain the responsibility of existing Vitest and full application browser tests.

#### Scenario: Discover the Storybook workflow

- **WHEN** a contributor reads the project setup and command documentation
- **THEN** they can identify the supported development and static-build commands
- **AND** they can identify the production-component, deterministic-fixture, and no-live-transport rules for future stories
