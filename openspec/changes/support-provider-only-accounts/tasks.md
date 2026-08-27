## 1. Delivery Coordination And Baseline

- [x] 1.1 Record issue #242 as the owner of the optional-email account invariant and link its implementation evidence to the D20 Project item.
- [ ] 1.2 Reconcile the independently owned Steam issue #241 and its `add-steam-account-authentication` OpenSpec artifacts so Steam consumes provider-only registration instead of mandatory email completion, without moving Steam protocol work into this change.
- [x] 1.3 Characterize existing direct-email, password, Magic Link, Google, Discord, Apple, linking, sudo, notification, and Account Settings behavior with focused tests before changing persistence.
- [x] 1.4 Audit code, fixtures, admin presentation, shared props, notifier boundaries, and tests for assumptions that `User.email` is always a string, and constrain edits to affected paths.

## 2. Nullable Email Persistence

- [x] 2.1 Add a reversible Ecto migration that removes only the `users.email` not-null constraint while retaining the `citext` type and case-insensitive unique index.
- [x] 2.2 Make the migration down path refuse to restore `NOT NULL` while null-email users exist and verify that it never fabricates or rewrites addresses.
- [x] 2.3 Update `D20.Accounts.User` types, changesets, and documentation so persisted email may be null while every operation that collects email still requires valid syntax and uniqueness.
- [x] 2.4 Preserve the existing incomplete direct-email registration shape and completed-account confirmation semantics without changing existing user IDs, usernames, password hashes, identities, or session tokens.
- [x] 2.5 Update account fixtures and test helpers to create explicit direct-email, provider-with-email, and provider-only user shapes without weakening defaults used by existing tests.
- [x] 2.6 Add migration and schema tests for multiple null emails, case-insensitive non-null uniqueness, unchanged existing rows, and reversible rollback before null rows exist.

## 3. Provider-Neutral Accounts Transactions

- [x] 3.1 Update provider registration changesets to require username, accept optional normalized email, set completed confirmation state, and reject browser-controlled identity ownership.
- [x] 3.2 Extend `D20.Accounts.register_user_with_identity/3` or its replacement to atomically create the user and exact external identity with optional email.
- [x] 3.3 Discard a currently owned provider email candidate before insertion without resolving, authenticating, or linking its owner.
- [x] 3.4 Implement one whole-transaction retry with null email only when the named users-email unique constraint loses a race; keep username and identity conflicts terminal and controlled.
- [x] 3.5 Ensure concurrent registration for one provider UID commits at most one user-and-identity pair and never authenticates a losing request by resolving the winner.
- [x] 3.6 Add Accounts tests for unused verified email, absent email, malformed or unverified candidate normalization, already-owned email, email race fallback, username race, identity race, and complete rollback on identity failure.

## 4. Provider Adapter And Registration Flows

- [x] 4.1 Update the provider-neutral registration-completion presentation and request contract to require username without requiring or accepting browser-editable email.
- [x] 4.2 Update Apple normalized registration data and encrypted completion state to carry an optional validated provider email candidate and permit unknown subjects without email.
- [x] 4.3 Update the Apple controller to create provider-only accounts for absent or owned email while preserving exact-subject returning login, explicit linking, safe returns, state consumption, and session rotation.
- [x] 4.4 Update Discord normalized registration data and session-bound completion proof to carry an optional validated verified email candidate and permit unknown user IDs without verified email.
- [x] 4.5 Update the Discord controller to create provider-only accounts for absent, unverified, invalid, or owned email while preserving exact-ID returning login, explicit linking, safe returns, proof consumption, and session rotation.
- [x] 4.6 Update Google normalized registration data and session-bound completion proof to carry an optional validated verified email candidate and permit unknown subjects without verified email.
- [x] 4.7 Update the Google controller to create provider-only accounts for absent, unverified, invalid, or owned email while preserving exact-subject returning login, explicit linking, safe returns, proof consumption, and session rotation.
- [x] 4.8 Add focused adapter and controller tests for every provider covering unused verified email import, no email, invalid or unverified email, already-owned email without merge, username failure, concurrent conflicts, returning login, and explicit linking regression.
- [x] 4.9 Verify provider completion state, page props, logs, and form fields contain no provider credential, raw claim, browser-controlled email, or provider UID exposure beyond existing server-owned encrypted or session-bound proof.

## 5. Email Addition And Delivery Safety

