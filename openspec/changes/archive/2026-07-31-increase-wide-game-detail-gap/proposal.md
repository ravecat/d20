## Why

The activation and description columns currently use the same `1rem` separation as the stacked mobile flow. The wide composition needs 25% more horizontal separation while preserving the compact mobile rhythm.

## What Changes

- Increase the game detail layout gap above the existing `48rem` breakpoint from `1rem` to `1.25rem`.
- Preserve the `1rem` gap when the panels stack at or below the breakpoint.
- Preserve panel sizing, page insets, description overflow, activation behavior, and accessible structure.
- Update responsive browser coverage for both gap values.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `responsive-game-detail-spacing`: Define distinct wide and stacked parent layout gaps.

## Impact

- Affected frontend: `assets/js/pages/game/ui/game.svelte` and its focused browser test.
- No route, session, iframe module, persistence, or game-engine contract changes.
- No dependency or migration.
- Rollback restores the shared `1rem` gap and previous assertions.
