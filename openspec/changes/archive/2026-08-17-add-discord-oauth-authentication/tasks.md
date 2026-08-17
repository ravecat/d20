## 1. Dependency and Runtime Boundary

- [x] 1.1 Add and lock the reviewed Ueberauth and Discord strategy dependencies, then verify dependency advisories and resolved versions.
- [x] 1.2 Add optional Discord runtime credentials, safe missing-credential degradation, environment documentation, shared availability, and focused runtime/shared-prop tests.

## 2. Accounts Registration Boundary

- [x] 2.1 Add the confirmed provider-registration changeset and one atomic Accounts transaction that creates a user and Discord identity from primitives.
- [x] 2.2 Cover successful registration, field validation, identity conflicts, and transaction rollback with focused schema and Accounts tests.

## 3. Discord Web Flow

- [x] 3.1 Add a Discord adapter that validates the provider, stable user ID, verified email semantics, and minimal normalized output without retaining credentials or profile data.
- [x] 3.2 Add explicit allowlisted routes and a controller that fixes OAuth parameters, stores short-lived session-bound attempts, handles returning login, username completion, safe local returns, explicit sudo linking, and redacted failures.
- [x] 3.3 Cover unavailable and fixed-scope requests, normalized callbacks, session rotation, completion expiry and retry, no email merge, linking bindings and conflicts, and failure cleanup with focused controller and adapter tests.

## 4. Inertia and Svelte Journeys

- [x] 4.1 Enable the existing Discord Register and Login controls only from shared availability and keep them as normal full-document links.
- [x] 4.2 Add Discord linked and unavailable states plus the explicit link action to Account Settings without coupling it to local settings forms.
- [x] 4.3 Add the Discord server-session contract to the provider-neutral registration-completion page and preserve isolated form state.
- [x] 4.4 Add or update focused Svelte tests for provider availability, full-document navigation, Account Settings linking state, and completion validation presentation.

## 5. Documentation and Validation

- [x] 5.1 Document Discord environment variables, exact callback, staging enablement gate, missing or unverified email behavior, and runtime rollback.
- [x] 5.2 Format touched files and run focused backend tests, focused frontend tests, linting, type checks, dependency audit, and strict OpenSpec validation.
- [x] 5.3 Run broad repository validation, confirm Discord remains unavailable without both credentials, and record any manual staging work that remains before production availability.

## Previous Worktree Validation Notes

- `just check` passed with 118 frontend tests, 621 backend tests, lint, typecheck, formatting, production assets, and Storybook build.
- `mix hex.audit` reports no retired or security advisory packages.
- Strict OpenSpec validation passes for all 62 changes and main specifications.
- Real Discord registration, returning login, explicit linking, denial, missing or unverified email, and credential-removal rollback still require staging verification against the exact registered callback before production availability.

## Current Master Validation Notes

- Focused backend validation passed with 106 tests covering Discord, runtime configuration, shared page props, and Account Settings.
- Focused frontend validation passed with 52 tests covering AuthDialog, Account Settings, and provider-neutral registration completion.
- `just check` passed with 121 frontend tests, 652 backend tests, formatting, lint, typecheck, production assets, and Storybook build.
- `mix hex.audit` reports no retired or security advisory packages.
- Strict OpenSpec validation passes for all 66 active changes and main specifications.
- The first broad run hit one non-reproducible workspace browser-test timing failure; its focused rerun and the complete retry both passed without workspace changes.
- Real Discord registration, returning login, explicit linking, denial, missing or unverified email, and credential-removal rollback still require staging verification against the exact registered callback before production availability.

## 6. Align With the Reviewed Google OAuth Structure

- [x] 6.1 Rebase the implementation on current master plus the reviewed Google OAuth snapshot, move Discord adapter and controller modules under `D20Web.Auth`, and reuse the generic auth, intent, safe-return, session, and Accounts boundaries.
- [x] 6.2 Replace the provider-specific completion page and old availability switch with the shared registration-completion contract and credential-derived operational availability.
- [x] 6.3 Extend the shared provider props, AuthDialog, Account Settings, runtime configuration, and documentation for Google and Discord without regressing either provider.
- [x] 6.4 Rewrite focused backend and frontend tests around the shared structure, then run formatting, targeted suites, `just check`, dependency audit, and strict OpenSpec validation.

## 7. Integrate With Apple and Current Master

