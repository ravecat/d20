## 1. Dialog composition

- [x] 1.1 Merge account form state, markup, icons, and scoped styles into `AuthDialog` while preserving existing form and accessibility contracts.
- [x] 1.2 Mount `AuthDialog` only while open, remove numeric remount versions, and preserve email only during mode switches within the same opening.
- [x] 1.3 Remove `auth_panel.svelte` and its obsolete Shared public export without changing the workspace dialog.

## 2. Verification

- [x] 2.1 Add browser coverage that closes and reopens account entry and verifies unfinished and transient state is discarded.
- [x] 2.2 Format touched frontend files and run the focused auth header browser test, frontend lint, and typecheck.
- [x] 2.3 Run strict OpenSpec validation and archive the completed change after all tasks pass.
