## 1. Restore interactive story motion

- [x] 1.1 Remove `assets/.storybook/preview.css` and its import from `preview.ts`.
- [x] 1.2 Remove the four Workspace animation cancellation loops while preserving story state setup and interactions.
- [x] 1.3 Update existing Storybook contributor guidance with interactive motion, standard automated stabilization, and the installed theme/completion waiting limitation; verify screenshot setup and production CSS remain unchanged.
- [x] 1.4 Use `homeBrowseGames` in public and authenticated Home metadata defaults; preserve explicit empty, singleton, favorites, and small widget scenarios and remove imports made unused by this change.

## 2. Validate the delivered behavior

- [x] 2.1 Rerun both public and authenticated Home story files through the existing Vitest script across all six instances after changing their default data; inspect actual/reference/diff images and update only justified affected baselines, retaining Workspace coverage. Run instances sequentially with one worker when host memory pressure prevents the parallel matrix from completing.
- [x] 2.2 Rerun the full visual suite across all six configured instances without baseline updates and record the result; the same sequential invocation is permitted under host resource pressure.
- [x] 2.3 Rerun scoped existing formatter and ESLint checks for touched frontend files, `just assets typecheck`, and `just assets storybook:build`.
- [x] 2.4 Review the D20 Storybook browser surface for default Home hero cycling with normal motion and without hover/focus, Workspace motion, scrolling, and light/dark theme switching; record actual upstream waiting behavior or a concrete access blocker.

## 3. Reconcile delivery artifacts

- [x] 3.1 Record updated validation evidence and remaining limitations in the owning change, and reconcile the tracking issue's expanded scope and acceptance state with the verified delivery.
- [x] 3.2 After implementation and required validation are complete, synchronize the catalog delta and archive this change through the OpenSpec lifecycle.
- [x] 3.3 Run `openspec validate --all --strict --no-interactive`, confirm this change is absent from `openspec list --json`, and include reconciled artifacts with the delivered changes in the semantic completion commit.
