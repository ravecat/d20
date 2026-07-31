## Why

The game page and Lobby component currently duplicate transient visibility state when a waiting session starts. Rendering from the authoritative Inertia `session` prop removes that split ownership and keeps the lobby stable until navigation returns the clean game page.

## What Changes

- Render Lobby directly from the game page `session` prop.
- Keep Lobby mounted while its canonical-URL Inertia navigation is pending.
- Remove the parent dismissal marker, derived lobby session, callback prop, and child visibility flag.
- Detach the Lobby Session store through normal component cleanup after the navigation response removes the session descriptor.
- Preserve session creation, channel commands, workspace discovery, routes, and public protocol contracts.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `session-workspace-lifecycle`: Make the server-provided page session descriptor the source of Lobby presence during the transition to an in-progress or finished session.
- `multi-session-game-workspace`: Remove the obsolete Presence-lease handoff requirement and align Lobby cleanup with authoritative page navigation.

## Impact

- Affected frontend code: `assets/js/pages/game/ui/game.svelte` and `assets/js/shared/components/lobby.svelte`.
- Affected specifications: Lobby transition requirements in `session-workspace-lifecycle` and `multi-session-game-workspace`.
- Tracking: GitHub issue `#173`.
- No API, route, persistence, migration, dependency, iframe module, or rollback data impact.
