## MODIFIED Requirements

### Requirement: Composite workflows retain their behavior

The root `justfile` SHALL retain `serve`, `up`, `format`, and `check` as named composite workflows, and each workflow MUST preserve its specified action order and command semantics without depending on a removed recipe.

#### Scenario: Development server workflow runs

- **WHEN** a developer runs `just serve` with optional node name and Erlang distribution arguments
- **THEN** the workflow runs `mix setup` before starting IEx with the Phoenix `serve` Mix alias and the supplied or existing default values

#### Scenario: Routed development workflow runs

- **WHEN** a developer runs `just up`
- **THEN** the workflow starts Docker Compose services before running the retained `serve` workflow

#### Scenario: Formatting workflow runs

- **WHEN** a developer runs `just format`
- **THEN** the workflow runs backend formatting before frontend asset formatting

#### Scenario: Validation workflow runs

- **WHEN** a developer runs `just check`
- **THEN** the workflow runs the complete backend `mix ci` gate exactly once
- **AND** then checks frontend formatting, linting, tests, and types in that order
- **AND** backend formatting and backend tests are not run a second time outside `mix ci`
- **AND** the workflow does not check generated agent-skill metadata
