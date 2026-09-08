## Why

Switching D20 worktrees creates differently named Compose projects whose Traefik containers compete for host port 80, preventing `just up` from reaching Phoenix startup. The local module workflow already uses one shared router and Docker network.

Tracking issue: https://github.com/ravecat/d20/issues/269

## What Changes

- Declare `d20` as the default project name in `compose.yaml`, independent of checkout directory.
- Document shared router ownership, old worktree-container cleanup, and the limits of concurrent application startup.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `project-command-interface`: Use one default Compose project across D20 worktrees and document shared lifecycle effects.

## Impact

Changes affect `compose.yaml`, local development documentation, and the command-interface specification. Phoenix startup, Vite, databases, game module contracts, ports, networks, and dependencies remain unchanged. No migration or deployment is required. Rollback removes the explicit name and requires stopping the shared router before returning to directory-derived worktree projects.
