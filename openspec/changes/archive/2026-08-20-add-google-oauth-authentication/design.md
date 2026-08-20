## Context

D20 already owns local accounts in `D20.Accounts`, browser authentication in `D20Web.Auth`, and external identity ownership in `user_identities`. The shared Svelte account dialog renders Google in both Register and Login modes, but both controls are disabled. Account Settings is already authenticated and sudo-protected.

The completed `establish-external-provider-identity-foundation` change provides exact Google identity lookup and constrained linking without storing credentials or profile data. A user still requires a unique email, and new registrations complete by choosing an immutable username. The normal D20 session cookie is `SameSite=Lax`, so it is available on Google's GET callback, but its signed cookie payload is readable and must not contain provider credentials or raw claims.

The accepted provider research selects Ueberauth as the web-boundary framework and requires a provider-specific compatibility gate. As of this design, Hex publishes `ueberauth` 0.10.8 and `ueberauth_google` 0.12.1. The Google strategy maps `Ueberauth.Auth.uid` from the Google `sub` field but accepts request-supplied scope and related OAuth parameters unless D20 removes them first. Its default token endpoint is older than the endpoint in Google's current discovery document and must be overridden.

## Goals / Non-Goals

**Goals:**

- Enable one minimal Google authorization-code flow for registration and login from the shared account dialog.
- Resolve returning players only through the exact stored Google subject.
- Create a new user, confirmed email, username, and Google identity atomically after explicit local completion.
- Preserve a provider-verified email as the account contact address while requesting no mailbox access.
- Reuse one provider-neutral registration-completion page for Magic Link, Google, and future providers.
- Let a recently authenticated user explicitly link Google from Account Settings.
- Preserve D20 session fixation protection, safe local returns, local authentication methods, and provider-independent Accounts boundaries.
- Fail safely and observably without persisting or logging Google credentials or raw payloads.
- Derive Google availability from runtime credentials so missing configuration never prevents the rest of the application from starting.

**Non-Goals:**

- Automatic account merging by email.
- Using Google for sudo reauthentication in the shared dialog.
- Unlinking Google or replacing a linked Google subject.
- Importing Google profile, avatar, contacts, refresh tokens, or access to other Google APIs.
- Supporting Google Workspace domain restrictions.
- Adding Facebook, Apple, or Discord request and callback behavior.
- Changing game, session-channel, iframe module, or public protocol contracts.

## Decisions

### Use an explicit Ueberauth Google boundary

Add reviewed `ueberauth` and `ueberauth_google` dependencies and configure only the `google` strategy. Add explicit `GET /auth/google` and `GET /auth/google/callback` routes instead of a public `:provider` route. `D20Web.Auth.GoogleController` owns request preparation and callback outcomes, while a small `D20Web.Auth.Google` adapter is the only D20 module that accepts `Ueberauth.Auth` or `Ueberauth.Failure`.

The controller pipeline stores an accepted safe local `return_to`, records either authentication or link intent, and removes caller-supplied `scope`, `prompt`, `access_type`, `include_granted_scopes`, `login_hint`, `hd`, and `hl` values before Ueberauth runs. The provider configuration fixes the scope to `openid email`; `profile` and all Google API scopes are excluded. Ueberauth state validation remains enabled.

Runtime configuration overrides the strategy token endpoint with `https://oauth2.googleapis.com/token` and the userinfo endpoint with `https://openidconnect.googleapis.com/v1/userinfo`, matching Google's discovery document. A compatibility test or spike must confirm those endpoints, authorization code exchange, state rejection, subject extraction, verified-email extraction, and error mapping before the provider is deployed to production.

A custom OAuth implementation was rejected because Ueberauth already supplies the Plug lifecycle and state validation selected by the accepted architecture. A dynamic provider route was rejected because unsupported strategies and arbitrary provider parameters must fail closed.

### Normalize only the stable subject and verified email

