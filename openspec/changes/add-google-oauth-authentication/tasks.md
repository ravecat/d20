## 1. Provider Dependencies and Runtime Configuration

- [x] 1.1 Add and lock reviewed `ueberauth` and `ueberauth_google` versions, override Google endpoints from the current discovery document, and record the accepted PKCE limitation in code-facing configuration documentation
- [x] 1.2 Add Google client ID and client secret runtime configuration, derive availability from both credentials, document safe missing-credential degradation in `envs/.env.example`, and add no provider-specific enable switch
- [x] 1.3 Pass Google environment values through unchanged and derive availability only from whether both variables are set, without trimming or content checks

  Validation note: covered together with Apple credential pass-through in 121 focused provider and runtime configuration tests, the complete backend suite with 613 passing tests, and strict validation of all 63 OpenSpec items.
- [x] 1.4 Remove test credential defaults from runtime configuration and make provider-specific tests own any fixed non-secret Google configuration they require

  Validation note: 121 focused runtime configuration, Apple, Google, page, settings, and provider-controller tests passed, followed by the complete backend suite with 613 passing tests and strict validation of the Apple and Google changes.

## 2. Atomic Google Account Registration

- [x] 2.1 Add a focused user changeset and `D20.Accounts` transaction that inserts a confirmed email, immutable username, and provider identity atomically without accepting provider payloads
- [x] 2.2 Cover successful provider registration, validation rollback, duplicate email, duplicate username, identity ownership conflict, and concurrent duplicate attempts in Accounts tests
- [x] 2.3 Preserve the provider-verified email as the canonical account email, ignore browser replacement values, document the minimal-email-claim policy for future providers, and cover the trust boundary in controller tests

## 3. Google Web Boundary

- [x] 3.1 Add `D20Web.Auth.Google` normalization and short-lived session-bound registration completion handling for Google subject, verified email, intent, expiry, and redacted failure reasons
- [x] 3.2 Add explicit Google request, callback, and registration-completion routes plus a thin controller that strips provider parameter overrides, preserves safe local returns, rejects unavailable provider routes before Ueberauth, resolves existing identities, and rotates the normal D20 session
- [x] 3.3 Add explicit authenticated and sudo-protected Google linking from Account Settings with user-bound callback intent, idempotent same-owner handling, and generic ownership conflicts
- [x] 3.4 Add adapter and controller coverage for availability derived from credentials, fixed scopes, unavailable direct routes, state or provider failures, missing or unverified data, returning login, unknown registration, email collision, completion expiry and replay, safe returns, session rotation, and link binding
- [x] 3.5 Cover both email-collision directions: an unknown Google subject cannot merge into an email-first account, while a Google-first account rejects duplicate email registration and remains accessible through Magic Link
- [x] 3.6 Group generic browser authentication, the Google adapter, and Google HTTP orchestration under `D20Web.Auth`, mirror the namespace in tests, and update affected references without changing behavior
- [x] 3.7 Trust the subject extracted by the configured Google strategy, remove duplicate provider UID validation and defensive structural guards around application-owned configuration and signed-session values, and align focused coverage

  Validation note: 35 focused Google adapter and controller tests passed after removing duplicate subject checks, simplifying known configuration and intent shapes, and verifying completion through the signed token result with exact session nonce binding.
- [x] 3.8 Store authentication and link intents directly in the signed session, remove duplicate intent timestamps and structural validation, and preserve missing-intent failure plus callback user and sudo binding

  Validation note: 35 focused Google adapter and controller tests passed with direct atom and tuple intents, one-time consumption, missing-intent failure, Ueberauth state handling, and link callback binding coverage intact.

## 4. Inertia and Svelte Account Flows

- [x] 4.1 Expose derived provider availability without credentials, render normal full-document Google links in Register and Login only when available, and otherwise render a disabled control with visible unavailable status
- [x] 4.2 Replace provider-specific completion UI with one accessible provider-neutral Inertia registration-completion page reused by Magic Link and Google, with one labelled username form, credential-specific submission, field errors, processing state, expiry recovery, and a safe alternate registration action
- [x] 4.3 Add a Sign-in methods section to Account Settings that reports Google linked and unavailable states and offers the explicit full-document link action only when unlinked and available
- [x] 4.4 Add focused frontend tests using accessible roles and names for available and unavailable Google actions, shared Magic Link and OAuth registration completion, validation, linked, and unlinked states

## 5. Security and Delivery Validation

- [x] 5.1 Format touched Elixir and frontend files and run targeted Google adapter, controller, shared-prop, Svelte, lint, and typecheck validation
- [x] 5.2 Run the complete backend test suite, `just check`, and strict OpenSpec validation without exposing Google credentials or provider payloads
- [ ] 5.3 Register the exact staging callback and manually verify Google registration, returning login, explicit linking, cancellation, invalid state, email and identity conflicts, safe return, and session rotation before production deployment
