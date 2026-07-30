## Why

Game-specific creation parameters are currently modeled as registry UI config and are sent during the already-created session's `start` command. This puts setup choices, such as the Koala Rescue Club sheet, on the wrong lifecycle boundary: those choices define the initial game state and should be known when the session is created.

## What Changes

- Move game creation attrs from the session `start` command to `POST /games/:slug/sessions`.
- Let each game engine describe and validate its own session creation attrs through a game-owned schema or changeset-like contract.
- Pass validated creation attrs into the game engine when initializing the game state.
- Keep session `start` responsible only for transitioning a ready waiting session into play.
- Derive frontend creation controls from the game-owned attrs description instead of hand-maintained registry form config.
- Keep the registry focused on stable operational bindings such as slug, engine, BGG id, and sandbox policy.
- Preserve shareable `/games/:slug?session=:id` URLs and iframe module connection semantics.

## Capabilities

### New Capabilities
- `game-session-creation-attrs`: Defines how games declare, validate, submit, and consume attrs needed to create a session.

### Modified Capabilities
- None. There are no archived base specs for this behavior yet.

## Impact

- Affected backend modules: `D20.Game`, `D20.Sessions`, `D20.Sessions.Session`, `D20Web.PageController`, `D20.Games.Registry`, and game engines such as `D20.KoalaRescueClub.Game`.
- Affected frontend modules: `assets/js/pages/game.svelte`, session creation form handling, and related TypeScript game prop types.
- Affected tests: controller tests for `POST /games/:slug/sessions`, session lifecycle tests, Koala game initialization tests, and frontend page/session form tests.
- API impact: `POST /games/:slug/sessions` accepts game creation attrs; channel event `start` no longer carries game creation attrs.
- Runtime compatibility risk: existing sessions already created before this change cannot retroactively receive creation attrs. Since current sessions are in-memory runtime processes, no database migration is required.
- Iframe module impact: no change to module connection payload or iframe sandbox contract is intended.
- Rollback impact: revert to registry-owned attrs config and pass attrs on `start` if the new init boundary regresses.
