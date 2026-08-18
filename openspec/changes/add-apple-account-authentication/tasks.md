## 1. Provider Configuration and Dependencies

- [x] 1.1 Add reviewed Ueberauth and Apple strategy dependencies, fixed Apple provider options, and dependency-lock updates.
- [x] 1.2 Add credential-derived runtime availability with an operator-supplied client secret, documented environment variables, and an operator enablement runbook.
- [x] 1.3 Cover D20-owned availability outcomes and dependency security behavior without testing declarative configuration or Ueberauth internals.

## 2. Apple Transaction Boundary

- [x] 2.1 Implement minimal Apple auth-result normalization that accepts only the configured provider, bounded subject, and optional valid email while discarding credentials and raw claims.
- [x] 2.2 Implement encrypted 10-minute attempt and completion cookies with purpose, intent, expiry, safe-return, tamper, and terminal-consumption validation.
- [x] 2.3 Cover normalization and cookie security, expiry, SameSite, scope, and tamper behavior with focused tests.

## 3. Accounts Registration and Linking

- [x] 3.1 Add a confirmed provider-registration changeset that applies the existing email and username rules without changing local registration behavior.
- [x] 3.2 Add one Accounts transaction that creates the user and Apple identity atomically and rolls back on email, username, provider-subject, or per-user-provider conflicts.
- [x] 3.3 Cover personal and relay email registration, username validation retry, duplicate email, identity conflicts, concurrency invariants, rollback, and unchanged identity lookup behavior.

## 4. Web Flow and Session Integration

- [x] 4.1 Add explicit Apple request, POST callback, and registration-completion routes with a narrow callback pipeline and no dynamic provider route.
- [x] 4.2 Implement returning login, unknown-identity completion, no-email and existing-email recovery, safe returns, session rotation, and bounded failure responses.
- [x] 4.3 Implement sudo-bound explicit Account Settings linking with idempotent same-user handling and generic ownership conflicts.
- [x] 4.4 Cover disabled access, fixed request parameters, callback outcomes, completion proof handling, registration, linking, route methods, session renewal, and bounded failure responses in controller and auth tests.

## 5. Inertia and Svelte Surfaces

- [x] 5.1 Extend the shared auth prop and TypeScript contract with bounded Apple availability and no provider credentials.
- [x] 5.2 Enable a full-document Apple action in Register and Login modes only when available while preserving disabled states for all unavailable providers.
- [x] 5.3 Add the accessible Apple username-completion page and Account Settings link or linked state with bounded result messaging.
- [x] 5.4 Validate the touched Svelte surfaces with formatting, lint, typecheck, build, and the repository's available frontend tests.

## 6. Validation and Delivery Readiness

- [x] 6.1 Run targeted Apple, Accounts, controller, session, and existing local-auth regression tests plus focused formatting and static checks.
- [x] 6.2 Run `mix hex.audit`, full backend tests, frontend checks, and `just check`, documenting any unrelated baseline advisory or environment limitation.

  Validation note: after reconciliation, `just check` passed with 116 frontend and 614 backend tests, `mix assets.build` passed, and `mix hex.audit` reported no retired or advisory-affected packages. One unrelated workspace browser test failed transiently on the first full run, then passed in a focused rerun and in the complete retry. The Nix shell hook reports a local `pg_ctl` startup warning, but the existing test database remains reachable and all database-backed checks pass.
- [x] 6.3 Validate the OpenSpec change strictly, verify Apple remains unavailable without credentials, and confirm the enablement runbook covers exact HTTPS callback, private relay, staging journeys, credential removal, and rollback.

## 7. Google Baseline Reconciliation

- [x] 7.1 Restack the change on the committed Google authentication baseline and update proposal, design, and delta specs for the shared `D20Web.Auth` namespace and provider-neutral registration completion.
- [x] 7.2 Move Apple adapter, proof, and controller modules below `D20Web.Auth`, align explicit request, callback, registration, cancel, and settings-link routes, and preserve Apple's POST-specific cookie and CSRF boundary.
- [x] 7.3 Reuse the shared registration-completion page and extend shared auth, dialog, and Account Settings state without regressing Google or local authentication methods.
- [x] 7.4 Reconcile Apple configuration, dependencies, Accounts usage, and tests with the committed Google implementation, removing superseded Apple-specific UI and duplicate provider-neutral code.
- [x] 7.5 Run targeted Apple and cross-provider regressions, `just check`, dependency audit, strict OpenSpec validation, and archive the reconciled change.

## 8. Credential-derived Availability

