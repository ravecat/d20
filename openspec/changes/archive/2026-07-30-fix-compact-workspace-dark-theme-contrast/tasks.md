## 1. Regression Coverage

- [x] 1.1 Extend `assets/tests/widgets/workspace/ui/workspace.browser.test.ts` with dark-theme token values and assert computed Compact surface, status, session-label, and control colors.

## 2. Compact Theme Correction

- [x] 2.1 Update `assets/js/widgets/workspace/ui/workspace.svelte` so Compact status and session-label colors follow the existing inverse theme token pair without fixed white content colors.

## 3. Validation

- [x] 3.1 Run the focused workspace browser test and resolve regressions.
- [x] 3.2 Format touched frontend files, then run frontend lint and type checks.
- [x] 3.3 Run strict OpenSpec validation and inspect the corrected Compact presentation in a real browser at representative light and dark theme values.
