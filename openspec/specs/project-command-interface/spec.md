# project-command-interface Specification

## Purpose
TBD - created by archiving change streamline-just-recipes. Update Purpose after archive.
## Requirements
### Requirement: Mix command dispatcher

The project SHALL expose a `mix` recipe that accepts one or more trailing arguments, runs Mix from the repository root, preserves each argument boundary, and returns the Mix command exit status without an additional `just` failure message.

#### Scenario: Dotted Mix task is dispatched

- **WHEN** a developer runs `just mix ecto.migrate`
- **THEN** the project runs `mix ecto.migrate` from the repository root

#### Scenario: Mix task receives additional arguments

- **WHEN** a developer supplies a Mix task followed by flags or positional values to `just mix`
- **THEN** every supplied value is forwarded to Mix as a distinct argument in its original order

#### Scenario: Mix task fails

- **WHEN** the dispatched Mix command exits unsuccessfully
- **THEN** `just mix` exits unsuccessfully with the same command result and without a redundant recipe failure footer

### Requirement: Asset script dispatcher

The project SHALL expose an `assets` recipe that accepts one or more trailing arguments, runs the named package script through Bun from the `assets/` directory, preserves each argument boundary, and returns the Bun command exit status without an additional `just` failure message.

#### Scenario: Asset package script is dispatched

- **WHEN** a developer runs `just assets browsers`
- **THEN** the project runs `bun run browsers` from the `assets/` directory

#### Scenario: Asset script receives additional arguments

- **WHEN** a developer supplies a package script followed by flags or positional values to `just assets`
- **THEN** every supplied value is forwarded to Bun as a distinct argument in its original order

#### Scenario: Asset script fails

- **WHEN** the dispatched Bun script exits unsuccessfully
- **THEN** `just assets` exits unsuccessfully with the same command result and without a redundant recipe failure footer

### Requirement: Named recipes represent project composition

Every named root recipe other than the default discovery recipe, the `mix` and `assets` dispatchers, and the supported `storybook` entry point MUST coordinate at least two meaningful project actions. The project SHALL NOT add or retain another named recipe whose only behavior is invoking one Mix task, Bun script, Docker command, or other native command.

#### Scenario: Native task requires no project orchestration

- **WHEN** a developer needs to run a single native task such as type checking
- **THEN** the documented interface uses the native command or a generic dispatcher instead of a dedicated `typecheck` recipe

#### Scenario: Storybook entry point is requested

- **WHEN** a developer runs `just storybook` with optional Storybook CLI arguments
- **THEN** the workflow invokes the atomic frontend Storybook command
- **AND** preserves every optional argument boundary
- **AND** does not start Docker Compose or Phoenix

#### Scenario: New recipe is proposed

- **WHEN** a new named root recipe other than `storybook` is added
- **THEN** its implementation visibly composes at least two meaningful actions unless it is the default discovery recipe or one of the two generic dispatchers

### Requirement: Single-action recipes are absent

The root `justfile` MUST NOT define the former `setup`, `start`, `down`, `test`, `build`, `typecheck`, `agent-skills-sync`, `agent-skills-check`, `db-create`, `db-migrate`, or `db-reset` recipes. Documentation SHALL direct developers to the corresponding native commands or generic dispatchers.

#### Scenario: Removed Mix wrapper is requested

- **WHEN** a developer inspects the root recipe list
- **THEN** `typecheck` and the other removed single-action wrappers are absent
- **AND** `mix typecheck` and `just mix typecheck` remain documented alternatives

#### Scenario: Removed Docker wrapper is needed

- **WHEN** a developer needs only to stop the local Docker Compose services
- **THEN** documentation directs them to `docker compose down` instead of a `just down` recipe

### Requirement: Composite workflows retain their behavior

The root `justfile` SHALL retain `serve`, `up`, `format`, and `check` as named composite workflows, and each workflow MUST preserve its specified action order and command semantics without depending on a removed public recipe or a repository process-management script.

#### Scenario: Development server workflow starts an absent node

- **WHEN** a developer runs `just serve` and no BEAM carries the requested `-sname`
- **THEN** the workflow runs `mix setup` before starting Watchexec and IEx with the supplied or default values
- **AND** remains attached to the interactive application workflow
- **AND** does not start Storybook

#### Scenario: Existing default server is requested again

- **WHEN** a developer runs `just serve` and a BEAM carries `-sname d20`
- **THEN** the workflow runs setup before force-stopping that BEAM
- **AND** starts a new watched `d20` runtime in the invoking terminal

#### Scenario: Existing explicit server is requested again

- **WHEN** a developer runs `just serve --sname d20_custom`
- **THEN** the workflow replaces only the BEAM carrying `-sname d20_custom`
- **AND** starts the new watched runtime in the invoking terminal with supplied Erlang arguments preserved

#### Scenario: Existing direct server is requested again

- **WHEN** the requested `-sname` belongs to a directly started local BEAM without Watchexec
- **THEN** `serve` force-stops that BEAM without requiring its cookie or original terminal

#### Scenario: Mix dependency manifest changes

- **WHEN** `mix.exs` or `mix.lock` changes while the watched runtime is active
- **THEN** Watchexec replaces its IEx/Phoenix child
- **AND** does not run dependency installation, full setup, or migrations automatically

#### Scenario: A partial or different node name is running

- **WHEN** a BEAM carries `-sname d20_test` and the developer requests `d20`
- **THEN** `d20_test` remains running

#### Scenario: Routed development workflow runs

- **WHEN** a developer runs `just up`
- **THEN** the workflow starts detached Docker Compose services before invoking `serve`
- **AND** does not invoke Concurrently or Storybook

#### Scenario: Routed development workflow starts a missing node

- **WHEN** `just up` invokes `serve` and no BEAM carries the requested `-sname`
- **THEN** the workflow remains attached to the new interactive application workflow

#### Scenario: Routed development workflow replaces an existing node

- **WHEN** `just up` invokes `serve` and a BEAM carries the requested `-sname`
- **THEN** the workflow uses the same exact short-name takeover as direct `serve`
- **AND** remains attached to the replacement in the invoking terminal

#### Scenario: Formatting workflow runs

- **WHEN** a developer runs `just format`
- **THEN** the workflow runs backend formatting before frontend asset formatting

#### Scenario: Validation workflow runs

- **WHEN** a developer runs `just check`
- **THEN** the workflow checks formatting, OpenSpec lifecycle, asset formatting, asset linting, asset tests, frontend types, Storybook, and backend tests in the existing order
- **AND** the workflow does not check generated agent-skill metadata

### Requirement: Default command discovery remains available

Invoking `just` without a recipe SHALL list the available root recipes after the command surface is reduced.

#### Scenario: Developer requests the default action

- **WHEN** a developer runs `just` without arguments
- **THEN** the output lists the retained workflows and generic dispatchers
- **AND** the output does not list removed single-action recipes
