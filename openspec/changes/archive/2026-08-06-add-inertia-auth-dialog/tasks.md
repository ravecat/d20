## 1. Phoenix And Inertia Authentication Boundary

- [x] 1.1 Enable Inertia request handling for existing browser authentication POST routes and add validated local return-path storage to UserAuth.
- [x] 1.2 Replace the registration JSON action and route with Inertia redirect, scoped validation, success, delivery-failure, and return-path behavior on the existing registration action.
- [x] 1.3 Add Inertia magic-link and password-login responses to the existing login action, including neutral magic-link success, generic password errors, remember-me behavior, and safe current-page return.
- [x] 1.4 Add focused controller and UserAuth tests for Inertia headers, error bags, session rotation, remember-me cookies, and safe and rejected return paths.
- [x] 1.5 Move every product account route to the Inertia pipeline, convert registration, login, confirmation, settings, and sudo responses to Inertia-only controller behavior, and preserve the generated Accounts and UserAuth security semantics.

## 2. Shared Account Dialog

- [x] 2.1 Replace the registration-only Svelte component with one native account dialog that conditionally renders Register or Login mode and preserves email, focus, close, and mode-switch behavior.
- [x] 2.2 Implement registration, magic-link login, and password login with typed Inertia Form components, isolated error bags and processing states, check-email results, password visibility, and an unchecked Keep me signed in control.
- [x] 2.3 Keep mode-specific Google, Facebook, Apple, and Discord buttons visibly unavailable and verify responsive scroll reachability and native dialog accessibility without a custom Tab trap.
- [x] 2.4 Update the shared header integration and browser-mode tests for mode switching, form payloads, error isolation, success states, focus restoration, authenticated visibility, and overlay interaction.
- [x] 2.5 Give Register and Login content-driven CSS block sizes without scripted measurement or animation-frame scheduling, retain viewport-constrained scrolling as a fallback, and verify desktop resizing and mobile overflow behavior.
- [x] 2.6 Replace local page-test mount wrappers and prop-only Svelte harnesses with standard unit and browser render APIs while keeping Inertia mocked only at the D20 call boundary.
- [x] 2.7 Extract the account forms into a reusable Svelte surface used by the native dialog and direct registration and login page without render-function or provider-button abstractions.
- [x] 2.8 Add focused Inertia pages for magic-link confirmation and account settings, including isolated form errors, token submission, password autofill semantics, and sudo reauthentication copy.
- [x] 2.9 Remove the superseded auth HEEx modules and templates and add focused frontend and controller coverage for every direct account URL.

## 3. Validation And Delivery

- [x] 3.1 Format all touched Elixir, Svelte, TypeScript, and OpenSpec files with repository-native formatters.
- [x] 3.2 Run targeted UserAuth, registration-controller, session-controller, page-controller, and shared-header browser tests.
- [x] 3.3 Run frontend lint and typecheck and the broad `just check` workflow.
- [x] 3.4 Run targeted auth controller and frontend tests after the Inertia-only migration, then run frontend lint, typecheck, and the broad `just check` workflow.
- [x] 3.5 Validate both coordinated OpenSpec changes strictly, archive `add-email-account-registration` before `add-inertia-auth-dialog`, and confirm neither remains active.
