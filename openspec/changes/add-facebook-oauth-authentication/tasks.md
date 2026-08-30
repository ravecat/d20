## 1. Dependency and Runtime Compatibility

- [x] 1.1 Add and lock the reviewed Facebook Ueberauth strategy, override token and profile requests to the explicit current Meta Graph API version, fix minimum scope and fields, and cover the resolved configuration.
- [x] 1.2 Add optional `FACEBOOK_OAUTH_CLIENT_ID` and `FACEBOOK_OAUTH_CLIENT_SECRET`, credential-derived availability, safe missing-credential behavior, environment documentation, and runtime/shared-prop tests.
- [x] 1.3 Record current Meta endpoints, redirect matching, Development-mode role and test-user constraints, local HTTPS fallback, package limitations, and the accepted confidential-client security gate in durable integration documentation.

## 2. Provider-Neutral Facebook Registration

- [x] 2.1 Add a Facebook adapter that validates the exact app-scoped user ID and exposes only an optional normalized email candidate from consistent provider callback data.
- [x] 2.2 Store bounded session-bound registration state containing only provider UID, optional email candidate, nonce, and safe return path.
- [x] 2.3 Add focused adapter, expiry, malformed UID, optional-email, and redaction tests.

## 3. Facebook HTTP Boundary

- [x] 3.1 Add explicit request, callback, username-only registration-completion, cancellation, and sudo-link routes plus a Facebook controller with fixed request parameters and safe local returns.
- [x] 3.2 Implement returning exact-identity login, unknown-identity username completion, provider-neutral atomic user-and-identity creation, idempotent linking, account-bound reauthentication, generic conflicts, session rotation, and terminal cleanup.
- [x] 3.3 Cover unavailable requests, scope escalation, state/provider failures, missing, malformed, unused, and owned email candidates, browser email replacement, username and identity conflicts, safe returns, session rotation, link binding, and redacted diagnostics.

## 4. Inertia, Svelte, and Storybook

- [x] 4.1 Add Facebook shared availability and linked state, normal full-document Register/Login/Account Settings actions, and omit Facebook when unavailable without exposing credentials.
- [x] 4.2 Keep the provider-neutral registration-completion page username-only for Facebook, Google, Discord, and Apple while displaying any server-owned email candidate as read-only text.
- [x] 4.3 Add focused frontend tests for Facebook username-only completion with and without email, use the generic Auth Provider story for the shared completion UI, and keep deterministic Facebook available, unavailable, linked, and unlinked Storybook states.
- [x] 4.4 Validate affected UI in supported desktop and mobile viewports with `chrome-devtools` MCP and record any fallback limitations.

## 5. Automated Validation and Specification Reconciliation

- [x] 5.1 Format touched Elixir and frontend files and run focused backend and frontend tests, linting, typecheck, production asset build, and Storybook build.
- [x] 5.2 Run `mix hex.audit`, complete backend tests, `just check`, and `openspec validate --all --strict --no-interactive`; resolve failures without unrelated changes.
- [x] 5.3 Reconcile task status and delta specifications with verified behavior and document exact residual risks, rollback behavior, and external prerequisites.
- [x] 5.4 Rebase the owning branch-backed worktree onto the nullable-email, provider-only account model and preserve Facebook login, linking, and reauthentication behavior.
- [x] 5.5 Align Facebook account creation with the provider-neutral optional-email transaction and update affected backend, frontend, Storybook, and regression contracts.
- [x] 5.6 Re-run focused and broad repository validation on the rebased result and keep external Meta verification tasks open.
- [x] 5.7 Remove the obsolete Facebook mailbox-verification sequence, second authorization intent, strict email-backed Accounts and notifier operations, editable-email UI state, confirmation route, and superseded tests.
- [x] 5.8 Verify username-only Facebook registration with unused, absent, malformed, and already-owned email candidates; regenerate focused visual baselines; reconcile all delivery artifacts; and rerun required focused and broad validation.

## 6. External Meta Verification

- [x] 6.1 Configure a Meta Development-mode app with an eligible administrator, Development-mode localhost callback support, the exact production callback, email permission, and the documented runtime credentials.
- [ ] 6.2 Manually verify registration with unused, absent, malformed, and already-owned email candidates, returning login, explicit linking, cancellation, invalid state, username and identity conflicts, replay, safe return, session rotation, and credential-removal rollback.
- [ ] 6.3 Register and verify the exact staging callback and complete journey before claiming production readiness or archiving the change.

## Validation Notes

- The Facebook implementation was originally committed on top of the nullable-email provider-only account model, then corrected under issue #187 to remove its unnecessary strict-email exception.
- Focused backend and frontend baselines passed before the correction after initializing ignored worktree dependencies. The repository's `bun run test` script did not resolve its local binary under the worktree shell, so the same locked Vitest binary was invoked directly for focused frontend validation.
- The corrected flow passed 109 focused Accounts and Facebook tests, 243 cross-provider and session tests, 7 registration-completion component tests, and 12 desktop, tablet, and mobile Storybook visual tests.
- `mix compile --warnings-as-errors`, `mix hex.audit`, frontend formatting, linting, typecheck, Svelte diagnostics, focused Elixir formatting, `git diff --check`, and strict validation of all 75 OpenSpec specifications and changes passed.
- Chrome DevTools MCP verified desktop completion with a read-only email candidate, mobile provider-only completion without email UI, username autofocus, keyboard order, and a clean console. Validation also exposed and corrected the username input pattern for current HTML regular-expression parsing.
- The first `just check` run reached the complete frontend suite but re-optimized Vite dependencies mid-run, causing two unrelated browser import failures and the previously observed 8-pixel `Maximum Only` mobile screenshot difference. The exact isolated browser tests passed 14/14 and the unrelated mobile visual test passed 4/4 without source or baseline changes. A second complete `just check` then passed with 188 frontend tests, production Storybook build, typecheck, lint, formatting, OpenSpec lifecycle checks, and 729 backend tests.
- Removing either Facebook credential remains the operational rollback. Existing provider-only Facebook users require another linked authentication method before provider removal can serve as a complete recovery path.
- A real unpublished Meta application is configured with the current administrator as an eligible role, automatic Development-mode localhost redirects, the exact `https://d20.ravecat.io/auth/facebook/callback` production redirect, strict redirect matching, `email` permission ready for testing, and both runtime credentials supplied outside version control.
- Issue #260 consolidated Registration Completion visual coverage to Magic Link and the generic Auth Provider story. Facebook completion with and without an email candidate remains covered by focused frontend and controller tests instead of provider-specific visual baselines.
- Tasks 6.2-6.3 remain open pending the complete real-provider journey matrix and staging verification. The change stays active and MUST NOT be archived or called production-ready until those tasks are verified.
