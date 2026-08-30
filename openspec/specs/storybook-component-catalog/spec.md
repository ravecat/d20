# storybook-component-catalog Specification

## Purpose

Define D20's isolated production-component catalog, deterministic story boundaries, inspection tooling, contributor commands, and repository validation.
## Requirements
### Requirement: Isolated Svelte component catalog

The frontend package SHALL provide a Storybook catalog for production Svelte components that starts and builds without starting Phoenix, PostgreSQL, live channels, workspace transports, or external game iframes. The root command interface SHALL expose the catalog independently from routed application startup.

#### Scenario: Start the catalog for local development

- **WHEN** a contributor runs `just storybook` with optional Storybook CLI arguments
- **THEN** Storybook serves the catalog on port 6006 when that port is available
- **AND** Storybook automatically uses the nearest available port without prompting when port 6006 is occupied
- **AND** the command reports the selected URL without opening a browser automatically
- **AND** every optional development CLI argument is forwarded unchanged to Storybook
- **AND** no Phoenix application or backend service is required to browse isolated stories

#### Scenario: Build the static catalog

- **WHEN** a contributor runs the documented Storybook static-build command
- **THEN** the frontend package emits the catalog under `priv/static/storybook` without opening a live backend connection
- **AND** Phoenix can serve the generated files under `/storybook/` when they exist
- **AND** the regular production asset deployment does not build Storybook implicitly

#### Scenario: Start routed application development

- **WHEN** a contributor runs `just up`
- **THEN** Docker Compose starts before the interactive Phoenix workflow
- **AND** Storybook does not start in that process tree
- **AND** the contributor can start Storybook independently with `just storybook`

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

The catalog SHALL provide generated documentation, controls, viewport selection, and accessibility inspection for discovered stories while preserving a path to add Storybook browser-backed interaction tests separately. The interactive catalog SHALL use the complete available canvas by default until a contributor explicitly selects a named viewport.

#### Scenario: Open the catalog without selecting a viewport

- **WHEN** a contributor opens Storybook without a viewport selection
- **THEN** the preview uses the complete available canvas
- **AND** no Desktop, Tablet landscape, or Mobile viewport is emulated

#### Scenario: Inspect the smoke story

- **WHEN** a contributor opens the baseline story in Storybook
- **THEN** they can inspect its generated documentation and editable controls
- **AND** they can explicitly select a narrow viewport and run the configured accessibility inspection

### Requirement: Authentication workflows are inspectable in isolation

The Storybook catalog SHALL organize production authentication surfaces under complete Home stories and route-labelled `Sign In` and `Sign Up` pages. It SHALL expose the production AuthDialog, Account Settings, Registration Completion, and Auth Confirmation components through typed deterministic stories. The stories SHALL render without Phoenix or a live Inertia submission boundary and MUST prevent form interaction from contacting an application server.

#### Scenario: Inspect authentication dialog states

- **WHEN** a contributor browses the Home, `Sign In`, and `Sign Up` story groups
- **THEN** Home Sign In and Home Sign Up cover the initial AuthDialog states through the production Header
- **AND** Home Sign In Sent Magic Link covers the Magic Link request completion state in the complete page context
- **AND** Home Confirmation With Magic Link covers email-backed sudo reauthentication through the production Header prompt
- **AND** Home Sign Up With Email covers sign-up email request completion through the production Header
- **AND** no standalone Sign In or Sign Up authentication-dialog group remains
- **AND** each state uses deterministic page and authentication-store state without a live backend

#### Scenario: Inspect Account Settings states

- **WHEN** a contributor opens the Account Settings stories
- **THEN** the production page can be inspected with its required established username
- **AND** provider linked, unlinked, available, and unavailable states are represented by deterministic props

#### Scenario: Inspect registration completion states

- **WHEN** a contributor opens the Registration Completion stories
- **THEN** the production page can be inspected for the distinct Magic Link and Auth Provider completion states
- **AND** the Auth Provider state exposes the production action for choosing another registration method
- **AND** the Auth Provider state represents every provider-backed completion that has the same user-visible behavior
- **AND** no provider credential, callback payload, or live form submission is required

