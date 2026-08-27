## Why

D20 currently requires every user row and every new provider registration to have an email address, which prevents verified providers such as Steam from creating accounts when they do not expose an email scope. Email must become an optional verified sign-in and contact method while immutable usernames and uniquely owned authentication identities continue to protect account ownership.

## What Changes

- **BREAKING** Make `users.email` nullable and define a completed account as one immutable unique username plus at least one verified authentication identity: a D20-verified email or a uniquely owned external provider identity.
- Allow an unknown verified provider identity to create a provider-only account after username selection, atomically creating the user and identity even when provider email is absent, invalid, unverified, or already owned.
- Persist a syntactically valid provider-verified email automatically only when it is case-insensitively unowned; never authenticate, merge, or link accounts by matching provider email.
- Let provider-only users add and verify an email later through Account Settings without storing the candidate address on the user until confirmation succeeds.
- Preserve current local behavior: email magic links, optional passwords, and password login by username or email.
- Make login, sudo reauthentication, recovery, password management, notifications, account props, and settings safe and understandable when email is absent.
- Migrate existing users and identities without changing usernames, verified emails, passwords, sessions, or identity ownership, and document reversible deployment and rollback constraints.
- Define the provider-neutral account path needed by Steam issue #241 without absorbing Steam provider configuration or protocol work.

## Capabilities

### New Capabilities
- `optional-email-account-identity`: Define the completed-account invariant, nullable-email persistence semantics, verified method availability, email addition, migration, and provider-only account lifecycle.

### Modified Capabilities
- `email-account-registration`: Allow provider registration without email, conditionally import an unowned provider-verified email, and remove the requirement to collect email before provider account creation.
- `email-account-login`: Preserve local login behavior while making email-dependent login, recovery, settings, notifications, and sudo reauthentication safe for users without email.
- `username-account-identity`: Make username completion sufficient when the same transaction establishes an external identity, without requiring an accepted email on provider completion.
- `external-provider-identity-foundation`: Add provider-neutral atomic user-and-identity registration while preserving exact identity ownership and concurrency constraints.
- `apple-account-authentication`: Permit unknown Apple subjects to register without a usable or unowned email while importing an acceptable unowned verified email when available.
- `discord-account-authentication`: Permit unknown Discord identities to register without a usable or unowned email while importing an acceptable unowned verified email when available.
- `google-account-authentication`: Permit unknown Google subjects to register without a usable or unowned email while importing an acceptable unowned verified email when available.
- `account-settings-provider-management`: Present email-dependent and password controls accurately for provider-only users while preserving provider linking behavior and responsive layout.

## Impact

- Tracks [GitHub issue #242](https://github.com/ravecat/d20/issues/242) and provides the provider-only account model required by Steam issue #241 and the persistent identity epic #12.
- Affects the `users` schema and migration, Accounts registration and email-token orchestration, provider adapters and controllers, authentication and sudo prompts, Account Settings and shared Inertia props, Svelte account UI, fixtures, and focused backend and frontend tests.
- Keeps provider credentials, raw claims, and external identity ownership outside the user row; no game, session, channel, iframe, or public AsyncAPI contract changes are intended.
- Existing unique `citext` email behavior remains for non-null values. PostgreSQL permits multiple null values under the current unique index after the not-null constraint is removed.
- The active production email-delivery change for issue #38 remains independently scoped and applies only when a verified destination email exists.
- Rollback can restore the previous application before provider-only accounts are created. After null-email accounts exist, restoring the not-null constraint requires first identifying and preserving another valid access path and then collecting, verifying, or otherwise explicitly resolving each missing email; no fabricated email backfill is permitted.
