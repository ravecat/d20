## Why

The game detail page applies viewport-oriented vertical sizing to its activation panel and page padding at every viewport, leaving large empty regions below the shell header and after the activation action. The main scroll container also reserves scrollbar space on one edge only, making the page insets physically asymmetric. Issue #166 tracks restoring compact, content-driven geometry without changing game activation behavior.

## What Changes

- Remove the page-only top inset between the standard shell header and game preview at all supported viewports.
- Let the activation panel size to its metadata, setup fields, action, and errors instead of retaining a viewport-derived minimum panel height.
- Preserve the existing section gap between the preview, activation panel, and description.
- Reserve main scrollbar space on both inline edges so the page's physical insets remain symmetric.
- Preserve wide-screen split placement, bounded description scrolling, bottom edge protection, session creation behavior, and accessible structure.
- Add responsive browser coverage for narrow and wide game detail layouts.

## Capabilities

### New Capabilities

- `responsive-game-detail-spacing`: Defines compact, content-driven spacing for narrow and wide game detail compositions.

### Modified Capabilities

- None.

## Impact

- Affected frontend: `assets/js/pages/game/ui/game.svelte`, `assets/js/app/layout.svelte`, and focused browser tests.
- No route, Inertia prop, session, iframe module, persistence, or game-engine contract changes.
- No new dependency or migration.
- Rollback is limited to restoring the prior responsive CSS rules and browser assertions.