#### Scenario: Inspect Magic Link login confirmation states

- **WHEN** a contributor opens the Magic Link Login Confirmation stories under `Sign In`
- **THEN** the production page can be inspected for signed-out login and sudo reauthentication
- **AND** the remember-me choice follows the production page state

#### Scenario: Interact with a catalog form

- **WHEN** a contributor submits a form from any authentication page story
- **THEN** Storybook prevents a live Inertia request
- **AND** the rendered production page remains available for inspection

#### Scenario: Inspect an authentication story with addon tooling

- **WHEN** a contributor opens an authentication page story in the supported desktop layout
- **THEN** the addon panel is visible to the right of the story canvas
- **AND** installed Controls, Actions, Interactions, and other addon panels remain available without per-story layout configuration
- **AND** narrow viewports retain Storybook's responsive manager layout

### Requirement: Account Settings uses a route-like catalog label

The Storybook catalog SHALL display the Account Settings component group as `/settings` under the existing `Pages` hierarchy while preserving the established Account Settings story IDs and scenarios.

#### Scenario: Browse Account Settings by its route-like label

- **WHEN** a contributor expands `Pages` in the Storybook sidebar
- **THEN** the Account Settings component group is labelled `/settings` with an ASCII slash
- **AND** Established Account, Provider Only Account, and No Available Providers remain its child stories
- **AND** their story IDs retain the `pages-settings` component prefix

### Requirement: Catalog navigation contains only authored stories

The Storybook catalog SHALL NOT opt existing stories into autogenerated documentation pages.

#### Scenario: Browse the catalog sidebar

- **WHEN** a contributor opens the Storybook catalog
- **THEN** each catalog group contains only its explicitly authored stories
- **AND** no autogenerated Docs entry is present

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

### Requirement: Home page is inspectable in isolation

The Storybook catalog SHALL expose the production home page through a typed deterministic story displayed as `/` under the existing `Pages` hierarchy. The story MUST render without Phoenix or remote asset availability and SHALL represent the released, in-development, and planned catalog stages.

#### Scenario: Inspect the home-page catalog

- **WHEN** a contributor expands `Pages` and opens the `/` story group
- **THEN** the group label uses the ASCII slash
- **AND** the production `HomePage` renders with deterministic game catalog entries
- **AND** released, in-development, and planned entries are visible
- **AND** the story retains the `home--catalog` ID
- **AND** the story does not require a live backend or remote image response

### Requirement: Page catalog distinguishes public and authenticated surfaces

The Storybook catalog SHALL organize complete routed page stories under `Pages/Public` or `Pages/Authenticated` according to the authentication state required to display each scenario. A complete page metadata group MUST NOT mix public and authenticated scenarios. Shared component and widget stories SHALL remain outside this page access hierarchy.

#### Scenario: Browse public pages

- **WHEN** a contributor expands `Pages/Public`
- **THEN** Home's anonymous catalog, sign-in, sign-up, and email-completion scenarios are available under `/`
- **AND** signed-out Magic Link confirmation is available under `/users/log-in/:token`
- **AND** registration completion is available under `/users/register/complete`
- **AND** Account Settings and reauthentication scenarios are absent

#### Scenario: Browse authenticated pages

- **WHEN** a contributor expands `Pages/Authenticated`
- **THEN** Account Settings is available under `/settings`
- **AND** Home's email-backed confirmation scenario is available under `/`
- **AND** tokenized reauthentication is available under `/users/log-in/:token`
- **AND** sign-in, sign-up, signed-out confirmation, and registration completion scenarios are absent

#### Scenario: Browse non-page stories

- **WHEN** a contributor opens a shared component or widget story
- **THEN** its existing catalog hierarchy remains unchanged
- **AND** it is not duplicated under `Public` or `Authenticated`