The adapter accepts the `uid` produced by the configured Ueberauth Google strategy as Google's stable `sub` and passes it to Accounts as an opaque identity key without imposing another provider-format validation. Ueberauth owns extraction from the validated Google response, while the existing provider-independent `UserIdentity` changeset remains authoritative for persistence constraints.

For an unknown identity, registration additionally requires a syntactically valid email and a literal verified-email result from Google's transient userinfo payload. For an already linked identity, email absence or change does not prevent login because the stored provider subject is authoritative. The adapter immediately discards credentials, tokens, and all remaining raw fields after normalization. It never passes a Ueberauth struct into `D20.Accounts`.

The verified provider address becomes the canonical D20 account email during new-account creation. Completion ignores any browser-submitted replacement email and takes the address only from authenticated completion state. Future providers follow the same rule: request their minimal email-address claim when available, accept only a provider-asserted verified address, and require separate D20 email collection and verification before account creation when no such address exists. Access to an email address is not access to the user's mailbox, contacts, or messages, so no mail or contacts API scope is requested.

Persisting the account email enables account and transactional delivery but does not itself grant marketing consent. Marketing subscriptions and notification preferences remain a separate product concern.

Using Google email as an identity key was rejected because Google documents that email can change and need not uniquely identify the provider account. Requesting `profile` or Gmail access was rejected because D20 needs neither profile data nor mailbox access to complete registration.

### Route callback outcomes by explicit intent

The request phase stores the application-owned intent directly in the signed session before redirecting to Google:

- `:authenticate` for both account-dialog Google actions, with the accepted safe local return path held by existing `Auth` session behavior.
- `{:link, user_id}` only from an authenticated and sudo-valid Account Settings route, bound to the current D20 user ID and a settings return path.

The callback consumes the intent. Because D20 is the only writer and the session is signed, the adapter does not add timestamps, structural validation, or a separate intent expiry policy. A missing intent or a link intent whose user binding no longer matches never falls back to authentication or linking. Ueberauth state validation owns the provider request/callback correlation, while the link callback rechecks the current D20 user and sudo freshness. The GET callback retains the D20 session under the existing `SameSite=Lax` policy, so no global cookie-policy change is needed.

For authentication intent:

- An exact identity match calls `Auth.log_in_user/3`. Signed-out login therefore renews and clears the previous browser session before issuing the normal D20 token.
- An unknown identity with an acceptable verified email starts registration completion.
- An unknown identity whose email already belongs to a D20 account does not create, link, or authenticate anything. The player is directed to use an existing method and link Google from Account Settings.

For link intent:

- The callback rechecks the same authenticated user and sudo age before linking.
- An identity already owned by that user is treated as an idempotent success.
- An identity owned by another user, or a different Google identity already linked to the current user, returns one generic conflict without revealing ownership.

Inferring intent solely from whether a callback has a current user was rejected because another tab or session change could turn a login attempt into an account-link mutation.

### Keep email contact and identity ownership separate

`users.email` is one case-insensitively unique contact and Magic Link address for a D20 account. `user_identities` owns authentication mappings by exact `(provider, provider_uid)`. Email is not an identity merge key, even when a provider asserts it as verified.

| Existing state | New attempt | Outcome |
| --- | --- | --- |
| Email or Magic Link account | Unknown provider identity with the same email | Reject provider authentication and linking; require login to the D20 account followed by explicit sudo-protected linking |
| Provider-created account | Direct registration with the same email | Reject duplicate account creation through the unique email constraint |
| Provider-created account | Magic Link request for the same email | Send the link and authenticate the existing D20 account |
| Provider-created account | Exact linked provider and UID | Authenticate the identity owner regardless of the provider's current email claim |
| One provider identity | Different unknown provider with the same email | Do not merge; require explicit linking from the authenticated D20 account |

