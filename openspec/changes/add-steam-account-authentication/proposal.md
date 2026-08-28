## Why

D20 players cannot use their Steam identity to register, return, or link an account even though Steam is a natural identity provider for the tabletop audience. Steam browser authentication uses OpenID 2.0 and returns a stable SteamID without email, so it needs a provider integration and the provider-only account model established by issue #242.

## What Changes

- Add an allowlisted Steam OpenID 2.0 browser flow for provider-only registration, returning login, account-bound reauthentication, and explicit sudo-protected linking.
- Use the community Hex package `ueberauth_steam_strategy` as the Steam OpenID client and Ueberauth strategy, following the same provider-specific controller composition as Google and Discord.
- Configure the package with a runtime `STEAM_API_KEY`; Steam is available only when the expected strategy is allowlisted and that credential is nonblank.
- Normalize the package result to canonical SteamID only. The package may fetch Steam profile data transiently, but D20 does not import or persist profile fields, raw callback values, or the API key.
- Resolve returning players only by canonical SteamID and keep D20 as the account and session system of record.
- Let an unknown verified SteamID create a completed provider-only account only after the player chooses a valid unique D20 username; create the user with null email and its exact Steam identity atomically through the provider-neutral Accounts transaction from issue #242.
- Keep email addition independent: a Steam-created account may add and verify email later through Account Settings, but Steam registration does not collect, infer, or fabricate one.
- Treat the community strategy as the Steam protocol boundary, without adding D20-owned assertion verification, replay persistence, or callback telemetry behavior to login and registration.
- Extend the shared Register, Login, authentication props, Account Settings provider collection, and corresponding Storybook reference states with Steam availability and linked state.
- Add adapter, Accounts, controller, persistence, frontend, configuration, regression, release, provider-removal, and rollback coverage without changing game, channel, session, or iframe contracts.

## Capabilities

### New Capabilities

- `steam-account-authentication`: Steam availability, community-adapter integration, canonical identity normalization, provider-only registration, returning login, reauthentication, explicit linking, failure handling, release verification, and rollback.

### Modified Capabilities

- `external-provider-identity-foundation`: Add Steam as a supported minimal external identity while preserving unique ownership and data minimization.
- `email-account-registration`: Offer Steam as an independently available registration choice without changing direct-email registration or collecting email in the Steam completion flow.
- `email-account-login`: Expose Steam availability and login alongside existing provider methods without changing local login behavior.

## Impact

- Tracks [GitHub issue #241](https://github.com/ravecat/d20/issues/241), depends on the provider-only account model in issue #242, and remains a child of the persistent-identity epic.
- Backend impact includes the third-party `ueberauth_steam_strategy` dependency, `D20Web.Auth.Steam` normalization, a Google/Discord-shaped provider controller workflow, session-bound registration completion, explicit routes, and focused tests.
- Frontend impact is limited to the existing shared authentication provider controls, generic registration-completion page, Account Settings provider collection, and their Storybook reference states; no provider-specific Svelte page is introduced.
- Configuration allowlists `Ueberauth.Strategy.Steam` alongside existing Ueberauth providers and reads `STEAM_API_KEY` at runtime. No enable flag, separate realm, callback, client ID, or client secret is added.
- Persistence adds only Steam to the existing identity provider constraint. No OpenID nonce, pending provider identity, or Steam registration-proof table is introduced.
- Rollback removes the Steam credential, strategy, and routes in an application deployment while preserving linked identities and all non-Steam authentication. No public game, channel, iframe, or session contract changes are required.
