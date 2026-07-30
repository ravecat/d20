## 1. Focused Control Geometry Coverage

- [x] 1.1 Enable focused CSS processing for `dialog.svelte` in `assets/vite.config.mjs` and extend `assets/js/components/session.test.ts` to assert that every visible Compact, Theater, Enter fullscreen, and Exit fullscreen button uses a `2rem` square surface with `0.4rem` padding.
- [x] 1.2 Assert that the control group uses a `0.3rem` gap and `0.4rem` logical block-start and inline-end offsets, including the one-control fullscreen state.
- [x] 1.3 Retain the existing semantic-name, keyboard-operable mode transition, fullscreen failure, iframe identity, and single SDK bridge initialization coverage without changing its behavioral expectations.

## 2. Proportional Overlay Reduction

- [x] 2.1 Update `assets/js/components/dialog.svelte` so `.dialog__control` changes from `2.5rem` to `2rem` in both axes and from `0.5rem` to `0.4rem` padding.
- [x] 2.2 Change `.dialog__controls` gap from `0.375rem` to `0.3rem` and its logical block-start and inline-end offsets from `0.5rem` to `0.4rem`.
- [x] 2.3 Keep the reduced geometry in the shared base rules so the existing `34rem` narrow branch receives the same `0.8` ratio without a larger mobile override.
- [x] 2.4 Preserve the existing `1px` border, `2px` focus outline, SVG stroke width, colors, hover and disabled states, logical top-end placement, dialog transitions, and fullscreen behavior.

## 3. Validation

- [x] 3.1 Run `bun run test -- js/components/session.test.ts` from `assets/` and confirm the geometry and existing display-mode tests pass.
- [x] 3.2 Run `bun run check` and `bun run typecheck` from `assets/` and resolve all failures caused by the change.
- [x] 3.3 Inspect Theater, Compact, and fullscreen controls in a real browser at a desktop viewport, `390px` width, and `320px` width; confirm the controls and icons remain proportional, do not clip at safe-area edges, retain visible focus, and cover less of the embedded game field.
- [x] 3.4 Run `openspec validate reduce-embedded-game-overlay-controls --strict` from the repository root and resolve every validation issue.
