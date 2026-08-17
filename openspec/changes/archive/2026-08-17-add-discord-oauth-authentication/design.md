## Context

D20 already owns local users, email and password authentication, session rotation, sudo checks, and an external identity table keyed by `(provider, provider_uid)`. Google authentication is committed and Apple authentication is implemented in the target `master` working tree. Discord remains a disabled future method there. Issue #188 requires registration, returning login, and explicit linking without creating a second account system, regressing Apple or Google, or treating Discord email as identity proof.

Discord currently supports the OAuth2 authorization-code grant at `https://discord.com/oauth2/authorize` and `https://discord.com/api/oauth2/token`. The `identify` scope exposes the stable Discord snowflake `id`; adding `email` exposes optional `email` and `verified` fields. `ueberauth_discord` 0.7.0 uses these endpoints and exposes the raw user object, but it is old, has no PKCE support, and accepts request parameters such as `scope`, `prompt`, guild selection, and permissions from the incoming request. The implementation must constrain that strategy at D20's web boundary.

The normal D20 session is a signed, `SameSite=Lax` cookie. Discord returns through a top-level GET callback, so the session and Ueberauth state cookie remain available. The session contents are readable by their holder, therefore completion state must contain no Discord access token, refresh token, authorization code, or unrelated profile data.

## Goals / Non-Goals

**Goals:**

- Add a credential-derived Discord method to the existing Register, Login, and Account Settings journeys.
- Resolve returning users only by the exact stored Discord identity and create D20 sessions only through `D20Web.Auth`.
- Create a new confirmed D20 user and Discord identity atomically after verified-email and username checks.
- Require a sudo-valid, same-user intent before linking Discord to an existing account.
- Fix OAuth scopes and routes, preserve Ueberauth state validation, reject unsafe returns, redact diagnostics, and make credential removal a complete rollback.
- Reuse the provider-neutral Accounts, D20 session, safe-return, sudo, shared-prop, settings, and registration-completion boundaries already used by Google and Apple.

**Non-Goals:**

- Import Discord servers, memberships, connections, display names, avatars, or social data.
- Persist or refresh Discord credentials, call Discord after the authentication callback, or sign the player out of Discord.
- Auto-link accounts by email, unlink identities, support more than one Discord identity per D20 user, or generalize all future providers in this slice.
- Enable Discord in production or claim staging verification without real Discord application credentials and exact registered callbacks.

## Decisions

### Use Ueberauth with the reviewed Discord strategy behind a strict D20 boundary

Keep `ueberauth` 0.10.8 and add `ueberauth_discord` 0.7.0. Add only explicit `/auth/discord`, `/auth/discord/callback`, and registration-completion routes. `D20Web.Auth.DiscordController` uses the same provider-scoped Ueberauth pipeline as Google and removes caller-controlled Discord request parameters before Ueberauth executes. The configured strategy fixes the scope to `identify email`; D20 never forwards caller-supplied `scope`, `prompt`, `permissions`, guild, bot, locale, or redirect parameters.

This follows the accepted provider architecture and reuses Ueberauth's state validation. Assent was considered because it is newer and supports PKCE parameters, but switching frameworks for the first implemented provider would invalidate the accepted shared boundary and add a larger integration change. A custom Discord OAuth client was rejected because it would duplicate token exchange, state, and error-handling responsibilities. The selected confidential server-side flow accepts the lack of strategy-level PKCE for this slice; a future policy making PKCE mandatory requires replacing or wrapping the strategy before enablement.

### Keep Discord-specific data at the web boundary

`D20Web.Auth.Discord` accepts only a `Ueberauth.Auth` result for the configured Discord provider. It requires a non-empty string UID no longer than the existing 255-character identity limit, verifies that it matches Discord's raw user ID, and reads `verified` only from the Discord raw user object. It returns minimal primitives needed by policy and discards credentials, codes, raw claims, display names, and avatars.

The adapter treats Discord `id` as the only provider identity key. For an already linked identity, changed or missing email data does not affect user selection. For an unknown identity, direct provider registration requires a syntactically valid email and Discord `verified == true`.

