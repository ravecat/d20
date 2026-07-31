## 1. Panel Spacing

- [x] 1.1 Remove the activation panel's internal padding without changing its flex and grid gaps.
- [x] 1.2 Remove the description panel's internal padding without changing its bounded overflow.

## 2. Browser Coverage

- [x] 2.1 Update narrow layout assertions to verify that activation and description content are flush with their panel boundaries.
- [x] 2.2 Update wide layout assertions to verify the same geometry while preserving split placement and description overflow.

## 3. Validation

- [x] 3.1 Run the Svelte autofixer and focused browser tests in Chromium and Firefox.
- [x] 3.2 Run frontend typecheck, formatting check, lint, and strict OpenSpec validation.
- [x] 3.3 Recheck the live game detail page at narrow and wide viewports.
