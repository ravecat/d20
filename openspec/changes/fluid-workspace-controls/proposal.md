## Why

Workspace Close, Compact, and fullscreen buttons retain their largest geometry on narrow viewports and occupy too much of the game surface. They should shrink smoothly to about two-thirds of their current size while retaining the existing maximum size on wide screens.

Tracking issue: https://github.com/ravecat/d20/issues/286

## What Changes

- Make workspace window buttons, icons, and internal button padding follow independent viewport-based CSS clamps in Compact, Theater, and browser fullscreen.
- Bound button size between `1.25rem` and the existing `1.875rem`, and icon size between `0.75rem` and the existing `0.9375rem`.
- Preserve the status badge size, Compact bar geometry, control gaps and offsets, native button semantics, ordering, and workspace actions.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `workspace-window-controls`: Replace fixed button and icon dimensions with shared fluid dimensions and bounded internal padding.
- `workspace-session-status-bars`: Permit fluid window controls while preserving the fixed status badge and content-derived Compact bar height.

## Impact

- Implementation is scoped to `assets/js/widgets/workspace/ui/workspace.svelte`, existing workspace story validation, and affected workspace screenshot baselines.
- No dependencies, routes, server behavior, persistence, migrations, public protocols, or iframe module contracts change.
- Rollback restores the prior CSS dimensions and associated baselines; no data rollback is required.
