## ADDED Requirements

### Requirement: Worktrees share the default Compose router project

The root Compose file SHALL declare `d20` as its default project name so native Compose commands and `just up` address the same local Traefik project regardless of checkout directory. The existing host port 80, Traefik configuration, and shared `d20` network SHALL remain unchanged.

#### Scenario: Project name resolves from different checkout directories

- **WHEN** a developer resolves the Compose configuration from the primary checkout or a differently named linked worktree without an explicit project-name override
- **THEN** the resolved project name is `d20`

#### Scenario: Another worktree repeats router startup

- **WHEN** the shared router is running and another worktree starts Compose with the same service configuration and image without an explicit project-name override
- **THEN** Compose reuses the existing `d20` router instead of creating a directory-named router that competes for port 80

### Requirement: Shared router lifecycle is documented

Local development documentation SHALL describe the effects of stopping or reconfiguring the shared router, handling an old directory-named router occupying port 80, and the distinction between sharing Traefik and running independent application instances.

#### Scenario: A developer stops or reconfigures the shared router

- **WHEN** a developer reads the local module workflow
- **THEN** it explains that `docker compose down` from any participating checkout stops the router for all worktrees and changed service configuration can recreate that shared router

#### Scenario: An old worktree router still owns the port

- **WHEN** a developer encounters a directory-named router occupying port 80 after adopting the default project name
- **THEN** documentation directs them to identify and stop that exact old container before starting the shared project

#### Scenario: A developer needs concurrent application instances

- **WHEN** a developer reads the worktree guidance
- **THEN** it explains that the shared project name does not serialize simultaneous Compose operations or isolate Phoenix node names and application ports