### Reuse shared provider boundaries while preserving callback-specific flow state

Before redirecting to Discord, the adapter stores the same short-lived intent shape used by Google: `authenticate`, or `link` bound to the initiating user ID, plus issue time. The generic `D20Web.Auth` boundary owns accepted safe local return paths. Ueberauth independently stores and validates OAuth state. Callback failures and terminal outcomes consume the Discord intent and clear Discord completion state. Discord and Google can use the normal signed session because both return through top-level GET callbacks.

An unknown acceptable identity creates the same signed, nonce-bound completion proof used by Google, with Discord-specific salt and session keys. It contains only provider UID, verified email, and random nonce, expires after no more than 10 minutes, and remains bound to the initiating browser session. The callback redirects to a clean local completion URL before rendering the shared provider-neutral Inertia page, so the Discord authorization code and state do not remain in the rendered page URL. Completion never appears in a query string or log.

Apple remains on its dedicated encrypted provider cookie because its cross-site POST callback cannot read the normal `SameSite=Lax` D20 session. Forcing Discord through Apple's flow would add a cookie without a callback constraint, while forcing Apple through the Google and Discord session flow would lose the initiating state. All three providers still converge on the same provider-neutral registration page, atomic Accounts transaction, login/session rotation, safe-return validation, sudo-protected linking pipeline, and caller-visible settings contract.

A server-side attempt table was considered for stronger replay accounting but rejected because the state is short-lived, contains no provider credential, and needs no cross-device continuity. The existing signed session already provides integrity and the Ueberauth state cookie protects the callback transaction.

### Add one atomic Accounts operation for provider registration

Reuse the provider-registration changeset and `D20.Accounts.register_user_with_identity/3` operation introduced by Google. It accepts user attributes, provider, and provider UID, then inserts the user and `UserIdentity` in one `Ecto.Multi` transaction. Existing unique constraints decide email, username, provider UID, and per-user provider races. Any losing transaction returns its own controlled error and never authenticates by resolving a winner.

This operation accepts primitives and remains independent of Ueberauth. Reusing `register_user/1` followed by `link_user_identity/3` was rejected because a failure between inserts could leave a provider-created user without its identity.

### Separate authentication, registration completion, and linking outcomes

- Exact identity plus a signed-out authentication intent logs in its owning user through `Auth.log_in_user/3`, preserving the accepted return path and normal session rotation.
- Unknown identity plus acceptable verified unused email starts username completion.
- Unknown identity plus missing, malformed, unverified, or already-owned email creates no user or identity and directs the player to local email authentication, followed by explicit linking from Account Settings.
- A link attempt succeeds only when the callback session still contains the same current D20 user and that user remains in sudo mode. It never falls back to login or registration.
- A subject already owned by the same user is idempotent. A subject owned by another user, or a second Discord subject for the same user, produces one generic conflict result.

### Derive UI availability from credentials without a provider-specific switch

Discord follows Google's operational availability contract. `auth.providers.discord.available` is true only when both runtime credentials are non-empty. Missing or blank credentials do not prevent application startup and direct Discord request or callback routes fail locally before Ueberauth starts an external transaction. AuthDialog renders a normal anchor for Discord only when available and omits the provider when unavailable. The anchor performs a full-document navigation, not an Inertia visit. Apple and Google remain independently derived from their own complete credential sets, while Facebook remains absent until it has a real availability contract. AuthDialog omits the external-provider separator and group when no provider is available so unavailable methods reserve no layout space.

Account Settings receives whether the current user already owns each Apple, Discord, and Google identity. It shows a normal link action only for an available, unlinked provider, reports the linked state without an unlink action, and reports unavailable otherwise. Discord reuses the provider-neutral `registration_completion` page already shared by Magic Link, Apple, and Google.

### Normalize failures and logs

Provider denial, cancellation, Ueberauth state failure, missing code, token or user lookup failure, malformed data, expired completion, and identity conflict create no unauthorized session or mutation. The controller redirects to the accepted safe local surface or Account Settings with an understandable retry or local-auth action. Logs contain only provider, outcome class, internal reason, and request ID. They never inspect or log the complete Ueberauth auth or failure value.

