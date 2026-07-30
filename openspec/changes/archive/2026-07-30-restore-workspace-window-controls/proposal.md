## Why

The workspace Theater view currently omits the explicit Compact control required by the embedded-game display contract, leaving players unable to return to the multi-window layout from the visible controls. The overlay controls also use a horizontal, mode-dependent order that obscures the distinction between closing a session and changing only its presentation.

The workspace also renders a passive session dock below the active game windows. The dock duplicates session identity, connection, and mode information without exposing any action, and the game-window layout reserves space for it even though the windows already represent every active session.

After the dock is removed, a single Compact preview still fills nearly the entire bottom edge because the workspace grid spans the viewport and the dialog fills its grid track. This obscures substantially more of the underlying page than a compact preview needs.

## What Changes

- Restore an explicit Compact action while a workspace game window is in Theater mode.
- Keep one stable source and sequential keyboard order: Close, fullscreen, then the applicable Compact or Expand action.
- Arrange Theater controls visually as Close, Compact, Enter fullscreen and Compact controls visually as Expand, Enter fullscreen, Close through CSS.
- Remove the duplicate workspace session dock without introducing a replacement panel.
- Reclaim the dock-only layout reservation while retaining safe-area spacing and mounted active game windows.
- On viewports wider than the existing `48rem` responsive boundary, bound the Compact preview region to approximately `50%` of viewport width by `25%` of viewport height and anchor it at the lower-right safe-area edge.
- Preserve an adaptive narrow-viewport fallback so game content and window controls remain usable.
- Preserve the mounted iframe and SDK bridge across Theater, Compact, and fullscreen transitions.
- Preserve native button semantics, accessible action names, visible focus, existing control geometry, and the current close and fullscreen behavior.

## Capabilities

### New Capabilities

- `workspace-window-controls`: Defines the available actions, stable source order, mode-specific visual layout, accessibility, and continuity requirements for shell-owned workspace window controls.

### Modified Capabilities

None. No capability has been archived under `openspec/specs/`; this change restores an already intended Theater-to-Compact transition and adds an explicit control layout contract.

## Impact

- Affected frontend components: `assets/js/components/dialog.svelte` and `assets/js/components/workspace.svelte`.
- Removed frontend component: `assets/js/components/workspace_dock.svelte`.
- Affected focused coverage: `assets/js/components/workspace.test.ts`.
- Tracking issues: https://github.com/ravecat/d20/issues/76 and https://github.com/ravecat/d20/issues/77.
- No backend, route, persistence, migration, session runtime, public protocol, iframe sandbox, SDK bridge, dependency, or separately delivered game-module contract changes are required.
- Rollback restores the current conditional control rendering, horizontal layout, full-width Compact region, dock composition, and dock reservation; no data or deployment-order rollback is required.