- [x] 5.1 Adapt the existing email-change token context to distinguish a null current email safely and invalidate it after any intervening email change.
- [x] 5.2 Keep a provider-only user's email null while Add email verification is pending and atomically attach the candidate only after valid token consumption and a second uniqueness check.
- [x] 5.3 Return controlled validation or expiry results when Add email loses a uniqueness race, is replayed, or is consumed after account state changes.
- [x] 5.4 Guard Magic Link, email-change, recovery, notifier, and queued-delivery boundaries so no token, job, or message is created without a verified non-null destination.
- [x] 5.5 Preserve neutral signed-out Magic Link responses for existing, unknown, and provider-only users and preserve issue #38's provider and queue behavior for requests that do have email.
- [x] 5.6 Add Accounts, token, notifier, and controller tests for Add email request and confirmation, null persistence before confirmation, conflicting confirmation, token replay, no-recipient guards, and neutral login output.

## 6. Login, Password, Session, And Sudo Behavior

- [x] 6.1 Preserve case-insensitive password login by username or non-null email and verify username/password login for a provider-only account with a password.
- [x] 6.2 Keep passwords optional and allow a sudo-valid provider-only user to set a password without treating that password as the account's sole verified identity or email recovery method.
- [x] 6.3 Replace sudo prompt assumptions about `current_user.email` with account-bound username and nullable email without exposing password-presence or per-provider account flags.
- [x] 6.4 Preserve the shared dialog's stable Magic Link form, username-or-email password form, and one provider block for ordinary login and sudo while enforcing account-bound success on the server.
- [x] 6.5 Bind provider sudo callbacks to the expected current user so authorization as another provider identity fails without switching the D20 session.
- [x] 6.6 Verify existing browser sessions, remember-me cookies, safe return paths, authentication rotation, and provider login remain compatible across the migration.
- [x] 6.7 Add Auth, controller, and session tests for stable email and null-email sudo prompts, account-bound provider reauthentication, wrong-account callbacks, provider outage, username/password reauthentication, and session preservation.

## 7. Account Settings And Shared Client State

- [x] 7.1 Update Account Settings props to represent email as nullable and expose `Add email` versus `Change email` without exposing provider UIDs or credentials.
- [x] 7.2 Update bounded authentication prompt props and TypeScript types to carry nullable email and the current username without password-presence or per-provider account flags; keep ordinary runtime provider availability unchanged.
- [x] 7.3 Update the Svelte Account Settings UI to display the immutable username, Add email form, absent-email recovery and notification guidance, independent password form, and existing provider states across supported viewports.
- [x] 7.4 Restore the shared authentication dialog's stable Magic Link, username-or-email password, and provider sections for provider-only sudo instead of composing markup from method flags.
- [x] 7.5 Preserve keyboard navigation, focus behavior, semantic notices, responsive layout, processing states, and independent form errors for every changed account UI state.
- [x] 7.6 Add focused frontend tests for provider-only settings, Add email pending and error states, stable null-email sudo forms, runtime provider availability, account-bound provider URLs, and unchanged signed-out login behavior.
- [x] 7.7 Validate changed Account Settings and authentication journeys with the configured Chrome DevTools MCP at supported narrow and wide viewports, including keyboard operation and no-email states.

## 8. Operations, Migration, And Rollback Verification

- [x] 8.1 Document the completed-account invariant, provider email candidate policy, no-merge behavior, no-email recovery limitations, and operator-visible null-email state.
- [x] 8.2 Document deploy ordering with migration first, application compatibility checks, provider-only enablement, and the issue #38 email-delivery boundary.
- [x] 8.3 Document rollback before and after provider-only account creation, including pausing new null-email registration, inventorying affected users, preserving provider access, and prohibiting fabricated email backfill.
- [ ] 8.4 Verify staging journeys for provider registration with unused, absent, unverified, invalid, and already-owned email; later Add email; returning login; provider disablement; and concurrent registration.
- [x] 8.5 Record Steam #241 reconciliation and production-readiness dependencies in issues #242 and #241 without claiming Steam implementation as part of this change.

## 9. Validation And Completion

- [x] 9.1 Format every touched Elixir file with `mix format <files>` and run the nearest migration, Accounts, provider adapter, controller, Auth, notifier, and settings tests with targeted `mix test` commands.
- [x] 9.2 From `assets/`, run targeted frontend tests with `bun run test -- <paths>` and run the repository formatting and lint scripts for touched Svelte and TypeScript files.
- [x] 9.3 Run `mix compile --warnings-as-errors`, `mix test`, `mix assets.lint`, `mix assets.test`, and `mix typecheck`, resolving failures caused by this change.
- [x] 9.4 Run `just check` after targeted backend, frontend, migration, and browser validation passes.
- [x] 9.5 Run `openspec validate support-provider-only-accounts --strict --no-interactive` and `openspec validate --all --strict --no-interactive`.
- [ ] 9.6 Update issue #242 with validation and migration evidence, complete every acceptance criterion, archive this OpenSpec change, and confirm it no longer appears in `openspec list --json`.
