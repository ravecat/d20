## Why

Long game descriptions are capped inside an independently scrolling panel on wide screens. Readers should reach the full description by scrolling the game page, with the description's height determined by its content at every viewport width.

## What Changes

- Remove the description panel's height cap and internal scrolling behavior so long descriptions extend the document.
- Keep short descriptions and the existing empty-description fallback naturally sized.
- Preserve the wide split layout, narrow stacked layout, metadata, accessible regions, launch form, and lobby behavior.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `game-detail-activation-layout`: Replace the wide description's internal scrolling requirement with content-sized description flow and page scrolling.
- `responsive-game-detail-spacing`: Require natural description height at every supported width while preserving the existing responsive placement and spacing.

## Impact

- Tracking: [GitHub issue #274](https://github.com/ravecat/d20/issues/274) in D20 Project 5.
- Product changes are limited to description styles in `assets/js/pages/game/ui/game.svelte`.
- No backend, route, metadata, session, persistence, iframe contract, dependency, or migration changes.
- Validation uses existing game unit and app layout browser suites plus focused responsive browser inspection.
- Rollback restores the removed description CSS; no data migration is involved.
