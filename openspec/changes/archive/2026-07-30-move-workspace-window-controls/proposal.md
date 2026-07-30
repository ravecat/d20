## Why

Workspace window controls are currently split between `Dialog` and `Workspace`: Close and fullscreen render inside the child while Compact or Expand renders separately in the parent. Composing the complete control block in `Workspace` through the existing children boundary gives one visible owner for every button, while a single expanded session identifier removes repeated per-window layout calculation.

## What Changes

- Type the required `Dialog` children snippet with the current fullscreen state and fullscreen toggle action.
- Render Close, the applicable Compact or Expand action, and fullscreen together in one `Workspace` control block inside that children snippet.
- Derive one reactive `expandedId` from the authoritative sessions and browser-local layout, then compare each rendered session with that identifier.
- Keep the Fullscreen API element reference, synchronization, and toggle implementation inside `Dialog`.
- Move the fullscreen button markup and all shared window-control styles to `Workspace`.
- Preserve native button semantics, accessible names, focus treatment, control geometry, session-close semantics, layout fallback behavior, browser fullscreen, iframe identity, and connection feedback.

## Capabilities

### New Capabilities

- `workspace-window-control-composition`: Defines one parent-owned window-control block supplied through the dialog children snippet plus single-value expanded-window derivation.

### Modified Capabilities

None. There are no synchronized main specifications under `openspec/specs/`; this change supersedes the split control-ownership decision in the unarchived completed `refactor-client-workspace` change while preserving its observable behavior.

## Impact

- Tracking issue: https://github.com/ravecat/d20/issues/155.
- Affected frontend components: `assets/js/widgets/workspace/ui/dialog.svelte` and `assets/js/widgets/workspace/ui/workspace.svelte`.
- Existing focused coverage: `assets/tests/widgets/workspace/ui/workspace.test.ts` and `assets/tests/widgets/workspace/ui/workspace.browser.test.ts`.
- No backend, route, persistence, migration, session runtime, public protocol, iframe module contract, dependency, or separately delivered game-module changes are required.
- Rollback restores dialog-owned Close and fullscreen markup, the separately positioned workspace layout control, and per-session `isExpanded` helper evaluation.
