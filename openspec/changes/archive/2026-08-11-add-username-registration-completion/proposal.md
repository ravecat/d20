## Why

Email registration currently confirms and authenticates a user without assigning the public username required by GitHub issue #192 and by the planned provider registration flow. D20 needs one explicit registration-completion step that establishes a stable, case-insensitively unique username before a newly registered account receives its first authenticated session.

## What Changes

- Add a nullable username identity to users with database-enforced case-insensitive uniqueness and application validation.
- Require an unconfirmed email registrant to choose an available username when consuming the confirmation link, and create the authenticated session only after username assignment and email confirmation succeed atomically.
- Present magic-link registration completion as ordinary page content in the application layout rather than as a dialog-like card.
- Allow existing accounts without a username to claim one from account settings without disrupting their current email, password, magic-link, or external-identity authentication methods.
- Allow password authentication by either username or email while preserving the generic invalid-credentials response.
- Expose the username as the account display name when present, with email as the compatibility fallback for existing accounts.

## Capabilities

### New Capabilities

- `username-account-identity`: Defines username format, normalization, uniqueness, one-time assignment, and compatibility for accounts created before username support.

### Modified Capabilities

- `email-account-registration`: Changes magic-link confirmation for new registrations into a username-gated completion step before authentication.
- `email-account-login`: Extends password login to accept either username or email while keeping magic-link login email-only and failures generic, and includes username claims in independent account-form state.

## Impact

- Adds a nullable `users.username` column and case-insensitive unique index; rollback removes username login and assignment data.
- Changes Accounts user lookup and confirmation transactions, account/session controllers, Inertia props, and account settings behavior.
- Changes the Svelte confirmation, login, and account-settings forms plus their backend and frontend tests.
- Does not change game iframe contracts, session runtime contracts, provider authorization, or existing email and external-identity records.
