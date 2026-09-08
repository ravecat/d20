## Context

The root Compose file runs only Traefik, publishing host port 80 and joining the explicitly named `d20` network used by independently started game modules. Without an explicit project name, checkout directory names produce separate router containers competing for that port. The issue was observed with `home-game-discovery-carousel-traefik-1` and `d20-traefik-1`.

## Goals / Non-Goals

**Goals:** Select the same default router project from every D20 worktree and explain shared operational ownership.

**Non-Goals:** Isolate multiple Phoenix/Vite/database instances, serialize concurrent Compose commands, change ports or module hostnames, or manage unrelated containers automatically.

## Decisions

Add top-level `name: d20` to `compose.yaml`. This applies to native Compose commands as well as `just up`, unlike a project flag in one recipe or a required shell environment variable. Retain the existing service, network, and port definitions. Docker's explicit `-p` and `COMPOSE_PROJECT_NAME` overrides still take precedence; separate project names do not isolate the fixed host port.

Document in README that worktrees share the router: repeated startup with identical service configuration and image reuses it, changed configuration can recreate it, and `down` stops routing for all worktrees. Also record existing Phoenix short-name takeover and port constraints so a shared proxy is not confused with independent application instances.

Use `docker compose config --quiet` and parsed configuration from differently named project directories to verify the default and unchanged service/network model. Check repeated real startup against the existing `d20` container by comparing its ID before and after, then request the existing Koala Rescue Club HTTP route. No new automated test harness is needed for a declarative setting.

## Risks / Trade-offs

- Shared stop or reconfiguration affects every worktree. Document the shared ownership and avoid stopping the router during validation.
- Existing directory-named routers are not adopted by the new project name. Identify the old port-80 container and stop that exact container once before starting the shared project; preserve the shared network and unrelated game containers.
- Simultaneous first creation or conflicting configuration updates can race. A shared project name is not a startup lock; concurrent orchestration remains outside this change.
- Worktrees lacking this commit retain directory-derived names. Each participating checkout must receive the change or use an explicit `d20` project override.

## Migration Plan

No application migration or production deployment is required. Add the default name, stop any identified old worktree router occupying port 80, and run the existing Compose startup. The current environment already uses the canonical `d20-traefik-1` after the incident recovery.

Rollback removes the top-level name and its documentation. Stop the shared router before intentionally returning to a directory-named project; the network and module contracts do not change.

## Open Questions

None.
