## MODIFIED Requirements

### Requirement: Composite workflows retain their behavior

The root `justfile` SHALL retain `serve`, `up`, `format`, and `check` as named composite workflows without depending on a public helper recipe or repository process-management script.

#### Scenario: Development server workflow starts an absent node

- **WHEN** a developer runs `just serve` and no BEAM carries the requested `-sname`
- **THEN** the workflow runs `mix setup` before starting Watchexec and IEx
- **AND** remains attached to the interactive workflow

#### Scenario: Existing default server is requested again

- **WHEN** a developer runs `just serve` and a BEAM carries `-sname d20`
- **THEN** setup completes before that exact short-name BEAM is force-stopped
- **AND** a new watched `d20` runtime starts in the invoking terminal

#### Scenario: Existing explicit server is requested again

- **WHEN** a developer runs `just serve --sname d20_custom`
- **THEN** only the BEAM carrying `-sname d20_custom` is replaced
- **AND** supplied Erlang arguments are preserved

#### Scenario: A partial or different node name is running

- **WHEN** a BEAM carries `-sname d20_test` and the developer requests `d20`
- **THEN** `d20_test` remains running

#### Scenario: Mix dependency manifest changes

- **WHEN** `mix.exs` or `mix.lock` changes while the watched runtime is active
- **THEN** Watchexec replaces its child without running setup or migrations

#### Scenario: Routed development workflow runs

- **WHEN** a developer runs `just up`
- **THEN** Docker Compose starts before `serve`
- **AND** the replacement remains attached to the invoking terminal

#### Scenario: Formatting workflow runs

- **WHEN** a developer runs `just format`
- **THEN** backend formatting runs before frontend formatting

#### Scenario: Validation workflow runs

- **WHEN** a developer runs `just check`
- **THEN** the existing formatting, OpenSpec, frontend, Storybook, and backend checks run in order
