## 1. Shared API Boundary

- [x] 1.1 Create `shared/api` socket, embedded-module contracts, and the segment public API.
- [x] 1.2 Update runtime, type-only, and Vitest mock imports to consume the Shared public API.
- [x] 1.3 Remove the superseded root modules and verify no legacy import paths remain.

## 2. Initial Shared API Validation

- [x] 2.1 Format the touched frontend and OpenSpec files with repository-native tools.
- [x] 2.2 Run focused session and workspace transport tests.
- [x] 2.3 Run the complete frontend test, lint, and type-check workflows.

## 3. Staged FSD Structure

- [x] 3.1 Keep `assets/js/app.js` as the stable build adapter and move application bootstrap implementation into the App layer.
- [x] 3.2 Convert flat Inertia pages into page slices with `ui` segments and public APIs, then update page resolution and test imports.
- [x] 3.3 Move root components, stores, and types into transitional Shared segments with segment public APIs while preserving their contracts.
- [x] 3.4 Update runtime, type-only, and Vitest mock imports, remove the legacy technical-bucket aliases, and verify the superseded root directories are gone.

## 4. Staged Migration Validation

- [x] 4.1 Format the moved frontend files and updated OpenSpec artifacts with repository-native tools.
- [x] 4.2 Run focused page, layout, session, and workspace tests.
- [x] 4.3 Run the complete frontend test, lint, type-check, and production build workflows.
- [x] 4.4 Run strict OpenSpec validation and verify no legacy import paths or empty runtime layer directories remain.
