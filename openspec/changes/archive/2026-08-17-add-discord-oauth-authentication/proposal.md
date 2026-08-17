## Why

D20 exposes Discord as an unavailable account choice even though the shared external-identity foundation already supports Discord identities. Players need a secure Discord registration, returning login, and explicit account-linking flow that resolves to the existing D20 account and session model without treating a matching email as ownership proof.

## What Changes

- Add an explicitly configured Discord OAuth authorization-code flow with fixed minimal scopes, Ueberauth state validation, allowlisted routes, credential-derived availability, and redacted failures.
- Authenticate returning players only through the exact stored Discord identity and the existing rotated D20 session boundary.
- Reuse the provider-neutral, short-lived, session-bound registration-completion flow introduced by Google to atomically create a confirmed D20 user and Discord identity when Discord supplies an acceptable verified unused email.
- Fail closed on missing or unverified Discord email, matching local email, identity conflicts, expired completion state, callback failures, and caller attempts to expand OAuth parameters, while providing a safe local or email-authentication next action.
- Let sudo-valid authenticated players explicitly link one unowned Discord identity from Account Settings without switching accounts or silently merging by email.
- Show Discord links in Register and Login only when runtime configuration reports Discord available, omit unavailable provider placeholders and their separator when no external provider is available, and expose linked state in Account Settings.
- Present authentication guidance and failures as accessible semantic info, warning, and error blocks so matching-email recovery instructions remain visible instead of blending into surrounding copy.
- Preserve Apple and Google as independently configured providers, reuse their shared authentication, registration-completion, settings, and sudo boundaries, and keep Apple's cross-site POST callback on its dedicated encrypted-cookie flow.
- Add dependency, adapter, Accounts, controller, session, UI, configuration, and regression coverage plus deployment and rollback documentation.

## Capabilities

### New Capabilities

- `discord-account-authentication`: Discord availability, authorization, normalization, registration completion, returning login, explicit linking, failure handling, release validation, and rollback.

### Modified Capabilities

- `email-account-registration`: The shared registration dialog conditionally enables Discord as a normal full-document account method.
- `email-account-login`: The global authentication prop reports provider availability, Login conditionally enables Discord, and Account Settings exposes Discord linking state and action.

## Impact

- Backend: the provider-independent `D20.Accounts` registration operation, `D20Web.Auth`, explicit auth routes, Discord adapter/controller modules under the shared auth namespace, and focused tests.
- Frontend: shared Inertia auth props for Apple, Discord, and Google, typed authentication prompt severity, an accessible inline notification primitive, AuthDialog provider controls, Account Settings, the common registration-completion page, TypeScript declarations, and component tests.
- Configuration and operations: the existing `ueberauth` boundary plus `ueberauth_discord`, optional Discord client runtime variables, exact callback registration, safe missing-credential degradation, and staging verification.
- Persistence: no migration; the existing `user_identities` table and uniqueness constraints remain authoritative.
- Rollback: removing either Discord credential makes new requests and links unavailable while preserving users and identity mappings; local email and password authentication remain available.
