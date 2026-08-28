## Context

D20 supports Google, Discord, and Apple through provider-specific modules below `D20Web.Auth`, explicit routes, a shared Ueberauth result boundary, `(provider, provider_uid)` identity records, atomic provider registration, safe local returns, rotated sessions, account-bound reauthentication, and sudo-protected linking. Issue #242 changed the account model so a provider can atomically create a completed user with a required immutable username, an optional verified email candidate, and one exact external identity. Steam consumes that provider-neutral path with `email: nil`.

Steam browser authentication is OpenID 2.0. Steam documents `https://steamcommunity.com/openid/` as its provider endpoint and a claimed identifier ending in `/openid/id/<steamid>`. A positive assertion contains a stable 64-bit SteamID but no email. Valve specifies the protocol but publishes no official Elixir or Ueberauth adapter.

The user approved the community Hex package `ueberauth_steam_strategy` 0.2.1. The package builds the OpenID request, performs direct provider verification, uses a Steam Web API key to call `GetPlayerSummaries`, and emits a Ueberauth result containing identity and profile data. D20 accepts those transient calls but normalizes the result to canonical SteamID only and never imports or persists profile data, callback values, or the API key.

Primary sources and integration evidence as of 2026-08-27:

- Official Steam browser authentication and 64-bit SteamID format: https://partner.steamgames.com/doc/features/auth
- Official Steam Web API: https://partner.steamgames.com/doc/webapi/ISteamUser
- OpenID Authentication 2.0: https://openid.net/specs/openid-authentication-2_0.html
- Community Hex package `ueberauth_steam_strategy` 0.2.1: https://hex.pm/packages/ueberauth_steam_strategy/0.2.1
- Community package repository: https://github.com/appsinacup/ueberauth_steam

## Goals / Non-Goals

**Goals:**

- Add Steam as a Register, Login, reauthentication, and Account Settings method while keeping D20 as the account system of record.
- Integrate Steam through the same Ueberauth strategy/controller shape as Google and Discord.
- Require the community adapter's runtime `STEAM_API_KEY` and derive availability from the expected strategy plus that nonblank credential, without a feature flag.
- Retain only canonical SteamID identity ownership in D20 persistence.
- Keep the provider boundary operation-minimal by trusting the approved strategy result instead of adding D20-owned assertion verification, nonce persistence, or protocol cleanup.
- Authenticate returning linked identities through the existing rotated D20 session boundary.
- Create an unknown Steam identity as a provider-only account after a valid unique username, with null email, in the existing atomic user-and-identity Accounts transaction.
- Keep later email addition in Account Settings and preserve no-merge behavior.
- Roll back Steam independently by removing its credential, strategy, and routes without deleting users or linked identities.

**Non-Goals:**

- Treating the community package as official Valve code.
- Collecting, fabricating, or requiring email during Steam registration.
- Creating a pending provider identity, Steam registration-proof table, or Magic Link completion path for Steam.
- Importing or persisting Steam persona names, real names, avatars, country, friends, groups, games, achievements, inventory, bans, or ownership data.
- Adding a general Steam API client outside the approved adapter.
- Supporting Valve's partner-only Web API OAuth or presenting Steam as OAuth/OIDC.
- Signing the player out of Steam, unlinking identities, linking multiple SteamIDs to one user, or generalizing every provider controller.

## Decisions

### Use the community Ueberauth strategy and the existing provider controller pattern

Add `{:ueberauth_steam_strategy, "~> 0.2.1"}` from Hex and allowlist `steam: {Ueberauth.Strategy.Steam, [...]}` beside Google and Discord. Runtime config supplies `api_key` from normalized `STEAM_API_KEY`. `D20Web.Auth.Steam.available?/0` requires both the expected strategy tuple and a nonblank API key, matching credential-derived availability for other providers.

`D20Web.Auth.SteamController` keeps the Google/Discord composition: prepare a D20 intent, reject unavailable requests, invoke `plug Ueberauth, providers: [:steam]`, match `ueberauth_auth` or `ueberauth_failure`, normalize through `D20Web.Auth.Steam`, and then perform D20 login, provider-only registration, reauthentication, or linking. The controller does not construct OpenID requests, invoke HTTP clients, fetch profiles, or clean package-private strategy state.

The package returns integer SteamID and profile/raw fields. `D20Web.Auth.Steam` converts only a canonical nonzero unsigned 64-bit UID to the provider UID string used by Accounts. All profile, raw-info, credential, and callback fields stop at the adapter boundary.

### Keep the community strategy as the complete Steam protocol boundary

The package owns request construction, state round-trip, direct OpenID verification, and its Web API profile lookup. After Ueberauth returns success, D20 validates only the provider tag and canonical UID supplied by the result, matching Google and Discord. It does not re-read callback assertions, re-run protocol invariants, persist response nonces, or add a database write before account handling.

