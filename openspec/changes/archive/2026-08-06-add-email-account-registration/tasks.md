## 1. Registration Application Boundary

- [x] 1.1 Add Accounts orchestration that composes user creation and confirmation-instruction delivery into explicit success, validation, and delivery-failure results.
- [x] 1.2 Add focused Accounts coverage for passwordless creation, repeated and concurrent case-insensitive email uniqueness, delivery failure, and stable identity after confirmation.
- [x] 1.3 Replace the internal JSON registration route with an Inertia form response path on the existing registration action, including scoped validation, duplicate, delivery-failure, return-path, and authenticated-caller behavior.
- [x] 1.4 Route the direct Inertia registration page through the same Accounts orchestration and cover its controlled delivery-failure recovery.
- [x] 1.5 Expose a boolean authenticated shared prop to Inertia pages and verify guest and authenticated values.

## 2. Shared-Shell Registration Experience

- [x] 2.1 Integrate registration as the initial mode of the accessible responsive Svelte account dialog using Inertia Form, including validation, success, delivery-failure, close, focus, Login-mode switching, and disabled provider states.
- [x] 2.2 Add the guest-only Register action to the shared header, including overlay interaction and existing D20 responsive styling.
- [x] 2.3 Update browser-mode component coverage for native dialog focus behavior, narrow layout reachability, provider disablement, Inertia form payloads and error bags, mode switching, and success and failure states.
- [x] 2.4 Preserve centered horizontal alignment between the default shared header and page content using stable scrollbar gutters and literal component-scoped insets instead of a global padding custom property.
- [x] 2.5 Add the `or` separator between email registration and disabled providers and verify it in the shared-header browser suite.
- [x] 2.6 Gate the local mailbox hint on both development routes and the Local mail adapter, rename its shared prop around availability, and cover the visible and hidden states.

## 3. Validation And Delivery

- [x] 3.1 Format the touched Elixir and frontend files with repository-native formatters.
- [x] 3.2 Run targeted Accounts, registration controller, authentication, page controller, and frontend browser tests.
- [x] 3.3 Run frontend lint and typecheck plus the broad `just check` workflow.
- [x] 3.4 Validate the OpenSpec change strictly, confirm all scoped tasks are complete, and keep production mail queue and retry work tracked by GitHub issue #38.
- [x] 3.5 Run focused backend and frontend validation for the local mailbox availability correction.