This asymmetry is intentional. A verified provider email is acceptable contact data for creating a new account when the address is unused, but it is not sufficient proof to mutate ownership of an existing account. Anyone who controls the canonical mailbox can authenticate through Magic Link by design. Accidental duplicate accounts remain possible when providers return different addresses, aliases, or privacy relays; avoiding that risk requires explicit linking, not heuristic merging.

### Complete new-account registration through one provider-neutral page

An unknown Google callback does not insert a partial user. Instead it stores a short-lived authenticated completion payload containing only the normalized Google subject, verified email, issued-at value, and a random nonce. The signed session stores the matching nonce and the safe local return path. Verification relies on the signed token result and exact nonce pattern match instead of repeating type and length checks for values written by the same boundary. The payload must expire after at most 10 minutes, must not appear in a URL or log, and is cleared on success, expiry, cancellation, or terminal conflict.

The existing Magic Link registration completion is separated from confirmed-user login and becomes one provider-neutral Inertia page. The page asks only for the required username, keeps provider credentials out of browser props, and submits through a server-provided same-origin action. Magic Link supplies its existing confirmation token as a hidden credential. Google supplies no browser credential: its provider subject and verified email remain in the short-lived session-bound proof. Future OAuth providers can reuse the same page without adding provider-branded Svelte pages.

The Google completion POST verifies the payload, session nonce, age, and CSRF token before calling a new provider-independent Accounts operation. That operation uses one `Ecto.Multi` transaction to:

1. Insert a user with the verified email, requested username, and `confirmed_at` set.
2. Insert the Google identity through the existing provider-independent identity rules.
3. Roll back the user if email, username, provider ownership, or per-user provider uniqueness fails.

On success, the controller clears completion state and authenticates through `Auth.log_in_user/3`. Username validation leaves the valid completion state available for another submission. A replay after success or a concurrent completion cannot create a second user because both user and identity uniqueness are database-enforced, and a replay conflict never authenticates the caller.

Creating the user during the callback was rejected because abandoned username completion would leave partial provider accounts. Storing an access token for later completion was rejected because registration requires only the normalized subject and verified email. A separate Google completion page was rejected because username selection is a D20 registration concern, not a provider concern, and would require duplicate pages for Discord, Apple, or later providers.

### Reuse Account Settings for explicit linking

`UserSettingsController.edit/2` exposes whether the current user already owns a Google identity. The Svelte page adds a Sign-in methods section with a normal full-page Link Google anchor only when Google is unlinked. The link request and callback both require the authenticated user and current sudo proof. This reuses the existing recent-authentication boundary and avoids introducing provider policy into Svelte.

Unlinking is excluded because D20 has not yet defined recovery policy for removing a user's last practical authentication method.

### Group web authentication flows under one namespace

`D20Web.Auth` is the shared browser-authentication interface for D20 session creation, rotation, cookies, access plugs, safe returns, and Inertia authentication prompts. Provider-specific adapters live below that interface, beginning with `D20Web.Auth.Google`, while provider HTTP orchestration lives in matching controller namespaces such as `D20Web.Auth.GoogleController`.

This layout keeps provider normalization and transient OAuth state separate from generic D20 session behavior while making every web authentication flow discoverable under `lib/d20_web/auth/` and `lib/d20_web/controllers/auth/`. `D20.Accounts` remains outside the web namespace as the provider-independent account and identity owner.

### Derive availability from credentials without a provider-specific enable switch

Add `GOOGLE_OAUTH_CLIENT_ID` and `GOOGLE_OAUTH_CLIENT_SECRET` to runtime configuration and `envs/.env.example`. Google is available when both environment variables are set. D20 reads the application-owned credential keyword list directly, passes supplied values through unchanged, and does not normalize, trim, inspect, or defensively revalidate the known configuration shape; an empty or whitespace-only value therefore still counts as supplied. An unset credential does not prevent application startup: the rest of D20 remains usable while Google request and callback routes fail locally before Ueberauth can start an external transaction. Runtime configuration never substitutes test credentials. Tests that require an available Google provider own their fixed non-secret configuration in test setup instead of changing runtime behavior. Secrets are read at runtime and are never exposed in Inertia props or logs.

