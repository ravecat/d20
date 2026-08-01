## 1. Store Contract

- [x] 1.1 Use `WorkspaceLayout` as the flat local store context, add `id` to every mode, and publish composed `layout` through `WorkspaceState` without `expandedId` or a helper.
- [x] 1.2 Make the workspace component compare sessions directly with `$workspace.layout.id`.

## 2. Focused Coverage

- [x] 2.1 Update workspace model and presentation tests for Auto IDs, exact focused IDs while present or absent, reappearance, and Compact layout.

## 3. Validation

- [x] 3.1 Format and lint touched frontend files, run focused workspace model and presentation tests, and run frontend type checking.
- [x] 3.2 Run strict OpenSpec validation for `publish-workspace-layout-id`.
