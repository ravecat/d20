## 1. Restore interactive story motion

- [x] 1.1 Remove `assets/.storybook/preview.css` and its import from `preview.ts`.
- [x] 1.2 Remove the four Workspace animation cancellation loops while preserving story state setup and interactions.
- [x] 1.3 Update existing Storybook contributor guidance with interactive motion, standard automated stabilization, and the installed theme/completion waiting limitation; verify screenshot setup and production CSS remain unchanged.

## 2. Validate the delivered behavior

- [x] 2.1 Run targeted Home and Workspace stories through `just assets test:visual` with file filters; inspect actual/reference/diff images and update only justified affected baselines.
- [x] 2.2 Run `just assets test:visual` across all six configured instances without baseline updates and record the result.
- [x] 2.3 Run scoped existing formatter and ESLint checks for touched frontend files, `just assets typecheck`, and `just assets storybook:build`.
- [ ] 2.4 Review a D20 Storybook browser surface for interactive motion, scrolling, and light/dark theme switching; record actual upstream waiting behavior or a concrete access blocker.

## 3. Reconcile delivery artifacts

- [x] 3.1 Record validation evidence and remaining limitations in the owning change, and reconcile the tracking issue's scope and acceptance state with the verified delivery.
- [ ] 3.2 After implementation and required validation are complete, synchronize the catalog delta and archive this change through the OpenSpec lifecycle.
- [ ] 3.3 Run `openspec validate --all --strict --no-interactive`, confirm this change is absent from `openspec list --json`, and include reconciled artifacts with the delivered changes in the semantic completion commit.
