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

The `serve` workflow SHALL complete project setup before starting the watched interactive IEx/Phoenix process, and setup MUST run only once per explicit workflow invocation.

#### Scenario: Developer starts the server

- **WHEN** a developer runs `just serve`
- **THEN** the workflow runs `mix setup` before starting the watched IEx/Phoenix process

#### Scenario: Watched input changes after startup

- **WHEN** a supported configuration input changes while the server is running
- **THEN** the workflow replaces the IEx/Phoenix process without rerunning `mix setup`

### Requirement: Startup configuration inputs trigger replacement

The `serve` workflow SHALL replace the running development process when `envs/.env`, `config/config.exs`, `config/runtime.exs`, or the configuration file for the active `MIX_ENV` changes. The active environment SHALL default to `dev` when `MIX_ENV` is unset.

#### Scenario: Dotenv values change

- **WHEN** `envs/.env` is created, modified, replaced, or removed while the development server is running
- **THEN** the running development process is replaced

#### Scenario: Shared configuration changes

- **WHEN** `config/config.exs` changes while the development server is running
- **THEN** the running development process is replaced

#### Scenario: Runtime configuration changes

- **WHEN** `config/runtime.exs` changes while the development server is running
- **THEN** the running development process is replaced

#### Scenario: Default development configuration changes

- **WHEN** `MIX_ENV` is unset and `config/dev.exs` changes while the development server is running
- **THEN** the running development process is replaced

#### Scenario: Explicit test configuration changes

- **WHEN** the server workflow was started with `MIX_ENV=test` and `config/test.exs` changes
- **THEN** the running development process is replaced

#### Scenario: Inactive environment configuration changes

- **WHEN** an environment-specific configuration file other than the active `MIX_ENV` file changes
- **THEN** the running development process is not replaced

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

The `up` workflow SHALL continue to start Docker Compose routing before invoking `serve`, and the resulting development server SHALL use the same watched restart behavior.

#### Scenario: Developer starts the routed workflow

- **WHEN** a developer runs `just up`
- **THEN** Docker Compose services start before the watched `serve` workflow

### Requirement: Automatic restart scope is development-only

The automatic watcher SHALL NOT change production release startup, persistence contracts, public routes, session protocols, or iframe module contracts.

#### Scenario: Production artifacts are built

- **WHEN** the application production image or release is built
- **THEN** the development watcher is not introduced into the production runtime command