### Present authentication messages with explicit semantic severity

Extend the shared authentication prompt with a server-owned `kind` of `info`, `warning`, or `error`. Controllers classify the outcome when they create the prompt instead of making the client infer severity from message text. Recoverable ownership and reauthentication guidance uses `warning`; expired, unavailable, or failed authentication uses `error`; passive development guidance uses `info`.

Render these messages through one small shared inline-notification component. It keeps text on the left and a severity-specific symbol inside a circle on the right, uses a tinted button-like surface and visible semantic border, and includes a screen-reader label so severity is not communicated by color or icon shape alone. Each variant takes its accent from the matching global theme token: `--color-info`, `--color-warning`, or `--color-error`; informational notifications do not fall back to the primary action color. Links supplied through the child snippet inherit the current notification accent instead of reverting to the primary action color. Informational and warning messages use polite status semantics; errors use alert semantics. The local mailbox notification uses `info`, while the matching-email Discord recovery prompt uses `warning`. The `InlineNotification` name intentionally distinguishes this in-flow component from a future floating `Notification` or toast component.

The shared non-reauthentication introduction for both Register and Login describes cross-device value as sharing game sessions across devices. This avoids implying that a player can only resume a session personally and keeps the same concise copy in both dialog modes.

The dialog keeps compact vertical rhythm between its content blocks, places separators close to the methods they distinguish, and avoids an additional large margin before the Register/Login mode switch. This keeps the hierarchy visible without turning each divider into a separate empty block.

Keeping severity in the prompt contract was selected over matching message strings in Svelte because copy changes must not silently alter behavior or presentation. Repeating custom markup in AuthDialog was rejected because the same semantics are required for prompt guidance, local development guidance, and form-level failures.

## Risks / Trade-offs

- [The Discord strategy was last released in 2022] -> Pin and audit it, verify its current endpoints and response mapping in focused tests, keep production credentials absent until staging succeeds, and require a real staging journey before production availability.
- [The strategy has no PKCE support] -> Treat D20 as a confidential server client, preserve state and exact callback registration, never expose the client secret, and revisit the strategy if project policy makes PKCE mandatory.
- [The strategy accepts request-controlled OAuth parameters] -> Replace request params with the fixed provider and `identify email` scope before the Ueberauth plug runs, and test attempted scope and permissions escalation.
- [Discord may omit email or report it unverified] -> Refuse direct provider registration and direct the player through local email ownership verification before explicit linking.
- [A matching email could be mistaken for account ownership] -> Never resolve or link by email; require local authentication and sudo for linking.
- [Signed cookie sessions are readable by their holder] -> Store no provider credential or raw profile data, limit completion to UID, verified email, safe return, and expiry, and clear it on terminal outcomes.
- [Concurrent completion or linking requests race] -> Use one database transaction and existing unique constraints, and never authenticate a losing request through the winner.
- [Removing Discord credentials could strand provider-created users] -> Provider-created users have a confirmed email and retain the existing magic-link path; operational rollback preserves identity rows for later restoration.

## Migration Plan

1. Add the pinned strategy dependency, optional runtime credentials, explicit routes, adapter, controller, shared props, UI, and tests on top of the reviewed Google authentication structure and the in-progress Apple authentication implementation.
2. Run dependency advisories, focused backend and frontend tests, the complete auth regressions, strict OpenSpec validation, and broad repository checks.
3. Register the exact HTTPS staging callback `/auth/discord/callback`; configure staging credentials and manually verify registration, returning login, explicit linking, cancellation, state rejection, matching email, unverified email, safe returns, session rotation, and credential removal.
4. Register the exact production callback and configure production credentials only after staging evidence is accepted.
5. Roll back by removing either Discord runtime credential. This disables new requests and links while preserving local authentication, users, and identity mappings. Dependency and code removal can happen in a later deploy after confirming provider-created users can receive magic links.

## Open Questions

None. The lack of PKCE is an explicit accepted trade-off for this confidential server integration; a stricter policy requires a design revision before production availability.
