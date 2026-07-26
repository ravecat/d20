## 1. Focused Workspace Coverage

- [x] 1.1 Extend `assets/js/components/workspace.test.ts` to assert the named Theater control group exposes Close, Compact, and Enter fullscreen in semantic order.
- [x] 1.2 Cover direct Theater-to-Compact activation, Compact control order, fullscreen control order, iframe identity, and single SDK bridge initialization.

## 2. Workspace Window Controls

- [x] 2.1 Update `assets/js/components/dialog.svelte` so Close renders first and the non-fullscreen mode branch exposes Compact in Theater or Expand in Compact with result-oriented accessible names.
- [x] 2.2 Give the controls defined group semantics and arrange the existing flex overlay as one vertical column without changing button geometry, gap, offsets, focus, pointer, disabled, or fullscreen behavior.

## 3. Validation

- [x] 3.1 Run `bun run test -- js/components/workspace.test.ts` from `assets/` and resolve focused regressions.
- [x] 3.2 Format the touched frontend files, then run `bun run check` and `bun run typecheck` from `assets/`.
- [x] 3.3 Run `openspec validate restore-workspace-window-controls --strict` and resolve every specification issue.
- [x] 3.4 Inspect Theater, Compact, and browser fullscreen controls in a real browser and confirm action availability, computed column layout, visual order, focus visibility, and iframe continuity.

## 4. Remove the Duplicate Workspace Panel

- [x] 4.1 Update `assets/js/components/workspace.test.ts` to require that multiple active game windows render without a separate Workspace sessions region or session-summary strip.
- [x] 4.2 Remove `WorkspaceDock` from `assets/js/components/workspace.svelte`, delete the obsolete component, and reclaim the dock-only block-end reservation while preserving the safe-area offset.

## 5. Revalidation

- [x] 5.1 Run `bun run test -- js/components/workspace.test.ts` from `assets/` and resolve focused regressions.
- [x] 5.2 Format the touched frontend files, then run `bun run check` and `bun run typecheck` from `assets/`.
- [x] 5.3 Run the complete frontend test suite and `openspec validate restore-workspace-window-controls --strict`.
- [x] 5.4 Inspect the live workspace in a real browser and confirm the duplicate panel is absent while active windows and their controls remain available.

## 6. Bound the Compact Preview

- [x] 6.1 Add browser-level regression coverage that a Compact preview above the `48rem` boundary is anchored at the lower-right safe-area edge, targets `50vw` by `25dvh`, and does not form a full-width bottom strip.
- [x] 6.2 Update the workspace and Compact dialog presentation so one or more Compact windows stay within the same bounded preview region while Theater and fullscreen dimensions remain unchanged.
- [x] 6.3 Verify the `48rem` and narrower fallback keeps game content and all vertical window controls reachable without horizontal viewport overflow.
- [x] 6.4 Run focused tests, frontend formatting and checks, type checking, the complete frontend suite, strict OpenSpec validation, and real-browser inspection at representative wide and narrow viewports.
