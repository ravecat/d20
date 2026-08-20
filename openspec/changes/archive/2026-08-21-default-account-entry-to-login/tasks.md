## 1. Server-Shaped Provider Contract

- [x] 1.1 Replace provider-specific Account Settings Inertia props with one ordered collection containing explicit identifiers, names, availability, durable linked state, and Phoenix-verified link URLs.
- [x] 1.2 Update focused controller tests to verify the complete collection contract, provider order, URLs, unavailable linked state, and absence of the removed top-level props.

## 2. Generic Svelte Consumption

- [x] 2.1 Update Account Settings to consume the provider collection, filter unavailable entries, and select trusted build-time icons through a typed provider-identifier map without client route literals.
- [x] 2.2 Update focused component tests and Storybook fixtures for the collection contract while preserving available, unavailable, linked, unlinked, account-form, and username behavior.

## 3. Validation And Delivery

- [x] 3.1 Format touched files and run focused controller tests, Account Settings frontend tests, frontend typecheck and lint, and Svelte diagnostics.
- [x] 3.2 Validate the Account Settings page in a browser when the configured local UI is available, then run strict OpenSpec validation and reconcile the completed change artifacts.

## 4. Login-First Account Entry

- [x] 4.1 Make clean auth-store sessions default to Login mode and rename the guest header action and local styling vocabulary from Register to Log in.
- [x] 4.2 Update auth-store and header browser tests so Login is the default entry while registration, provider availability, responsive behavior, closing, prompts, and authenticated actions remain covered.

## 5. Combined Validation And Delivery

- [x] 5.1 Format touched files and run focused auth-store and header browser tests, frontend lint, and typecheck with Svelte diagnostics.
- [x] 5.2 Validate guest Login entry, in-dialog registration switching, and authenticated Account Settings in the configured Chrome DevTools browser.
- [x] 5.3 Run `just check`, sync both delta specifications, archive the combined change, and verify strict OpenSpec lifecycle state.

  Validation note: three `just check` attempts reached the frontend suite and failed only in the unrelated Firefox workspace fullscreen state test. The complete frontend suite passed when split into 112 non-workspace tests and 12 isolated workspace browser tests; formatting, lint, typecheck, Svelte diagnostics, Storybook build, 632 ExUnit tests, focused auth tests, and Chrome DevTools validation passed.
