## Why

The home catalog currently lists only games that have a configured local engine, which hides planned games and makes implementation availability indistinguishable from catalog membership. The catalog needs to communicate which games are playable, being developed, or inactive while still allowing every listed game to have a metadata detail page.

## What Changes

- Expand the configured catalog with Flip 7, Railroad Ink: Deep Blue Edition, Confusing Lands, Trails of Tucana, Shifting Stones, Trailblazers, Death Valley, Voyages, Sky Team, Qwixx, Nimalia, Lost Cities, Deep Sea Adventure, Waypoints, and Aquamarine.
- Add optional game `status` metadata with supported values `active` and `in_progress`; absence of `status` means inactive.
- Mark Qwinto as `active`, Koala Rescue Club as `in_progress`, and leave the remaining catalog entries inactive.
- Return catalog entries from `D20.Games.list/0` in availability order with active games first, in-progress games second, and inactive games last while preserving registry order within each group; clients render the received order without regrouping it.
- Keep active catalog cards visually prominent, mute in-progress and inactive cards, and render an explicit `Soon` badge for in-progress games.
- Render game titles directly over their artwork without a chip background, using a subtle left-side scrim for legibility.
- Allow every configured catalog game to open its metadata detail route, including entries without a playable local engine.
- Expose session creation controls for active games in every environment and for in-progress games outside production so completed games are public while work-in-progress engines remain testable during development.
- Reject direct page and standalone-module session-creation requests when the game is inactive or when an in-progress game runs in production, so the UI restriction is not the only enforcement boundary.

## Capabilities

### New Capabilities

- `game-catalog-availability`: Catalog membership, availability status, visual treatment, and detail-page access for active, in-progress, and inactive games.
- `game-session-launch-policy`: Environment-aware and status-aware policy for exposing and accepting session creation from game detail pages.

### Modified Capabilities

- None.

## Impact

- Changes the `D20.Games.Registry.Entry` contract and application game configuration.
- Changes catalog and detail Inertia props, Svelte types, home-card presentation, and detail-page activation controls.
- Changes page-controller session creation authorization without changing routes, session persistence, existing session runtime behavior, or iframe module contracts.
- Adds no database migration and no new runtime dependency.
- Rollback consists of reverting the registry fields/config entries, controller policy, and corresponding Svelte presentation changes.
