## Why

The developers page already owns its browser title in Svelte, while the Phoenix controller also assigns the same value to the root layout. Keeping the title in both layers duplicates page metadata and lets the two values drift.

## What Changes

- Make the developers Svelte page the single owner of its browser title.
- Stop assigning the developers page title in `D20Web.PageController`.
- Update focused tests to verify the page-owned title without requiring a controller assign.

## Capabilities

### New Capabilities

- `client-owned-page-title`: Defines that a client-rendered page owns its browser title instead of receiving duplicate title metadata from its Phoenix controller.

### Modified Capabilities

None.

## Impact

- Affects the developers action in `D20Web.PageController`, the developers Svelte page behavior, and their focused tests.
- Does not change routes, Inertia page props, game/session behavior, iframe module contracts, dependencies, persistence, or migrations.
- Rollback is limited to restoring the controller assign and its assertion.
