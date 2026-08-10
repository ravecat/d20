## MODIFIED Requirements

### Requirement: Initial development startup order

The `just serve` workflow SHALL complete full project setup in a separate process before starting the watcher. After setup succeeds, the watcher SHALL launch the existing `serve` Mix alias for every initial or replacement interactive IEx/Phoenix child.

#### Scenario: Developer starts the server

- **WHEN** a developer runs `just serve`
- **THEN** full setup completes before the watcher starts
- **AND** the watcher launches an interactive child through `mix serve`
- **AND** the child starts a listening Phoenix endpoint

#### Scenario: Watched input changes after startup

- **WHEN** a supported environment or configuration input changes while the server is running
- **THEN** the workflow replaces the interactive child through `mix serve`
- **AND** full setup does not run again for that replacement

## ADDED Requirements

### Requirement: Development server aliases start Phoenix without setup

The `serve` Mix alias SHALL delegate directly to `phx.server`, and the backward-compatible `start` Mix alias SHALL delegate to `serve`. Direct server aliases MUST NOT automatically run dependency resolution, database setup, migrations, seeds, asset installation, or a production asset build.

#### Scenario: Direct serve alias is used

- **WHEN** a developer runs `mix serve`
- **THEN** Mix starts Phoenix through `phx.server`
- **AND** full setup does not run first

#### Scenario: Legacy start alias is used

- **WHEN** a developer runs `mix start`
- **THEN** Mix delegates to `serve`
- **AND** Phoenix starts without running full setup first

### Requirement: Initial setup remains deliberate and failure-gated

The `just serve` workflow SHALL run the complete `setup` alias once before starting the watcher. A setup failure MUST prevent the watcher and Phoenix child from starting. Watched replacements MUST NOT apply pending migrations or repeat dependency, seed, or asset preparation.

#### Scenario: Initial setup succeeds

- **WHEN** a developer runs `just serve` with a valid development environment
- **THEN** dependency resolution, database setup, seeds, asset setup, and asset build complete before the watcher starts

#### Scenario: Initial setup fails

- **WHEN** `mix setup` exits unsuccessfully during `just serve`
- **THEN** the watcher and Phoenix child do not start

#### Scenario: Migration file changes without another watched event

- **WHEN** a migration becomes pending while no path under `envs/` or `config/` changes
- **THEN** the running watcher does not apply that migration

#### Scenario: Watched replacement finds a pending migration

- **WHEN** an environment or configuration event replaces the child while a migration is pending
- **THEN** the replacement starts Phoenix without applying that migration

#### Scenario: Pending migration is applied deliberately

- **WHEN** a developer runs `mix ecto.migrate`, `mix setup`, or a new top-level `just serve` invocation with a pending migration
- **THEN** the selected setup or migration command applies the migration

## REMOVED Requirements

### Requirement: Development server alias owns full setup

**Reason**: Running setup and `phx.server` in one Erlang VM starts D20 during seeds before endpoint serving is enabled, so the resulting development process has no Bandit listener.

**Migration**: Run full setup as a separate `mix setup` process before the watcher, and restore `serve` as a direct `phx.server` alias.
