## Why

The game detail layout already defines page insets and sibling gaps, but its activation and description panels add another `1rem` of internal padding. These nested spacing layers shift related content inward and make the composition looser than intended.

## What Changes

- Remove internal padding from the activation and description panels.
- Keep spacing between the two panels owned by the parent layout gap.
- Keep spacing among activation metadata, setup controls, feedback, and actions owned by their existing flex and grid gaps.
- Preserve responsive page insets, bounded description overflow, session creation behavior, and accessible structure.
- Update responsive browser coverage to verify flush panel content at narrow and wide viewports.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `responsive-game-detail-spacing`: Require panel content to use parent-owned spacing without additional activation or description panel padding.

## Impact

- Affected frontend: `assets/js/pages/game/ui/game.svelte` and its focused browser test.
- No route, Inertia prop, session, iframe module, persistence, or game-engine contract changes.
- No new dependency or migration.
- Rollback is limited to restoring the two panel padding declarations and matching assertions.
