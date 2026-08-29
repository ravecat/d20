# development-runtime-restart Specification

## Purpose
TBD - created by archiving change restart-dev-server-on-config-change. Update Purpose after archive.
## Requirements
### Requirement: Reproducible watcher tooling

The project development shell SHALL provide the environment loader, file watcher, and process matcher required by the automatic development restart and repeated-start takeover workflows.

#### Scenario: Developer enters the Nix environment

- **WHEN** a developer enters the repository development shell
- **THEN** `direnv`, `watchexec`, and `pkill` are available without an additional global installation

### Requirement: Initial development startup order

The `just serve` workflow SHALL complete full project setup before force-stopping a BEAM with the requested short node name and launching the existing `serve` Mix alias through Watchexec.

#### Scenario: Developer starts an absent server

- **WHEN** a developer runs `just serve` and no BEAM carries the requested `-sname`
- **THEN** full setup completes before Watchexec starts
- **AND** Watchexec launches an interactive child through `mix serve`

#### Scenario: Developer replaces an existing server

- **WHEN** a developer runs `just serve` and a BEAM carries the requested `-sname`
- **THEN** full setup completes before that BEAM is force-stopped
- **AND** a fresh watcher starts afterward

#### Scenario: Watched input changes after startup

- **WHEN** a supported environment or configuration input changes while the server is running
- **THEN** the owning watcher replaces its interactive child through `mix serve`
- **AND** full setup does not run again for that configuration-driven replacement

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

The `just serve` workflow SHALL run the complete `setup` alias once before exact-node takeover and watcher startup. A setup failure MUST leave an existing node and watcher untouched and MUST prevent a replacement from starting. Watched replacements MUST NOT apply pending migrations or repeat dependency, seed, or asset preparation.

#### Scenario: Initial setup succeeds

- **WHEN** a developer runs `just serve` with a valid development environment
- **THEN** dependency resolution, database setup, seeds, asset setup, and asset build complete before takeover and watcher startup

#### Scenario: Initial setup fails without an existing runtime

- **WHEN** `mix setup` exits unsuccessfully during `just serve` and the requested node is absent
- **THEN** the watcher and Phoenix child do not start

#### Scenario: Initial setup fails with an existing runtime

- **WHEN** `mix setup` exits unsuccessfully and the exact requested node is already running
- **THEN** the workflow does not request shutdown of that node
- **AND** does not start a replacement watcher

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

- **WHEN** a path outside `envs/`, `config/`, `mix.exs`, and `mix.lock` changes without another watched event
- **THEN** that change does not cause this watcher to replace the development process

### Requirement: Mix dependency manifests trigger watched replacement

The `serve` workflow SHALL observe `mix.exs` and `mix.lock` alongside the existing environment and configuration watch roots. A manifest change SHALL replace the watched IEx/Phoenix child without running full setup, dependency installation, or migrations automatically.

#### Scenario: Mix project manifest changes

- **WHEN** `mix.exs` changes while the development server is running
- **THEN** Watchexec replaces the running IEx/Phoenix child
- **AND** does not repeat full setup or dependency installation

#### Scenario: Mix lockfile changes

- **WHEN** `mix.lock` changes while the development server is running
- **THEN** Watchexec replaces the running IEx/Phoenix child
- **AND** does not repeat full setup or dependency installation

#### Scenario: Migration changes

- **WHEN** a file under `priv/repo/migrations/` changes without another watched event
- **THEN** the watcher does not restart the runtime or apply the migration automatically

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

### Requirement: Explicit startup transfers exact short-name ownership

Every explicit `just serve` invocation SHALL force-stop only the local BEAM command carrying the requested default or explicit `-sname`, then start a fresh watched IEx/Phoenix runtime in the invoking terminal. Partial and different short names MUST remain untouched.

#### Scenario: Default node is already running

- **WHEN** a developer runs `just serve` while a BEAM with `-sname d20` exists
- **THEN** the workflow force-stops that BEAM
- **AND** starts a fresh watched `d20` runtime in the invoking terminal

#### Scenario: Explicit custom node is already running

- **WHEN** a developer runs `just serve --sname d20_custom` while a BEAM with `-sname d20_custom` exists
- **THEN** the workflow replaces that BEAM independently from `d20`
- **AND** starts the fresh `d20_custom` runtime in the invoking terminal

#### Scenario: Matching node was started directly

- **WHEN** a developer or agent directly started a BEAM with the requested `-sname`
- **THEN** a later `just serve` replaces it without requiring its cookie or original terminal

#### Scenario: Similar node remains active

- **WHEN** `d20_test` is active and the developer requests `d20`
- **THEN** the workflow does not stop `d20_test`

### Requirement: Revised watcher releases ownership after explicit takeover

Watchexec processes started by the revised workflow SHALL exit when their matching IEx/Phoenix child is force-stopped, so the previous terminal cannot reclaim the node later.

#### Scenario: Repeated startup replaces a revised watcher

- **WHEN** repeated startup force-stops a child started by the revised workflow
- **THEN** its Watchexec owner exits

#### Scenario: Developer uses a watcher from the older workflow

- **WHEN** a watcher was started before the revised nonzero-child exit behavior existed
- **THEN** the migration documentation requires that watcher to be stopped manually once

### Requirement: Latest invocation owns the interactive runtime

After successful exact-name takeover, the new Watchexec and IEx/Phoenix process tree SHALL remain attached to the terminal that invoked the latest `just serve` or `just up` command.

#### Scenario: Developer evaluates an expression after takeover

- **WHEN** repeated startup completes and the developer enters an Elixir expression in the latest terminal
- **THEN** the replacement IEx process evaluates the expression and prints its result there

#### Scenario: Developer stops the replacement

- **WHEN** the developer follows the documented interactive shutdown sequence in the latest terminal
- **THEN** the replacement watcher and IEx/Phoenix child exit with that foreground workflow

### Requirement: Routed development startup inherits restart behavior

The `up` workflow SHALL start Docker Compose routing before invoking `serve`, and the resulting development server SHALL use the same exact short-name takeover and latest-terminal ownership behavior as direct `serve`.

#### Scenario: Developer starts the routed workflow with no matching node

- **WHEN** a developer runs `just up` and the requested short node name is absent
- **THEN** Docker Compose services start before setup and the foreground watched server

#### Scenario: Developer starts the routed workflow with a matching node

- **WHEN** a developer runs `just up` and the exact requested short node name is present
- **THEN** Docker Compose services start before `serve` replaces that node
- **AND** the new watched runtime remains attached to the invoking terminal

### Requirement: Automatic restart scope is development-only

The automatic watcher SHALL NOT change production release startup, persistence contracts, public routes, session protocols, or iframe module contracts.

#### Scenario: Production artifacts are built

- **WHEN** the application production image or release is built
- **THEN** the development watcher is not introduced into the production runtime command
