## 1. Responsive Regression Coverage

- [x] 1.1 Extend the focused game detail browser test to assert symmetric `1rem` narrow and `1.5rem` wide shell insets, and confirm the new assertions fail against the regressed CSS.
- [x] 1.2 Extend the app layout browser test to assert that wide header, content, and footer edges share `1rem` mobile and `1.5rem` desktop insets, and confirm the assertions fail against the regressed CSS.

## 2. Game Detail Insets

- [x] 2.1 Restore component-scoped `1.5rem` inline padding on the game detail shell and its `1rem` override at the existing `48rem` breakpoint without changing block spacing or panel geometry.
- [x] 2.2 Restore matching component-scoped responsive inline padding for the wide header and footer variants without changing authentication, compact animation, safe-area, or narrow-layout behavior.

## 3. Validation

- [x] 3.1 Run the focused Chromium and Firefox browser tests for app-shell and game detail spacing.
- [x] 3.2 Run formatting checks, frontend linting, and frontend type checking for the touched Svelte and TypeScript area.
- [x] 3.3 Validate all OpenSpec artifacts strictly and confirm the expanded change is ready to archive.
