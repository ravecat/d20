## Context

D20 currently stores local email directly on `users`, enforces `NOT NULL`, and treats that field as a prerequisite for every registration path. Local registration temporarily creates an unconfirmed user with email and no username, then a Magic Link assigns the username and confirms the account. Google, Discord, and Apple instead carry provider-verified email through short-lived completion state and create a confirmed user, username, and `user_identities` row in one transaction.

That model blocks providers such as Steam OpenID that prove a stable external identity but do not return email. It also conflates the completed-account invariant with availability of one particular authentication method. The stable ownership facts are instead an immutable username and at least one verified method: a confirmed D20 email or an exact, uniquely owned provider identity.

Issue #242 owns this account-model change. Steam issue #241 consumes the resulting provider-neutral path but continues to own Steam OpenID protocol, provider availability, routes, UI branding, and production verification. Production email delivery issue #38 remains independent and sends only when an operation has a verified destination.

## Goals / Non-Goals

**Goals:**

- Allow a completed account to have `email: nil` when it owns a verified external identity.
- Preserve existing email registration, Magic Link, optional-password, username-or-email password login, sessions, and account ownership.
- Accept an optional provider-verified email as the account email only when it is valid and unowned, without making it registration-critical.
- Atomically create a user and external identity and fail safely under concurrent username, email, or provider-identity races.
- Let an authenticated provider-only user add a D20-verified email later without persisting the candidate before confirmation.
- Make email-dependent controls and operations explicit and safe when no email exists.
- Migrate existing data without fabricated addresses or lost authentication methods.

**Non-Goals:**

- Automatically merging or linking accounts by email.
- Replacing `users.email` with a general credentials table in this change.
- Requiring a password, changing password-login identifiers, or adding a separate password-reset token.
- Unlinking external identities or allowing an account to remove its last verified identity.
- Implementing Steam OpenID, changing provider allowlists for Steam, or editing the independently owned Steam change.
- Changing email-delivery providers, queue reliability, Magic Link validity, marketing consent, or notification preferences.

## Decisions

### Define completion at the Accounts boundary

A completed user has:

- a valid immutable unique username;
- `confirmed_at` set; and
- either a non-null email that D20 or the creating provider verified, or at least one persisted external identity.

Pending direct-email registrations remain the one intentional incomplete shape: email is present, while username and `confirmed_at` are null and no provider identity is required. Provider registration creates the username, confirmed user, and identity together, so it never commits a completed provider user without an authentication identity.

The cross-table `email OR EXISTS(user_identities)` invariant cannot be expressed as a simple PostgreSQL check constraint. D20 therefore preserves it through narrow Accounts transactions and by keeping identity unlinking and email removal unavailable. Database constraints remain authoritative for username, non-null email, and provider ownership uniqueness.

Alternative considered: add a general `account_credentials` or email-identity table and migrate every local flow. Rejected because nullable email plus existing token verification solves the current provider constraint with less migration and contract churn.

### Make email nullable without weakening uniqueness

Add a reversible migration that drops only the `NOT NULL` constraint from the existing `citext` email column. Keep the current case-insensitive unique index. PostgreSQL permits multiple nulls while continuing to reject equivalent non-null addresses.

No existing row is rewritten. Existing emails, confirmation state, usernames, password hashes, identities, and session tokens retain their values. Application types and presentation paths must treat email as `String.t() | nil` rather than manufacturing a placeholder.

Alternative considered: store provider-specific fake addresses. Rejected because fabricated values are not owned contact methods, can collide, leak into notifications, and misrepresent recovery availability.

### Treat provider email as an optional candidate

Each provider boundary continues to normalize and trust only its stable provider UID. When a provider also asserts a verified email, the adapter validates its syntax and passes it as an optional registration candidate. Missing, malformed, or unverified provider email becomes `nil`; it does not block provider registration.

Provider registration checks whether the candidate is currently unowned. An unowned candidate is inserted as the canonical account email. An already-owned candidate is discarded and the new account is created with `email: nil`. No email match resolves, authenticates, or links an existing user. The provider-neutral completion page asks only for username and does not accept a browser-submitted email replacement.

For concurrency, the Accounts operation first attempts the complete user-and-identity transaction with the accepted candidate. If and only if the user insert loses the named email unique constraint, it retries the entire transaction once with `email: nil`. Username or identity conflicts are returned as controlled errors and are never retried as email-less registration. A losing request never resolves or authenticates a concurrently created winner.

Alternative considered: lock email strings with advisory locks. Rejected because a constraint-specific whole-transaction retry is simpler, preserves the unique index as authority, and avoids introducing a lock-key protocol.

Alternative considered: reject provider registration when its email is already owned. Rejected by the selected policy because provider identity itself proves the new account; rejecting would make optional email registration-critical and would still not permit safe account merging.

### Keep provider completion state minimal and optional-email aware

Short-lived provider registration state continues to contain only the provider UID, safe return state, and the optional normalized email candidate needed by the server transaction. It contains no provider credential or raw claims and remains encrypted or signed and session-bound according to each provider's existing flow.

The registration-completion page displays no required account email and accepts only the username plus the existing opaque server-owned proof. A successful response may present the account's resulting email state through normal authenticated Account Settings, not by trusting a pre-insert browser value.

### Reuse verified email-change semantics for the first email

Account Settings presents `Add email` when `user.email` is null and `Change email` otherwise. Both use the existing email-change token model:

1. validate the candidate and current uniqueness;
2. send confirmation to the candidate address;
3. keep `users.email` unchanged, including null, while confirmation is pending;
4. on token consumption, revalidate uniqueness and update the user atomically;
5. expire relevant tokens according to existing email-change behavior.

