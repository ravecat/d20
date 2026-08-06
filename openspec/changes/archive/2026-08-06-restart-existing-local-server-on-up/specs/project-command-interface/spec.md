## MODIFIED Requirements

### Requirement: Composite workflows retain their behavior

The root `justfile` SHALL retain `serve`, `up`, `format`, and `check` as named composite workflows, and each workflow MUST preserve its specified action order and command semantics without depending on a removed recipe.

#### Scenario: Development server workflow runs

- **WHEN** a developer runs `just serve` with optional node name and Erlang distribution arguments
- **THEN** the workflow runs `mix setup` before starting IEx with the Phoenix `serve` Mix alias and the supplied or existing default values

#### Scenario: Routed development workflow runs

- **WHEN** a developer runs `just up`
- **THEN** the workflow starts Docker Compose services before delegating to the private reuse-or-start helper
- **AND** the helper triggers the existing watcher when the exact `d20` node is registered or runs the retained `serve` workflow when it is absent

#### Scenario: Formatting workflow runs

- **WHEN** a developer runs `just format`
- **THEN** the workflow runs backend formatting before frontend asset formatting

#### Scenario: Validation workflow runs

- **WHEN** a developer runs `just check`
- **THEN** the workflow checks formatting, asset linting, asset tests, frontend types, and backend tests in the existing order
- **AND** the workflow does not check generated agent-skill metadata
