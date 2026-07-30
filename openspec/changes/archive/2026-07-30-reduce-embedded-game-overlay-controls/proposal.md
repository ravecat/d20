## Why

The shell-owned display controls currently render as fixed `2.5rem` square overlays at every viewport width, so they occupy disproportionate space over embedded game content, especially on mobile devices. Their complete visible footprint needs to shrink by 20% without changing presentation-mode or fullscreen behavior.

## What Changes

- Reduce every embedded-game overlay control from `2.5rem` to `2rem` on desktop and mobile viewports.
- Apply the same `0.8` scale factor to each control surface, padding, inter-control gap, and edge offset so the SVG follows the reduced content box and the overlay remains visually proportional.
- Keep Compact, Theater, Enter fullscreen, and Exit fullscreen controls at one consistent size in every supported display mode.
- Preserve semantic buttons, accessible names, keyboard operation, visible focus, hover and disabled states, safe-area placement, native fullscreen behavior, and iframe continuity.

## Capabilities

### New Capabilities

- `embedded-game-overlay-controls`: Defines the proportional visual footprint and responsive sizing of shell-owned display controls over an embedded game.

### Modified Capabilities

- None. No capability has been archived under `openspec/specs/`; this change refines the presentation of controls introduced by the completed `embedded-game-display-modes` change without changing its mode-transition requirements.

## Impact

- Affected frontend module: `assets/js/components/dialog.svelte`; focused CSS test processing is enabled in `assets/vite.config.mjs`.
- Focused frontend coverage in `assets/js/components/session.test.ts` will verify the shared computed geometry while retaining existing interaction and accessibility assertions; real-browser checks will cover the existing desktop and narrow responsive branches.
- No dependency, backend, route, persistence, migration, session runtime, Fullscreen API, iframe sandbox, SDK bridge, or iframe module contract changes are required.
- Rollback restores the current control dimensions and spacing; no data or deployment-order rollback is required.
