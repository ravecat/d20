## 1. Specification Reconciliation

- [x] 1.1 Update affected active provider-account OpenSpec artifacts so `/profile*` is authoritative before implementation.
- [x] 1.2 Validate the route-migration change and all affected active changes strictly.

## 2. Phoenix Route Migration

- [x] 2.1 Replace the Account Settings page, update, email-confirmation, and provider-link router declarations with the `/profile*` family and add focused route absence coverage for `/users/settings*`.
- [x] 2.2 Update Account Settings and provider controllers, safe return destinations, generated links, and Apple result-cookie scope to use `/profile*` without changing authentication semantics.
- [x] 2.3 Update focused backend controller, authentication, and account tests for the new canonical paths.

## 3. Frontend and Storybook Migration

- [x] 3.1 Update Svelte actions, navigation links, authentication return targets, fixtures, and frontend tests to use `/profile*`.
- [x] 3.2 Rename the Account Settings Storybook group to `/profile`, render its layout at `/profile`, preserve explicit story IDs and scenarios, and update visual references.

## 4. Validation and Completion

- [x] 4.1 Run focused backend and frontend tests, route inspection, formatting, linting, TypeScript/Svelte checks, Storybook visual tests, and the static Storybook build.
- [x] 4.2 Run risk-appropriate broad repository validation and strict OpenSpec validation, recording any genuine residual risks.
- [x] 4.3 Reconcile completed tasks, sync the delta specifications into authoritative specs through the repository lifecycle, and archive the completed change before integration.

## Validation Notes

- `mix phx.routes` exposes eight `/profile*` routes and no `/users/settings*` route.
- Focused backend coverage passed 186 tests across Account Settings and all provider controllers; the full backend suite passed 771 tests.
- Frontend formatting, linting, TypeScript, and Svelte checks passed; all 80 unit tests and 63 desktop, tablet, and mobile Storybook visual tests passed.
- The static Storybook build completed successfully. Existing visual baselines remained valid because route metadata changed without changing rendered page content or explicit story IDs.
- Strict validation passed for the route-migration, provider-only, and Steam changes and for all 80 pre-archive OpenSpec items; post-archive validation passed all 79 active and authoritative items.
- Final `just check` passed 771 backend tests, 191 aggregated frontend unit and browser tests, formatting, linting, type checks, and the production Storybook build.
- Per the requested breaking migration, previously issued `/users/settings*` links and in-flight return destinations are intentionally not compatible with `/profile*`. No manual DevTools pass was run because no prepared D20 development page remained available; automated controller, component, metadata, and three-viewport visual coverage passed.