This accepts a deliberate tradeoff: D20 does not independently guarantee cross-node replay rejection for Steam OpenID response nonces. It relies on the approved adapter's Steam verification and state handling plus D20's short-lived consumed session intent, consistent with the trust boundary used for other external providers. Repeated callbacks without a valid D20 intent cannot proceed to login, linking, reauthentication, or registration.

### Complete unknown Steam registration through provider-only Accounts

An existing exact Steam identity follows returning login. An unknown verified identity receives short-lived, integrity-protected, session-bound completion state containing canonical provider UID plus a random browser-session binding nonce. It redirects to the generic registration-completion page, which exposes `email: null`, username input, generic submission metadata, and cancel action; SteamID never appears in page props or form fields.

A valid username POST verifies completion state and calls `Accounts.register_user_with_identity(%{username: username, email: nil}, :steam, steam_id)`. Invalid or assigned username keeps completion state for retry and creates neither record. Identity conflict rolls back user creation, clears completion, creates no session, and returns a generic result. Success clears state and authenticates through `D20Web.Auth`, preserving rotation, remember-me, and safe return behavior.

A provider-only user may later add and verify email through issue #242's independent Account Settings flow.

### Reuse exact identity login, account-bound reauthentication, linking, and generic UI

Returning login resolves only `(:steam, canonical_steam_id)`. Steam data never updates username or email. Reauthentication accepts only a SteamID linked to the current user and cannot switch accounts. Linking requires the same current user and sudo proof; same-user repeats are idempotent and other ownership conflicts are generic.

Shared `auth.providers` and TypeScript declarations include `steam.available`. Existing Register/Login provider groups render full-document Steam links only when the expected strategy and API key are configured. Account Settings uses its generic provider collection and icon map. Storybook keeps Steam visible in the available Register/Login and Account Settings reference states, represents unavailable and linked states through the existing generic provider data, and includes a provider-only Steam registration-completion scenario with null email.

### Use standard Phoenix logging and telemetry boundaries

Steam OpenID assertions arrive as query parameters. Keep Phoenix's standard `filter_parameters` configuration for parsed sensitive fields, but retain the standard `Plug.Telemetry` endpoint and ordinary provider-controller diagnostics. D20 does not add a Steam-specific telemetry implementation, callback connection mutation, or route-level logging behavior. Application diagnostics record semantic provider outcomes rather than deliberately logging provider payloads.

## Risks / Trade-offs

- [The community package is third-party and performs profile lookup] -> Pin 0.2.x, audit updates, normalize to SteamID only, and never import or persist profile data.
- [The adapter requires a Steam Web API key] -> Load only at runtime, determine availability from a nonblank credential, exclude it from props/logs, and document only the variable name in the environment template.
- [The package owns legacy OpenID verification] -> Treat the approved adapter as the provider trust boundary, pin 0.2.x, test its Ueberauth result boundary, and verify the live journey in staging.
- [D20 does not add cross-node OpenID nonce replay persistence] -> Rely on the adapter's Steam verification and state plus D20's consumed short-lived intent, matching other providers and avoiding a Steam-specific database operation during login.
- [Signed session completion state is browser-readable] -> Treat SteamID as an identifier rather than a secret, bind it to an unguessable nonce and signature, expire it after ten minutes, and never expose it in page props, forms, telemetry, or logs.
- [The same SteamID or username can race during completion] -> Depend on the existing atomic Accounts transaction and named uniqueness constraints; never authenticate the winner of a losing request.

## Migration Plan

1. Deploy the provider-only account migration from issue #242 before the Steam-capable release.
2. Add a reversible migration that adds Steam only to the identity provider constraint.
3. Add `ueberauth_steam_strategy`, runtime `STEAM_API_KEY`, Ueberauth configuration, canonical D20 normalization, provider-shaped controller routes, generic UI integration, and tests.
4. Run focused dependency, adapter, migration, Accounts, controller, provider regression, frontend, compile, type, lint, broad check, audit, and strict OpenSpec validation.
5. Deploy the candidate to staging and verify the exact callback, provider-only username completion, returning login, reauthentication, linking, cancellation, repeated or intent-less callback failure, identity conflicts, safe returns, session rotation, missing-credential behavior, and profile non-persistence.
6. Deploy to production only after staging evidence is accepted.

Rollback removes `STEAM_API_KEY` first so new Steam actions become unavailable, then removes the strategy and routes in a later deployment. Existing provider-only users and Steam identities remain intact; users with added email/password retain those alternatives. Do not reverse the provider constraint while Steam rows remain. Never fabricate email for provider-only users.

## Open Questions

None.
