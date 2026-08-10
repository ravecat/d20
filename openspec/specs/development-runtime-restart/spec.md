# development-runtime-restart Specification

## Purpose
TBD - created by archiving change restart-dev-server-on-config-change. Update Purpose after archive.
## Requirements
### Requirement: Reproducible watcher tooling

The project development shell SHALL provide the environment loader and file watcher required by the automatic development restart workflow.

#### Scenario: Developer enters the Nix environment

- **WHEN** a developer enters the repository development shell
- **THEN** both `direnv` and `watchexec` are available without an additional global installation

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

### Requirement: Replacement process receives current environment

Every initial or replacement development process SHALL start through the authorized repository direnv environment so it receives the current `.envrc`, Nix shell, and optional dotenv values.

#### Scenario: Existing dotenv value changes

- **WHEN** a dotenv value changes and the watcher replaces the development process
- **THEN** the replacement process receives the new value instead of the watcher's original value

#### Scenario: Dotenv value is removed

- **WHEN** a dotenv value is removed and the watcher replaces the development process
- **THEN** the removed value is not retained solely from the previous process environment

### Requirement: Interactive IEx remains usable

The watched development process MUST retain terminal input and preserve each supplied node-name and Erlang emulator argument boundary.

#### Scenario: Developer evaluates an expression

- **WHEN** the watched server reaches the IEx prompt and the developer enters an Elixir expression
- **THEN** IEx evaluates the expression and prints its result

#### Scenario: Erlang emulator arguments contain spaces

- **WHEN** the `serve` workflow supplies an Erlang emulator option string containing spaces
- **THEN** the replacement process receives that option string as one argument

#### Scenario: Developer overrides the node name

- **WHEN** the developer supplies a `serve` node-name option
- **THEN** the watched IEx process uses the supplied short node name

### Requirement: Routed development startup inherits restart behavior

The `up` workflow SHALL start Docker Compose routing before delegating to the private reuse-or-start decision, and the resulting new or reused development server SHALL use the same watched restart behavior.

#### Scenario: Developer starts the routed workflow

- **WHEN** a developer runs `just up`
- **THEN** Docker Compose services start before the workflow decides whether to restart the existing watcher or invoke `serve`

### Requirement: Routed startup reuses the existing default watcher

After Docker Compose routing starts, the `up` workflow SHALL check whether EPMD lists the exact local `d20` short node name. When that node is registered, the workflow SHALL update the active environment configuration file already watched by the development restart workflow and MUST NOT start a second `serve` workflow. When that node is not registered, the workflow SHALL invoke `serve` normally.

#### Scenario: No existing default node is registered

- **WHEN** a developer runs `just up` and EPMD does not list the exact `d20` short node name
- **THEN** the workflow invokes the watched `serve` workflow after Docker Compose routing starts

#### Scenario: Existing default node is registered

- **WHEN** a developer runs `just up` and EPMD lists the exact `d20` short node name
- **THEN** the workflow updates the active environment configuration file to trigger the existing watcher
- **AND** it does not invoke another `serve` workflow

#### Scenario: Similar node name is registered

- **WHEN** EPMD lists a node such as `d20_test` but does not list the exact `d20` short node name
- **THEN** the workflow treats the default node as absent and invokes `serve`

#### Scenario: Default development environment is active

- **WHEN** the existing `d20` node is registered and `MIX_ENV` is unset
- **THEN** the workflow updates `config/dev.exs`

#### Scenario: Explicit development environment is active

- **WHEN** the existing `d20` node is registered and `MIX_ENV` names another environment
- **THEN** the workflow updates the matching `config/<MIX_ENV>.exs` file

### Requirement: Restart decision remains private to routed startup

The reuse-or-start decision SHALL be implemented as a private project helper and MUST NOT add another public root command to the Just recipe listing.

#### Scenario: Developer lists project commands

- **WHEN** a developer runs `just --list`
- **THEN** the private reuse-or-start helper is absent from the listed public recipes

### Requirement: Automatic restart scope is development-only

The automatic watcher SHALL NOT change production release startup, persistence contracts, public routes, session protocols, or iframe module contracts.

#### Scenario: Production artifacts are built

- **WHEN** the application production image or release is built
- **THEN** the development watcher is not introduced into the production runtime command