- [x] 7.1 Restore the reviewed Discord implementation on current `master` without overwriting the in-progress Apple implementation, and keep Apple's POST callback flow isolated from Discord's GET callback flow.
- [x] 7.2 Extend shared authentication props, AuthDialog, Account Settings, runtime configuration, and provider-neutral registration completion for Apple, Discord, and Google without regressing any provider.
- [x] 7.3 Reconcile the Discord delta specifications and focused backend and frontend tests with Apple as an independently available provider.
- [x] 7.4 Run targeted and broad validation, update validation evidence, and archive the completed change only after current `master` passes.

## 8. Make Authentication Guidance Visually Distinct

- [x] 8.1 Extend the shared authentication prompt with an explicit semantic kind and classify recoverable guidance, unavailable or failed operations, and reauthentication prompts at the server boundary.
- [x] 8.2 Add one accessible shared inline-notification component with info, warning, and error variants, then use it for authentication prompts, local mailbox guidance, and the existing form-level failure block.
- [x] 8.3 Add focused backend and browser-mode coverage for severity semantics, verify the matching-email warning and local-mailbox info block in a real browser, run repository validation, sync the main specification, and archive the completed change.
- [x] 8.4 Align every inline-notification variant with its existing global semantic theme color, verify the local-mailbox info rendering, and rerun focused and strict validation.
- [x] 8.5 Shorten the local-mailbox guidance, make links supplied through inline-notification child content inherit the active semantic accent, update the shared Register and Login introduction to describe sharing sessions across devices, and verify the copy and presentation.
- [x] 8.6 Rename the shared component and its public surface to `InlineNotification` so it remains distinct from a future floating notification or toast component, then rerun focused validation.
- [x] 8.7 Hide unavailable provider actions and their now-empty separator, tighten spacing between dialog blocks and dividers, update focused browser coverage, and verify both account modes in a real browser.

## Authentication Notice Follow-up Validation Notes

- Focused backend validation passed with 143 tests covering shared prompt severity and Apple, Discord, Google, page, and session controller behavior.
- Focused frontend validation passed with 47 tests covering the shared AuthDialog, provider prompt severity, local mailbox guidance, form-level errors, and shared auth state.
- Real-browser verification confirmed the local-mailbox info block, a protected-route warning block, and an invalid-magic-link error block with semantic labels and roles. The exact existing-account Discord warning is covered by the browser-mode AuthDialog test.
- `just check` passed with 121 frontend tests, 652 backend tests, formatting, lint, typecheck, production assets, and Storybook build.
- The first broad run hit one non-reproducible workspace browser-test timing failure; its focused rerun and the complete retry both passed without workspace changes.
- The main email account login specification contains the shared severity contract, and strict validation passes for the active Discord change.
- The informational variant now uses the existing `--color-info` theme token instead of the primary action color; warning and error continue to use `--color-warning` and `--color-error`.
- Focused browser-mode validation passed with 40 AuthDialog tests, frontend lint and typecheck passed, and real Chrome verification confirmed the local-mailbox info styling with no page warnings or errors.
- The local mailbox copy is `Development emails are available in the local mailbox.`, its child link inherits the info accent, and the shared Register and Login introduction now describes sharing game sessions across devices.
- Focused browser-mode validation again passed with 40 AuthDialog tests, frontend lint and typecheck passed, and real Chrome verification confirmed both dialog modes and no page warnings or errors.
- The shared component, exported type, file, import, public export, and BEM block now consistently use `InlineNotification`; no `InlineNotice` or `inline-notice` references remain.
- Focused browser-mode validation passed after the rename with 40 AuthDialog tests, frontend lint and typecheck passed, and real Chrome verification confirmed the Register dialog with no page warnings or errors.
- AuthDialog now renders only available Apple, Discord, and Google links, omits Facebook and unavailable-provider placeholders, and removes the provider separator and group when every provider is unavailable.
- Focused browser-mode validation passed with 42 AuthDialog tests, frontend lint and typecheck passed, strict change validation passed, and real Chrome verification confirmed the tighter Register and Login layouts with only configured Google and Discord links visible.
- `just check` passed with 123 frontend tests, 652 backend tests, formatting, lint, typecheck, production assets, and Storybook build. Its first run hit the existing non-reproducible workspace Firefox timing failure; the focused test and complete retry both passed without workspace changes.