The shared Inertia auth prop exposes only provider availability, never credentials. The shared account dialog renders Google as a normal full-document link when available and as a disabled control with visible unavailable status otherwise. Account Settings combines the same availability with linked state and does not offer a link action while unavailable. Facebook, Apple, and Discord remain disabled and unchanged.

A provider-specific runtime enable switch was rejected because product feature flags will be owned by a separate mechanism. Availability is a derived operational state, not a rollout decision. A provider outage after a configured request begins cannot be known during page rendering and continues through the existing generic failure path with local email alternatives.

### Map failures to safe local UI and redacted diagnostics

Provider cancellation, state mismatch, missing authorization code, token or userinfo failure, malformed provider results, unverified registration email, expired completion proof, and ownership conflict create no D20 session or identity mutation. Authentication failures return to an accepted safe local page and use the existing one-time auth prompt to open Login mode with a retry or local-auth alternative. Registration validation stays on the shared provider-neutral completion page with field-specific errors where safe.

Server diagnostics include provider, outcome class, internal reason atom, and request ID only. They exclude authorization codes, access tokens, refresh tokens, ID tokens, Ueberauth structs, raw userinfo, email, and provider subject. Detailed provider errors are not reflected to the browser.

## Risks / Trade-offs

- [The published Google strategy has no built-in PKCE flow] -> Treat this first release as a confidential server-side client, keep Ueberauth state validation and the client-secret token exchange over HTTPS, record the security exception in the compatibility evidence, and do not add an unreviewed custom strategy. If PKCE becomes a release requirement, revise this design and replace the strategy before enabling Google.
- [The provider package defaults can lag Google's current endpoints] -> Override endpoints from the current Google discovery document and verify the complete flow in staging before enablement.
- [A completion proof is a short-lived bearer artifact] -> Bind it to the initiating signed session and random nonce, limit it to 10 minutes, exclude it from URLs and logs, clear it on terminal outcomes, retain no provider credential, and never authenticate on replay conflict.
- [Google email matches an existing local account] -> Fail closed and require local authentication plus explicit linking; never use the email match as ownership proof.
- [Concurrent registration or linking races] -> Put user and identity creation in one transaction and rely on existing database uniqueness constraints for the losing request.
- [Google credentials are revoked or invalid after provider-only registration] -> Provider-created users retain a confirmed email and can use the existing magic-link login path; identity rows remain valid after credentials are restored.
- [An authenticated session changes while Google is open] -> Bind link intent to the initiating user and recheck both user identity and sudo freshness on callback.
- [Provider errors leak sensitive callback data] -> Normalize at one adapter, use a fixed redacted log schema, and test that credentials and raw payloads are absent.

## Migration Plan

1. Add and lock the reviewed dependencies, endpoint overrides, runtime credentials with safe unavailable degradation, explicit routes, adapter, Accounts transaction, controllers, UI, and automated tests.
2. Run dependency advisories, targeted backend and frontend checks, the complete auth regression suite, strict OpenSpec validation, and broad repository checks.
3. Register the exact HTTPS staging callback `/auth/google/callback`, configure staging credentials, and manually verify registration, returning login, explicit linking, cancellation, state rejection, duplicate email, conflict, safe return, and session rotation.
4. Register the exact production callback, configure production credentials, and deploy only after staging evidence is accepted.
5. Roll back the application release and revoke or rotate the Google client credentials if provider entry points must be removed. Existing users and identity mappings remain intact, and provider-created users retain magic-link authentication through their confirmed email.

## Open Questions

None. PKCE support is an explicit accepted trade-off for this confidential server-side provider slice; any policy change that makes PKCE mandatory requires a design revision before enablement.
