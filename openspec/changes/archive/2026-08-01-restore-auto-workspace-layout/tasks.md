## 1. Remove exact-focus implementation

- [x] 1.1 Remove Workspace context, pending focus state, and `focusWhenAvailable`
- [x] 1.2 Remove the game page and Lobby start-completion callback while preserving existing Lobby exit rendering
- [x] 1.3 Remove exact-focus test harnesses and scenarios

## 2. Restore Auto behavior

- [x] 2.1 Initialize `WorkspaceStore` in Auto and keep the existing first-session derivation
- [x] 2.2 Update model and workspace presentation tests for Auto mount, replacement snapshots, explicit Compact, and remount

## 3. Superseded artifacts and validation

- [x] 3.1 Remove the uncommitted exact-session focus OpenSpec changes
- [x] 3.2 Run targeted tests, complete frontend tests, typecheck, lint, formatting, and strict OpenSpec validation
- [x] 3.3 Sync and archive the completed Auto-layout change