- [x] 8.1 Remove `APPLE_AUTH_ENABLED`, derive Apple availability from the complete credential set like Google OAuth, update operator documentation and specifications, and cover absent, partial, and complete configuration.

  Validation note: `mix deps.get` fetched `ueberauth_apple`; 90 focused Apple, runtime configuration, page, and settings tests passed. The startup validation behavior from this pass is superseded by task 8.2.
- [x] 8.2 Simplify the configuration contract so a complete credential set enables Apple without startup key, callback, or client-secret validation, and synchronize the main specification.
- [x] 8.3 Simplify runtime configuration and focused tests to implement presence-only activation and direct client-secret pass-through.

  Validation note: 92 focused Apple, runtime configuration, page, and settings tests passed, followed by the complete backend suite with 613 passing tests. Complete values enable Apple without startup credential or callback validation.
- [x] 8.4 Pass Apple and shared provider environment values through unchanged, derive availability only from whether every required variable is set, and remove trimming and content checks from configuration and tests.

  Validation note: 121 focused runtime configuration, Apple, Google, page, settings, and provider-controller tests passed, followed by the complete backend suite with 613 passing tests and strict validation of all 63 OpenSpec items. Empty and whitespace-only environment values remain unchanged and count as supplied; only `nil` marks a credential variable as unset.
- [x] 8.5 Consolidate Apple availability and request inputs under the Ueberauth Apple strategy configuration and remove the duplicate D20 module configuration.

  Validation note: 121 focused runtime configuration, Apple, Google, page, settings, and provider-controller tests passed, followed by the complete backend suite with 613 passing tests and strict validation of the Apple and Google changes.

## 9. Flow State Simplification

- [x] 9.1 Replace the custom proof module, crypto, JSON, and manual lifetime validation with one phased encrypted Apple flow cookie owned by `D20Web.Auth.Apple` and backed by `Phoenix.Token`, while preserving the POST callback, linking, safe return, and registration behavior.
- [x] 9.2 Update focused Apple flow and controller tests and run targeted and broad validation.

  Validation note: 204 focused Apple, Google, Accounts, runtime configuration, page, and settings tests passed. `just check` passed with 116 frontend and 615 backend tests, `mix assets.build` passed with only the existing chunk-size warning, `mix hex.audit` found no retired or advisory-affected packages, and strict OpenSpec validation passed all 64 items.

## 10. Provider Action Copy

- [x] 10.1 Use `Sign up with <provider>` for every provider choice in Register mode and `Sign in with <provider>` for every provider choice in Login mode, including enabled and unavailable states.
- [x] 10.2 Update focused frontend tests and verify both dialog modes in the running browser.

  Validation note: the AuthDialog browser-mode suite passed 42 tests in Chromium, covering Register and Login provider actions plus both contextual email-success notifications.

## 11. Callback Pipeline Naming

- [x] 11.1 Rename the dedicated Apple callback pipeline to `:apple` without changing its plugs or route behavior, then verify formatting, compilation, and routes.

  Validation note: focused formatting and compilation passed, all six Apple routes remained present with the POST callback mapped to `D20Web.Auth.AppleController.callback/2`, and all 15 Apple controller tests passed.
- [x] 11.2 Enforce authentication and sudo mode once in the shared Account Settings router scope, remove duplicate guards from the settings, Apple, and Google controllers, and verify route access behavior.

  Validation note: focused formatting passed and all 58 Apple, Google, and Account Settings controller tests passed, including unauthenticated, stale-sudo, and successful provider-link routes.

- [x] 11.3 Remove Apple-specific OAuth failure logging and its logging-only test while preserving fail-closed callback, registration, and linking responses.

  Validation note: focused formatting passed, all 14 Apple controller tests passed, and strict OpenSpec validation passed.

## 12. Provider Configuration Simplification

- [x] 12.1 Replace runtime Apple developer JWT generation and caching with an operator-supplied client secret, remove the lifetime and refresh-window machinery, and preserve the minimal encrypted POST callback state.

  Validation note: 89 focused runtime, Apple, controller, page, and settings tests passed; formatting, warnings-as-errors compilation, and all 66 strict OpenSpec items passed. The full backend run passed 647 of 650 tests; three exact PageController provider-map expectations failed only when the concurrent uncommitted Discord change exposed `providers.discord`, and their focused rerun passed.

## 13. Contextual Email Success Notifications

- [x] 13.1 Specify informational email-registration and magic-link success notifications with a result-only local mailbox link and no persistent development notice.
- [x] 13.2 Replace the two success-specific AuthDialog surfaces with the shared informational inline notification and remove the standalone local mailbox notice and obsolete result styling.
- [x] 13.3 Update focused browser-mode coverage for production-like initial states, conditional mailbox links after both email successes, and semantic informational status, then run focused frontend validation.

  Validation note: targeted formatting and ESLint passed, the AuthDialog browser-mode suite passed 42 tests, and TypeScript plus Svelte diagnostics completed with no errors or warnings.

