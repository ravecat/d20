## ADDED Requirements

### Requirement: Explicit startup transfers exact short-name ownership

Every explicit `just serve` invocation SHALL force-stop only the local BEAM command carrying the requested default or explicit `-sname`, then start a fresh watched IEx/Phoenix runtime in the invoking terminal. Partial and different short names MUST remain untouched.

#### Scenario: Default node is already running

- **WHEN** a developer runs `just serve` while a BEAM with `-sname d20` exists
- **THEN** the workflow force-stops that BEAM
- **AND** starts a fresh watched `d20` runtime in the invoking terminal

#### Scenario: Explicit custom node is already running

- **WHEN** a developer runs `just serve --sname d20_custom` while a BEAM with `-sname d20_custom` exists
- **THEN** the workflow replaces that BEAM independently from `d20`

#### Scenario: Matching node was started directly

- **WHEN** a developer or agent directly started a BEAM with the requested `-sname`
- **THEN** a later `just serve` replaces it without requiring its cookie or original terminal

#### Scenario: Similar node remains active

- **WHEN** `d20_test` is active and the developer requests `d20`
- **THEN** the workflow does not stop `d20_test`

### Requirement: Revised watcher releases ownership after takeover

Watchexec processes started by the revised workflow SHALL exit when their matching IEx/Phoenix child is force-stopped, so the previous terminal cannot reclaim the node later.

#### Scenario: Repeated startup replaces a watched runtime

- **WHEN** repeated startup force-stops a child started by the revised workflow
- **THEN** its Watchexec owner exits

#### Scenario: Developer uses a watcher from the older workflow

- **WHEN** a watcher was started before the revised exit behavior existed
- **THEN** the migration documentation requires that watcher to be stopped manually once

### Requirement: Latest invocation owns the interactive runtime

After takeover, the new Watchexec and IEx/Phoenix process tree SHALL remain attached to the terminal that invoked the latest `just serve` or `just up` command.

#### Scenario: Developer uses IEx after takeover

- **WHEN** repeated startup completes and the developer enters an Elixir expression
- **THEN** the replacement IEx evaluates it in the latest terminal

#### Scenario: Developer stops the replacement

- **WHEN** the developer follows the documented interactive shutdown sequence
- **THEN** the replacement watcher and child exit

## MODIFIED Requirements

### Requirement: Reproducible watcher tooling

The project development shell SHALL provide `direnv`, Watchexec, and `pkill` for the automatic restart and repeated-start takeover workflow on supported Linux and macOS hosts.

#### Scenario: Developer enters the Nix environment

- **WHEN** a developer enters the repository development shell
- **THEN** `direnv`, `watchexec`, and `pkill` are available without global installation

### Requirement: Initial development startup order

The `just serve` workflow SHALL complete full project setup before force-stopping a matching short-name BEAM and launching `mix serve` through Watchexec.

#### Scenario: Developer starts an absent server

- **WHEN** no BEAM carries the requested `-sname`
- **THEN** full setup completes before Watchexec starts its interactive child

#### Scenario: Developer replaces an existing server

- **WHEN** a BEAM carries the requested `-sname`
- **THEN** full setup completes before that BEAM is force-stopped
- **AND** a fresh watcher starts afterward

### Requirement: Mix dependency manifests trigger watched replacement

The `serve` workflow SHALL observe `mix.exs` and `mix.lock` alongside `envs/` and `config/`. A manifest change SHALL replace the watched IEx/Phoenix child without running full setup, dependency installation, or migrations automatically.

#### Scenario: Mix manifest changes

- **WHEN** `mix.exs` or `mix.lock` changes while the server is running
- **THEN** Watchexec replaces its child without repeating setup

#### Scenario: Migration changes

- **WHEN** a file under `priv/repo/migrations/` changes without another watched event
- **THEN** the watcher does not restart the runtime or apply the migration

### Requirement: Routed development startup inherits restart behavior

The `up` workflow SHALL start Docker Compose before invoking `serve`, and SHALL use the same exact short-name takeover and latest-terminal ownership behavior.

#### Scenario: Developer runs routed startup

- **WHEN** a developer runs `just up`
- **THEN** Docker Compose starts before `serve`
- **AND** the fresh watched runtime remains attached to the invoking terminal

## REMOVED Requirements

### Requirement: Routed startup reuses the existing default watcher

### Requirement: Restart decision remains private to routed startup
