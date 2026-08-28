## Why

D20 already represents Facebook identities and now supports completed provider-only accounts with nullable email. Requiring a Facebook-specific mailbox-verification journey adds avoidable fields, delivery dependencies, and a second provider authorization even though the exact Facebook identity is sufficient to establish the account's authentication method. Facebook registration should use the same username-only completion contract as Google, Discord, and Apple.

## What Changes

- Add an explicitly configured Facebook authorization-code flow with fixed minimal scope and profile fields, Ueberauth state validation, current versioned Meta Graph endpoints, allowlisted routes, credential-derived availability, and redacted failures.
- Authenticate returning players only through the exact stored Facebook user ID and the existing rotated D20 session boundary.
- Route an unknown Facebook identity through the shared username-only registration-completion page and create the completed user and Facebook identity atomically.
- Treat a syntactically valid Facebook email returned consistently by the provider as an optional server-owned account candidate. Persist it only when unowned; otherwise complete registration with null email.
- Never accept a browser-submitted email during provider completion and never use a Facebook email match as identity, authentication, merging, or linking proof.
- Safely handle absent, malformed, or already-owned email candidates, duplicate usernames, replay, expired state, provider cancellation, callback failure, and ownership conflicts.
- Let sudo-valid authenticated players explicitly link one unowned Facebook identity from Account Settings without changing accounts or silently merging by email.
- Add Facebook to shared authentication availability, Register and Login choices, Account Settings, provider-neutral registration completion, and Storybook authentication workflows.
- Remove the Facebook-only mailbox confirmation, second authorization, strict email-backed Accounts operation, provider-registration notifier, editable-email UI state, and confirmation route.
- Document `FACEBOOK_OAUTH_CLIENT_ID`, `FACEBOOK_OAUTH_CLIENT_SECRET`, the exact callback, Meta Development mode roles and test users, local HTTPS fallback, staging verification, dependency compatibility evidence, and credential-removal rollback.

## Capabilities

### New Capabilities

- `facebook-account-authentication`: Facebook availability, authorization, returning login, provider-only-capable registration, explicit linking, failure handling, operational validation, and rollback.

### Modified Capabilities

- `email-account-registration`: The shared account journey conditionally offers Facebook and uses the same username-only optional-email provider registration contract for Facebook, Google, Discord, and Apple.
- `email-account-login`: Shared authentication availability and Account Settings include Facebook login, reauthentication, and linking states.

## Impact

- Backend: `D20.Accounts`, `D20Web.Auth.Facebook`, the Facebook controller, routes, runtime configuration, shared props, and focused tests.
- Frontend: AuthDialog, Account Settings, the provider-neutral registration-completion page, Storybook fixtures and workflows, visual baselines, and focused tests.
- Dependencies and operations: a pinned Facebook OAuth strategy behind explicit current Meta endpoints, two optional runtime credentials, exact callback registration, Meta app-role or test-user setup, dependency audit, and manual staging verification.
- Persistence and protocols: no migration or public channel-contract change; nullable `users.email` and existing `user_identities` constraints remain authoritative.
- Rollback: removing either Facebook credential disables new Facebook requests and links while preserving local authentication, users, and identity mappings. Provider-only Facebook users require another linked method before provider removal can be their complete recovery path.
- Tracks [GitHub issue #187](https://github.com/ravecat/d20/issues/187).