## 14. Configuration Test Boundary

- [x] 14.1 Remove the direct runtime configuration test suite and Ueberauth configuration-shape checks from the Apple adapter tests while preserving coverage of D20-owned identity normalization and encrypted flow-state behavior.

  Validation note: the focused Apple adapter suite passed 7 tests asynchronously after removing the configuration-owned checks.

## 15. Inline Notification Text Rhythm

- [x] 15.1 Specify top-aligned multi-line notification symbols, progressive body-copy wrapping, and intact short linked labels without justified or balanced text.
- [x] 15.2 Update the shared InlineNotification CSS with start alignment, progressive pretty wrapping, and compatible no-wrap link labels.
- [x] 15.3 Run targeted formatting, lint, browser-mode coverage, typecheck, and strict OpenSpec validation.

  Validation note: focused formatting passed, frontend lint passed, 42 AuthDialog browser-mode tests passed in Chromium, TypeScript and Svelte diagnostics reported no errors or warnings, the production asset build passed with only the existing chunk-size warning, and strict change validation passed.

## 16. Provider Link Result Consistency

- [x] 16.1 Convert bounded Apple callback outcomes to one-use flash on the first same-site Account Settings request, redirect to the clean settings URL, and remove the Apple-specific callback result from Inertia props and Svelte tests.

  Validation note: 37 focused Apple callback and Account Settings controller tests passed, 8 focused Svelte tests passed, warnings-as-errors compilation, focused frontend formatting and lint, TypeScript and Svelte diagnostics, git diff checks, and strict OpenSpec validation all passed.

## 17. Storybook Account Pages

- [x] 17.1 Add a Storybook-only Inertia Form boundary that renders the production page structure with deterministic idle form state and prevents live submissions.
- [x] 17.2 Add typed Account Settings, Registration Completion, and Auth Confirmation page stories covering their meaningful server-owned states.
- [x] 17.3 Run focused formatting, frontend lint, typecheck, relevant page tests, Storybook static build, and strict OpenSpec validation.
- [x] 17.4 Remove autogenerated documentation opt-in from every existing story and verify the static catalog index contains only authored story entries.

  Validation note: frontend formatting and lint passed, TypeScript and Svelte diagnostics reported no errors or warnings, 14 focused page tests passed, the static Storybook catalog built successfully, its index contains ten authored stories and zero Docs entries, all six page stories rendered in Chromium without runtime errors, Storybook prevented the exercised Auth Confirmation submission from navigating, and all 65 OpenSpec items passed strict validation.

## 18. Runtime Apple Client Secret Generation

- [x] 18.1 Replace the operator-supplied client-secret contract with source Apple credentials and provider-owned Ueberauth JWT generation across the proposal, design, specifications, operator runbook, and environment template.
- [x] 18.2 Implement the Ueberauth client-secret callback in `D20Web.Auth.Apple`, update availability fixtures, and cover the provider request behavior without restoring declarative runtime-configuration tests.
- [x] 18.3 Run focused formatting, warnings-as-errors compilation, Apple and shared-provider tests, and strict OpenSpec validation.

  Validation note: 78 focused Apple, page, and Account Settings tests passed, followed by warnings-as-errors compilation and the complete backend suite with 635 passing tests. All 65 OpenSpec items passed strict validation, git diff checks passed, and every Apple example value is empty.

## 19. Storybook Addon Panel Layout

- [x] 19.1 Configure the native Storybook manager to keep the addon panel visible to the right of the story canvas in the desktop layout.
- [ ] 19.2 Run focused formatting, lint, typecheck, Storybook static build, desktop manager verification, and strict OpenSpec validation.

## 20. Provider-owned Apple Link Feedback

- [x] 20.1 Specify a short-lived encrypted Apple link-result cookie and keep Apple result handling out of provider-neutral controllers.
- [x] 20.2 Move link-result storage, validation, flash presentation, and one-use consumption into `D20Web.Auth.Apple`; stop producing or parsing Apple result query parameters.
- [x] 20.3 Update focused behavioral tests and run backend formatting, compilation, controller tests, and strict OpenSpec validation.

  Validation note: focused Apple adapter, callback, and Account Settings coverage passed with 46 tests; the complete backend suite passed with 637 tests. Focused formatting, warnings-as-errors compilation, diff checks, and strict OpenSpec validation passed.
