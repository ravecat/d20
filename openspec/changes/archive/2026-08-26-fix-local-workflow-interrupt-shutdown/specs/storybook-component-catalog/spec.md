## MODIFIED Requirements

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
