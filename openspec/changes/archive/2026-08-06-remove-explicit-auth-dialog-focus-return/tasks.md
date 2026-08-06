## 1. Account dialog focus coupling

- [x] 1.1 Remove the Register-button DOM state, binding, and `returnFocusTo` prop from the App header.
- [x] 1.2 Remove the return-focus prop and explicit caller-element focus call from the shared account dialog.
- [x] 1.3 Update focused browser coverage to retain dialog focus-entry and closure checks without requiring application-forced trigger focus restoration.

## 2. Validation and delivery

- [x] 2.1 Format touched Svelte, TypeScript, and OpenSpec files and run the focused header browser test, frontend lint, and typecheck.
- [x] 2.2 Sync the modified account specs, validate OpenSpec strictly, archive the completed change, and review the scoped diff against the existing dirty worktree.
