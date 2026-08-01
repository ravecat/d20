## 1. Store Ownership

- [x] 1.1 Derive a stable `expandedId` in `WorkspaceStore` from authoritative sessions and private layout intent, and remove raw layout from `WorkspaceState`.
- [x] 1.2 Consume `$workspace.expandedId` in the workspace component and remove its local reconciliation.

## 2. Focused Coverage

- [x] 2.1 Update workspace model tests for Auto selection, explicit focus, missing-focus fallback and retention, and Compact output.

## 3. Validation

- [x] 3.1 Format and lint touched frontend files, run the focused workspace model and presentation tests, and run frontend type checking.
- [x] 3.2 Run strict OpenSpec validation for `move-workspace-expansion-derivation`.
