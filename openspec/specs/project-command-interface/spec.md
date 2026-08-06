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

Every named root recipe other than the default discovery recipe and the `mix` and `assets` dispatchers MUST coordinate at least two meaningful project actions. The project SHALL NOT add or retain a named recipe whose only behavior is invoking one Mix task, Bun script, Docker command, or other native command.

#### Scenario: Native task requires no project orchestration

- **WHEN** a developer needs to run a single native task such as type checking
- **THEN** the documented interface uses the native command or a generic dispatcher instead of a dedicated `typecheck` recipe

#### Scenario: New recipe is proposed

- **WHEN** a new named root recipe is added
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

### Requirement: Default command discovery remains available

Invoking `just` without a recipe SHALL list the available root recipes after the command surface is reduced.

#### Scenario: Developer requests the default action

- **WHEN** a developer runs `just` without arguments
- **THEN** the output lists the retained workflows and generic dispatchers
- **AND** the output does not list removed single-action recipes
