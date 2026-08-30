## 1. Page Catalog Organization

- [x] 1.1 Move Account Settings and Registration Completion into authenticated and public page groups with updated visible titles and stable existing metadata IDs.
- [x] 1.2 Split Home into public and authenticated metadata groups, keeping existing scenarios, deterministic catalog data, and matching authentication context.
- [x] 1.3 Split Magic Link confirmation into public confirmation and authenticated reauthentication metadata groups with the same production component and route URL.

## 2. Regression Coverage

- [x] 2.1 Update focused page-layout tests to assert the Public and Authenticated hierarchy, unique metadata IDs, and matching shell context for every routed group.
- [x] 2.2 Move the reviewed visual references to their new public or authenticated story paths and verify the complete visual matrix without presentation changes.

## 3. Validation and Delivery

- [x] 3.1 Run focused formatting, linting, unit tests, type checks, and the static Storybook build.
- [x] 3.2 Verify the Public and Authenticated page hierarchy and representative stories in the configured Storybook browser page without console errors.
- [x] 3.3 Archive the completed OpenSpec change, run strict all-item validation, and reconcile GitHub issue #260 with the verified result.