The token context must encode a stable representation of the current value, including the null state, so a token cannot be replayed after another email change. A uniqueness race at confirmation returns a controlled unavailable-address result and does not attach the address.

No provider-reported address replaces an existing D20 email during returning login or linking. A provider-only user explicitly adding email through Account Settings uses D20 verification, regardless of earlier provider claims that were unavailable or owned.

Alternative considered: write an unverified candidate into `users.email` immediately. Rejected because local login, notifications, and completed-account checks could treat an unverified address as owned.

### Preserve local authentication and make method availability explicit

Public signed-out login remains enumeration-neutral:

- Magic Link accepts email and returns the same response for unknown, absent, and provider-only accounts.
- Password login continues accepting username or email and fails generically when the account has no password.
- Provider actions remain based on runtime availability.

An authenticated provider-only user may set a password through the existing sudo-protected settings flow. Password does not replace the requirement for the account's verified provider identity and does not create an email recovery path. Until email is verified, Magic Link recovery and email notifications are unavailable and Account Settings explains how to add email.

Email delivery and token creation operations must receive a user with a non-null verified destination or return a controlled unavailable result before inserting a token or job. No message is addressed to an empty or fabricated value.

### Bind sudo reauthentication without restructuring the shared dialog

Sudo prompts must not assume `current_user.email` exists. The prompt identifies the current account by username and carries email as a nullable value, but it does not expose separate password or per-provider availability flags. The shared dialog retains its existing stable Magic Link form, username-or-email password form, and one provider block driven by the same runtime provider availability used for ordinary login. A null email therefore changes account data and delivery behavior, not the dialog's composition.

Magic Link requests without a verified destination create no token or delivery, and password attempts against an account without a password retain the existing generic failure. A provider callback used for sudo reauthentication must resolve to the expected current user. A different provider identity fails closed and must not switch the browser session to another D20 account. Shared props never expose password presence, linked-provider membership, provider UIDs, email candidates, credentials, or raw claims.

Alternative considered: conditionally compose the dialog from account-specific Magic Link, password, and per-provider flags. Rejected because it creates many presentation combinations, leaks unnecessary account-method metadata into shared props, and is not required for security when token confirmation, password authentication, and provider callbacks remain account-bound on the server.

### Keep existing activation and sessions compatible

`confirmed_at` continues to mean that account registration is completed, not that every future contact method was independently verified. Provider-created users set it when their atomic user-and-identity transaction succeeds. Direct-email users set it only after Magic Link completion. A provider-only user's later email is trusted because it is written only after the email-change token is consumed.

Existing session tokens remain valid across the nullable-column migration. No forced logout or token rewrite is required. Existing users already satisfy the new completed-account invariant through their confirmed email and any linked identities.

## Risks / Trade-offs

- [The completed-account invariant spans `users` and `user_identities`] -> Keep all provider creation inside one Accounts transaction, retain identity unlinking as a non-goal, and add invariant-focused transaction tests.
- [Two providers can assert the same verified email] -> Preserve one canonical owner through the unique index, discard the candidate for later accounts, and never infer shared ownership.
- [A uniqueness race occurs after the initial email availability check] -> Retry only the failed provider registration transaction once without email when the named email constraint loses.
- [Provider-only users have no email recovery or notifications] -> Expose method availability in settings and sudo UI, omit impossible operations, and explain email addition without fabricating delivery.
- [A provider outage can temporarily strand a provider-only user without password] -> Allow authenticated users to add verified email and an optional password; provider redundancy and unlinking remain separate work.
- [Existing code assumes email is always a string] -> Audit schema types, notifier/token guards, layouts, admin views, fixtures, serializers, prompts, and tests before enabling null-email creation.
- [Restoring `NOT NULL` after provider-only accounts exist is not automatic] -> Inventory null-email users and require a verified resolution plan before rollback; never backfill fake addresses.
- [Steam #241 currently specifies mandatory email completion] -> Update that independently owned change to consume this provider-only path before Steam implementation or completion; do not duplicate Steam protocol requirements here.
- [Issue #38 may enqueue email for a user without a destination] -> Keep its queue/provider work independent but require every enqueue boundary to skip or reject operations lacking verified email.

## Migration Plan

1. Reconcile issue #242 artifacts and update the independently owned Steam #241 specification before implementing Steam registration against the old mandatory-email flow.
2. Add and validate the nullable-email migration while leaving the unique email index, existing data, and all provider entry points unchanged.
3. Update schema types, fixtures, Accounts email operations, account projections, and UI assumptions so existing flows work with both string and null email before allowing new null rows.
4. Add the provider-neutral optional-email registration transaction and constraint-specific fallback, then adapt Google, Discord, and Apple normalization and completion state.
5. Update Account Settings, shared authentication props, notifications, recovery, and account-bound sudo reauthentication while preserving the shared dialog's stable forms.
6. Deploy the migration before the application release. Verify existing email, password, Magic Link, provider login/linking, current sessions, and email delivery before enabling a provider without email.
7. Verify provider-only registration, later email verification, no-merge behavior, concurrency races, and provider disablement in staging. Steam #241 may then enable its provider-specific registration path.

Before any provider-only account is created, rollback may restore the previous application and reverse the nullable migration because every row still has email. After null-email rows exist, application rollback must first preserve access through their provider identities, pause creation of more provider-only users, inventory affected accounts, and collect and verify real addresses or deploy a forward fix. The down migration must fail rather than fabricate data while null rows remain.

## Open Questions

None. Local authentication remains Magic Link plus optional password with username-or-email password identifiers, and unique verified provider email is imported opportunistically as selected in issue #242 clarification.
