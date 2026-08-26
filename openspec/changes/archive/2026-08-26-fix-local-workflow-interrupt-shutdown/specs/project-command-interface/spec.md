## MODIFIED Requirements

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

### Requirement: Composite workflows retain their behavior

The root `justfile` SHALL retain `serve`, `up`, `format`, and `check` as named composite workflows, and each workflow MUST preserve its specified action order and command semantics without depending on a removed recipe.

#### Scenario: Development server workflow runs

- **WHEN** a developer runs `just serve` with optional node name and Erlang distribution arguments and the exact requested node name is not registered with EPMD
- **THEN** the workflow delegates to the private `start` helper
- **AND** runs `mix setup` before starting Watchexec and IEx with the Phoenix `serve` Mix alias and the supplied or existing default values
- **AND** it does not start Storybook

#### Scenario: Dependency or migration inputs change

- **WHEN** a developer changes `mix.exs`, `mix.lock`, or a file under `priv/repo/migrations/`
- **THEN** the watcher does not run dependency installation, full setup, or migrations automatically
- **AND** the developer runs `mix deps.get` or `mix ecto.migrate` explicitly as applicable
- **AND** can invoke `just serve` to restart the existing watched runtime afterward

#### Scenario: Existing watched server is requested again

- **WHEN** a developer runs `just serve` and EPMD reports the exact requested short node name
- **THEN** the workflow touches the active environment configuration file so the existing Watchexec owner restarts IEx/Phoenix
- **AND** it does not run setup or attempt to start a duplicate node
- **AND** it does not force-stop or unregister the existing node

#### Scenario: A partial or different node name is registered

- **WHEN** EPMD reports node names that do not exactly equal the requested short node name
- **THEN** `just serve` follows the initial-start path for the requested name

#### Scenario: Routed development workflow runs

- **WHEN** a developer runs `just up`
- **THEN** the workflow starts detached Docker Compose services before invoking `serve`
- **AND** does not invoke Concurrently or Storybook

#### Scenario: Routed development workflow starts a missing node

- **WHEN** `just up` invokes `serve` and the requested node is not registered
- **THEN** the workflow remains attached to the interactive application workflow

#### Scenario: Routed development workflow reuses an existing node

- **WHEN** `just up` invokes `serve` and the exact requested node is registered
- **THEN** the workflow triggers its Watchexec restart and returns without starting a duplicate foreground process

#### Scenario: Formatting workflow runs

- **WHEN** a developer runs `just format`
- **THEN** the workflow runs backend formatting before frontend asset formatting

#### Scenario: Validation workflow runs

- **WHEN** a developer runs `just check`
- **THEN** the workflow checks formatting, asset linting, asset tests, frontend types, Storybook, and backend tests in the existing order
- **AND** the workflow does not check generated agent-skill metadata
