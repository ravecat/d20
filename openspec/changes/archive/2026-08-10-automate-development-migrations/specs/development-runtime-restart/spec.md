## MODIFIED Requirements

### Requirement: Initial development startup order

The `just serve` workflow SHALL have the watcher launch the existing `serve` Mix alias for every initial or replacement interactive IEx/Phoenix child. Each child SHALL complete full project setup before starting Phoenix, and the Just recipe MUST NOT duplicate setup outside that alias.

#### Scenario: Developer starts the server

- **WHEN** a developer runs `just serve`
- **THEN** the watcher launches an interactive child through `mix serve`
- **AND** full setup completes before Phoenix starts

#### Scenario: Watched input changes after startup

- **WHEN** a supported environment or configuration input changes while the server is running
- **THEN** the workflow replaces the interactive child through `mix serve`
- **AND** full setup runs again before replacement Phoenix starts

### Requirement: Startup configuration inputs trigger replacement

The `serve` workflow SHALL replace the running development process when any file or directory within `envs/` or `config/` is created, modified, replaced, renamed, or removed. The watcher MUST observe both directories recursively without requiring a per-file allowlist, MUST include paths ignored by repository ignore files, and MUST NOT observe `priv/repo/migrations/`.

#### Scenario: Environment directory content changes

- **WHEN** any path within `envs/` is created, modified, replaced, renamed, or removed while the development server is running
- **THEN** the running development process is replaced

#### Scenario: Configuration directory content changes

- **WHEN** any path within `config/` is created, modified, replaced, renamed, or removed while the development server is running
- **THEN** the running development process is replaced

#### Scenario: Migration directory content changes

- **WHEN** any path within `priv/repo/migrations/` is created, modified, replaced, renamed, or removed while the development server is running
- **THEN** that change alone does not cause the watcher to replace the development process or execute the migration

#### Scenario: Inactive environment configuration changes

- **WHEN** an environment-specific configuration file other than the active `MIX_ENV` file changes within `config/`
- **THEN** the running development process is replaced

#### Scenario: Future configuration input is added

- **WHEN** a new file is added anywhere within `envs/` or `config/`
- **THEN** the running development process is replaced without adding another watcher filter

#### Scenario: Ignored configuration path changes

- **WHEN** a repository ignore rule matches a changed path within `envs/` or `config/`
- **THEN** the running development process is replaced

#### Scenario: Path outside configuration directories changes

- **WHEN** a path outside `envs/` and `config/` changes without another watched event
- **THEN** that change does not cause this watcher to replace the development process

## ADDED Requirements

### Requirement: Development server alias owns full setup

The `serve` Mix alias SHALL run the complete `setup` alias before `phx.server`, and the backward-compatible `start` Mix alias SHALL delegate to `serve`. A setup failure MUST prevent Phoenix from starting for that direct or watched launch.

#### Scenario: Direct serve alias is used

- **WHEN** a developer runs `mix serve`
- **THEN** Mix completes dependency resolution, database setup, seeds, asset setup, and asset build before starting Phoenix

#### Scenario: Legacy start alias is used

- **WHEN** a developer runs `mix start`
- **THEN** Mix delegates to `serve`
- **AND** full setup completes before Phoenix starts

#### Scenario: Watched launch setup fails

- **WHEN** `mix setup` exits unsuccessfully during an initial or replacement child launched by `just serve`
- **THEN** Phoenix does not start for that child

#### Scenario: Migration file changes without another watched event

- **WHEN** a migration becomes pending while no path under `envs/` or `config/` changes
- **THEN** the running watcher does not apply that migration

#### Scenario: Watched replacement finds a pending migration

- **WHEN** an environment or configuration event replaces the child while a migration is pending
- **THEN** the replacement `mix serve` setup applies the migration before starting Phoenix

#### Scenario: Pending migration is applied through a direct command

- **WHEN** a developer runs `just serve`, `mix serve`, `mix start`, or `mix ecto.migrate` with a pending migration
- **THEN** the selected command applies that migration before any requested Phoenix server starts
