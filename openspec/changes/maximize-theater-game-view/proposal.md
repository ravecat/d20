## Why

The Theater presentation currently limits embedded games to `72rem` by `42rem` on wider viewports, leaving substantial shell-owned space unused and making the shared container favor landscape games. The shell needs a format-neutral Theater surface that gives every game nearly the entire safe dynamic viewport and lets the game decide how to use that space.

## What Changes

- Expand Theater mode to nearly the full available dynamic viewport at every viewport width, including desktop and mobile layouts.
- Replace the desktop-specific maximum dimensions and narrow-viewport sizing override with one responsive, format-neutral Theater layout.
- Keep a minimal outer gap around Theater mode and respect safe-area insets on every viewport edge.
- Keep the embedded player wrapper at the full size of the resulting Theater surface so portrait, landscape, square, and responsive games receive the same available canvas.
- Preserve Compact mode, native fullscreen, display controls, modal behavior, iframe continuity, SDK bridge continuity, and all existing game-module contracts.

## Capabilities

### New Capabilities

- `embedded-game-theater-layout`: Defines a viewport-filling, safe-area-aware Theater surface that is independent of embedded game dimensions or aspect ratio.

### Modified Capabilities

- None. No capability has been archived under `openspec/specs/`; this change refines the Theater layout introduced by the completed `add-embedded-game-display-modes` change without changing its mode-transition contract.

## Impact

- Affected frontend module: `assets/js/components/dialog.svelte`, plus behavioral frontend tests for preservation of existing presentation behavior.
- Affected presentation boundary: the shell-owned Theater dialog only; embedded games continue to size themselves within the player surface.
- No backend, route, persistence, migration, session runtime, public protocol, dependency, iframe sandbox, SDK bridge, or iframe module contract changes are required.
- Rollback restores the current desktop maximum dimensions and narrow-viewport Theater override; no data or deployment-order rollback is required.
