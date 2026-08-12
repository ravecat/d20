## Why

D20 currently presents Google in its shared Register and Login dialog only as an unavailable future method. Tracking issue #190 requires the first end-to-end external-provider flow so a player can create or access the same durable D20 account through Google without a separate D20 password.

## What Changes

- Add a Google OAuth request and callback boundary that accepts only the configured Google strategy, validates the provider transaction, and normalizes the stable Google subject plus verified email without retaining credentials or raw claims.
- Resolve returning players by the existing exact `(google, provider_uid)` identity mapping and finish authentication through the `D20Web.Auth` session boundary.
- Route an unknown Google identity through the same provider-neutral registration-completion page as Magic Link, then create the D20 user, immutable username, confirmed email, and Google identity atomically.
- Request the provider's minimal email-address claim when available and persist the provider-verified address as the D20 account email without requesting mailbox access.
- Reject implicit account or identity merging by email in either registration direction and direct the player to authenticate the existing D20 account before explicitly linking another provider identity.
- Let a recently reauthenticated player link one Google identity from Account Settings, with database conflicts reported without disclosing another account.
- Enable the Google actions in both shared account-dialog modes while leaving Facebook, Apple, and Discord visibly unavailable.
- Derive Google availability only from whether both optional runtime client credential variables are set, pass their values through unchanged, degrade safely when either variable is unset, and retain safe local return handling, redacted failure reporting, focused automated coverage, and manual staging verification for the Google console and production callback.

## Capabilities

### New Capabilities

- `google-account-authentication`: Google authorization, callback normalization, new-account completion, returning-player login, explicit account linking, failure handling, configuration, and release verification.

### Modified Capabilities

- `email-account-registration`: Enable Google as a full-page provider registration choice, use one provider-neutral username-completion page, and define how Google and future providers supply the canonical account email.
- `email-account-login`: Enable Google as a full-page provider login choice while preserving magic-link, password, safe-return, and dialog behavior.

## Impact

- Backend: adds reviewed `ueberauth` and `ueberauth_google` dependencies, Google provider configuration, explicit request/callback and registration-completion routes, a provider web adapter/controller under one `D20Web.Auth` namespace, and an atomic Accounts registration operation built on the existing identity foundation.
- Frontend: enables the existing Google controls in the shared account dialog, adds provider-linking state to Account Settings, and replaces provider-specific completion UI with one registration-completion page shared by Magic Link and OAuth flows.
- Configuration: adds runtime client ID and client secret variables plus exact staging and production callback requirements. Google is available when both variables are set, has no provider-specific enable switch, and keeps secrets runtime-only.
- Persistence: no new durable provider profile or token storage is introduced; existing `users` and `user_identities` constraints remain authoritative.
- Sessions and contracts: successful provider login uses the existing D20 session rotation and safe local redirect behavior. Game, channel, iframe module, and public protocol contracts are unchanged.
- Rollback: roll back the application release and revoke or rotate the Google client credentials before removing the provider dependencies. Existing D20 users and identity rows remain valid, and provider-created users retain magic-link access through their confirmed email.
