## Context

D20 already owns users, browser sessions, username completion, and a provider-independent `user_identities` table. Google authentication established the `D20Web.Auth` namespace, explicit provider controllers below it, bounded provider availability in shared props, and one provider-neutral `registration_completion` page shared with Magic Link. The shared authentication dialog still renders Apple as unavailable, and no Apple strategy, route, or callback adapter exists.

Apple's web authorization differs from the local and future GET callback flows. Requesting the email scope requires `response_mode=form_post`; the cross-site POST does not carry D20's current `SameSite=Lax` session cookie. Apple returns the optional user object only on first consent, while `ueberauth_apple` 0.7.0 derives the stable UID and email from the signed ID token on later callbacks. The strategy validates the token signature, issuer, audience, issued and expiration times, and nonce. D20 must not weaken its normal session cookie or trust provider email as an identity key.

The implementation is tracked by GitHub issue #191 and builds on the committed external identity foundation and username registration completion. Apple console credentials and a real HTTPS callback are unavailable in repository tests, so availability must derive only from the presence of the complete runtime credential set. Repository tests exercise D20-owned authentication outcomes and security boundaries without parsing declarative runtime configuration or duplicating Ueberauth's configuration contract.

## Goals / Non-Goals

**Goals:**

- Add a closed, credential-gated Apple authentication path with simple presence-based runtime configuration and no separate enable flag.
- Authenticate returning identities through `D20Web.Auth` and preserve safe local return behavior.
- Create a confirmed D20 user and Apple identity atomically after local username completion.
- Support Apple private relay email without requiring a personal address and without silently merging by email.
- Let a sudo-valid authenticated player explicitly link an unowned Apple identity.
- Keep callback credentials and provider payloads out of Accounts, persistence, URLs, logs, and client props.
- Keep the initial local-development authentication dialog visually aligned with production while preserving a direct mailbox action after an email request succeeds.
- Make Account Settings, Registration Completion, and Auth Confirmation available for deterministic visual inspection without Phoenix or live Inertia submissions, with their addon tooling visible beside the desktop canvas.
- Preserve local email, password, magic-link, iframe, channel, and game-session behavior.

**Non-Goals:**

- Enabling Apple in any deployed environment or storing Apple console credentials in the repository.
- Persisting Apple access, refresh, ID, or authorization tokens, raw claims, names, avatars, or relay metadata.
- Automatically linking an Apple subject to an account with the same email.
- Unlinking Apple, processing Apple server-to-server account events, or signing the player out of Apple.
- Adding a generic dynamic provider route or forcing provider-specific callback security into one generic controller.

## Decisions

### Use Ueberauth 0.10 and ueberauth_apple 0.7.0 behind explicit Apple routes

Reuse `ueberauth`, add `ueberauth_apple`, and configure one Apple strategy with `callback_methods: ["POST"]`, fixed `default_scope: "email"`, and the exact runtime callback URL. Route only `GET /auth/apple` and `POST /auth/apple/callback`; do not accept a caller-controlled provider segment. Place provider normalization and the minimal D20 flow-state helpers together at `D20Web.Auth.Apple`, with the controller at `D20Web.Auth.AppleController`, matching the namespace established by Google while retaining Apple-specific callback handling.

Version 0.7.0 is the first current release line that both includes the July 2026 Apple ID-token claim-validation fix and removes vulnerable older HTTP dependencies. The strategy validates Ueberauth state and reuses it as the Apple nonce. A custom Apple OAuth implementation was rejected because it would duplicate signature, claim, state, nonce, and token-exchange logic with a larger security surface. A generic provider controller was rejected because Apple's cross-site POST and cookie binding differ materially from Google's GET callback, while a dynamic route would weaken the allowlist.

### Request only email and force server-owned authorization parameters

D20 needs email to satisfy the current required `users.email` field, but does not use the Apple name. The request therefore uses only the `email` scope. Before Ueberauth builds the redirect, the controller records the D20 attempt and removes caller-supplied scope and OAuth options so query parameters cannot expand or change the authorization request.

Requesting email forces Apple's form POST response. The normal browser and Inertia pipelines retain Phoenix CSRF protection. Only the explicit Apple POST callback uses a narrow pipeline without Phoenix form-CSRF rejection; Ueberauth state and the ID-token nonce remain mandatory for that cross-site request.

The callback pipeline fetches the session only for successful signed-out authentication and recovery messages. It does not derive an anonymous actor or otherwise mutate a missing Lax application session. This prevents the cross-site callback response from replacing the authenticated session cookie that the browser withheld during an Account Settings linking callback.

### Keep D20 session cookies Lax and use one encrypted short-lived Apple flow cookie

Do not change `_d20_key` from `SameSite=Lax`. The Apple strategy already emits its state cookie as `SameSite=None; Secure` for `form_post`. D20 adds one encrypted, authenticated, HTTP-only flow cookie scoped to `/auth/apple`. Its attempt phase uses `SameSite=None; Secure` so the Apple POST callback can receive the D20 intent, safe local return path, and expected link user. The callback consumes that phase within 10 minutes.

An unknown identity callback replaces the attempt phase with a `SameSite=Lax; Secure` registration phase in the same cookie. That phase contains only the normalized Apple subject, provider-authenticated email, and safe return path. It never appears in a URL, page prop, or log, expires after 10 minutes, remains available only across retryable username validation, and is deleted after success, expiry, corruption, cancellation, or a terminal conflict.

An authenticated link callback writes its bounded `linked`, `conflict`, or `failed` result to a separate encrypted, authenticated, HTTP-only `SameSite=Lax; Secure` cookie scoped to `/users/settings`. The Apple provider module owns the cookie, accepts only those three results, and expires it after 10 minutes. The settings router invokes that module as a plug after authentication and sudo checks. The plug consumes the cookie, verifies a claimed successful link against durable Apple identity ownership, writes the one-use Phoenix flash, and redirects to the clean Account Settings URL. Query parameters are neither produced nor trusted, and `UserSettingsController` remains provider-neutral.

Use `Phoenix.Token.encrypt/4` and `Phoenix.Token.decrypt/4` for confidentiality, integrity, and age validation instead of maintaining custom key derivation, message encryption, JSON serialization, timestamps, and lifetime checks. Authenticated linking is authorized at request start by the existing current D20 user and `Accounts.sudo_mode?/1`. The encrypted attempt phase binds the callback to that exact user because the Lax D20 session is intentionally absent from the cross-site POST. Ueberauth state and Apple nonce remain the provider transaction authority; the D20 cookie carries only application workflow state. Storing provider attempts in PostgreSQL was rejected because the encrypted cookie plus one-use Apple authorization code and state/nonce checks provide the required short-lived transaction without a migration or cleanup job.

### Normalize Apple results at the web boundary

`D20Web.Auth.Apple` is the only D20 module that accepts an Apple `Ueberauth.Auth`. It accepts only provider `:apple`, an exact non-empty UID within the existing 255-byte identity limit, and an optional syntactically valid email. The adapter returns only `%{provider: :apple, provider_uid: uid, email: email_or_nil}`. It does not pass credentials, raw info, names, or Ueberauth structs into Accounts.

The email comes from the Apple strategy after ID-token signature and registered-claim validation. A returning stored subject does not require email and never updates the D20 account email. An unknown subject requires a valid email because D20 currently requires one. Private relay addresses pass the same email policy as personal addresses and are stored without special-case transformation.

### Resolve identity before applying registration or linking policy

For a signed-out callback, an exact `(apple, subject)` match logs in its owning user through `Auth.log_in_user/3`, which creates a D20 token and renews the browser session. An unknown subject with an unused valid email receives username completion. An unknown subject whose email already belongs to D20 receives a generic existing-account recovery message and no identity or session.

Add an Accounts transaction that inserts a confirmed user with validated email and username and then inserts the Apple identity. Database uniqueness on user email, username, `(provider, provider_uid)`, and `(user_id, provider)` is the concurrency authority. Any losing insert rolls back the complete transaction. The controller retries only username validation; email or identity ownership conflicts are terminal and never authenticate by resolving a race winner.

For explicit linking, resolve the subject first. The same user's existing mapping is idempotent, an unowned subject is linked to the attempt-bound user, and any other ownership or per-user Apple conflict returns one generic conflict result. Linking never changes the current D20 user or email.

### Expose bounded provider state to Inertia

Extend the required shared `auth` prop with `providers.apple.available` without changing `providers.google.available`. The authentication dialog renders normal full-document Google and Apple links independently according to their bounded availability and retains disabled unavailable controls otherwise. The Apple link carries only a safe return path; authentication and linking intent are selected by explicit routes and server-owned controller state rather than dialog input. It does not use Inertia navigation.

Provider action copy follows the dialog intent rather than provider-specific wording: Register mode uses `Sign up with <provider>` and Login mode uses `Sign in with <provider>` for Google, Facebook, Apple, and Discord. The same label is retained when a provider is unavailable so availability does not change the action's accessible name.

Account Settings receives independent Google and Apple availability and linked states. Its shared router scope enforces authentication and sudo mode once for settings and both provider-link routes, so individual controllers do not duplicate those guards. It renders Link with Apple only when Apple is available and unlinked, using the explicit `/users/settings/auth/apple` route and the same sudo boundary as Google. The cross-site Apple POST callback cannot safely write flash into the absent Lax session, so the Apple provider module redirects with one bounded encrypted result cookie. On the first same-site Account Settings GET, the same provider module consumes the cookie, validates a successful result against durable link state, converts it to the same one-use Phoenix flash presentation used by Google and Discord, and redirects to the clean settings URL. Neither controller parses Apple query parameters or defines Apple-specific result handling. Apple page props contain only durable availability and linked state, never a callback-result field. Unknown Apple identities render the shared `registration_completion` page with only email, a server-owned Apple submission action, a server-cookie credential discriminator, and a cancel action. The encrypted registration state never enters page props, URLs, or form fields.

### Keep local mailbox guidance contextual to email success

Email registration and magic-link success results use the shared informational `InlineNotification` presentation rather than a separate success-specific surface. When `auth.local` is true, the result appends a `/dev/mailbox` link after its normal production copy. When `auth.local` is false, the same notification renders without development guidance. AuthDialog does not render a standalone mailbox notice before a successful email request, so the initial local-development dialog remains representative of production while the mailbox action appears at the point where it is useful.

The shared notification keeps its text in the flexible Grid column and its severity symbol in the trailing intrinsic column. Multi-line content top-aligns the symbol with the first line instead of centering it against the entire paragraph. The text column uses `text-wrap: pretty` as a progressive enhancement, falling back to normal wrapping where unsupported. Short linked labels use the widely supported `white-space: nowrap` fallback followed by `text-wrap: nowrap`, so `local mailbox` remains one readable action without relying on JavaScript. Balanced or justified text was rejected because this is body copy inside a visible full-width surface, where either choice would introduce misleading empty space or uneven word spacing.

### Isolate account page stories at the Inertia form boundary

Storybook imports the production Account Settings, Registration Completion, and Auth Confirmation page components and supplies typed page props for their meaningful server-owned states. Account Settings covers its required established username with provider availability differences. Registration Completion covers Magic Link and Apple server-cookie completion, including the provider cancel action. Auth Confirmation covers regular sign-in and sudo reauthentication.

The Storybook Vite configuration replaces only the `@inertiajs/svelte` module used inside the isolated catalog with a story-owned boundary. Its `Form` renders a normal HTML form, supplies deterministic idle slot state with no validation errors, and prevents submission. The remaining exports provide inert navigation and a minimal guest page so the existing shared-component barrel stays buildable without a server. The boundary does not imitate server success, failure, or navigation. Production builds and frontend tests keep their existing Inertia modules and mocks, so catalog interaction cannot contact Phoenix while the stories still exercise the real production page markup and styles.

The Storybook manager uses its native UI configuration API to open the addon panel on the right in the desktop layout. Its visibility customisation keeps the panel enabled for every story while preserving Storybook's native user controls and panel sizing. This applies once at the catalog boundary so Controls, Actions, Interactions, and other installed addon panels appear beside every story without repeating per-story parameters. Storybook retains its responsive mobile layout on narrow viewports.

### Generate the client secret inside the Apple provider boundary

Apple is available when the Services ID, Team ID, Key ID, base64-encoded private key, and callback URL environment variables are all set. An unset variable leaves Apple unavailable without failing application startup. Supplying the complete set is the operator's decision to enable Apple, so D20 preserves the source values in one `Ueberauth.Strategy.Apple` configuration entry without normalizing, trimming, parsing, or validating them during startup. Invalid source credentials fail through the provider flow when first used.

`D20Web.Auth.Apple.provider_config/0` gives Ueberauth a client-secret callback instead of a pre-generated token. Ueberauth calls `D20Web.Auth.Apple.client_secret/1` while building the Apple OAuth client; the provider module decodes the configured private key and delegates JWT signing to `UeberauthApple.generate_client_secret/1`. The generated JWT is ephemeral and is not stored in application configuration, deployment secrets, persistence, or client props. Generating it for each provider flow removes manual JWT rotation and avoids D20-owned cache, lifetime, and refresh-window machinery. The long-lived private key remains owned by the deployment secret store and must be rotated only when Apple key policy or compromise requires it.

## Risks / Trade-offs

- [Apple POST callback cannot read the normal D20 session] - Bind intent, return path, and link user in the encrypted attempt cookie, carry only a bounded encrypted outcome cookie to the first same-site settings request, convert it in the Apple provider module to one-use flash, and never relax or replace the global session cookie.
- [A provider or token-exchange failure may contain credentials in nested structs] - Map failures to internal atoms, return bounded user-facing messages, and defer application-specific OAuth diagnostics until D20 has a shared logging design.
- [Concurrent registration or linking can race] - Treat database constraints and the Accounts transaction as authoritative and never authenticate a losing request through its winner.
- [Apple returns no usable email for an unknown subject] - Refuse registration and provide local email authentication as the recovery path; returning stored subjects remain usable without email claims.
- [Private relay delivery requires Apple console and outbound-domain configuration] - Keep enablement operator-owned, document the variables and relay prerequisite, and require staging delivery verification before production enablement.
- [Operator supplies an invalid credential or callback value] - Keep D20 startup independent of optional Apple validation and surface the failure through the closed provider flow without creating a session or identity.
- [The application receives a long-lived Apple private key] - Keep it only in the deployment secret store, never expose it through props or logs, and revoke it in Apple Developer if it is compromised.
- [JWT generation adds work to each provider flow] - Delegate signing to the installed Ueberauth Apple library and avoid a cache until measured provider traffic justifies additional state.
- [The Apple strategy performs network calls that cannot be exercised with real credentials in CI] - Test D20-owned availability outcomes, cookies, normalization, transactions, controller outcomes, routes, and UI state with injected auth/failure data; leave declarative configuration and Ueberauth internals to their owning boundaries and retain a manual HTTPS staging gate.
- [Ueberauth Apple does not provide PKCE] - Accept the confidential web-client authorization code flow with state and nonce for this provider slice, record the limitation, and revisit the strategy if D20 policy makes PKCE mandatory.
- [The local mailbox becomes less discoverable before an email request] - Show the link immediately after successful registration or magic-link submission, when the developer has a concrete message to inspect, and keep the initial dialog aligned with production.
- [A page story could accidentally submit to a live application] - Replace the Inertia form module only in Storybook, render native form semantics, and prevent every catalog submission without changing production imports or behavior.
- [A persistent side panel can constrain a narrow canvas] - Force the panel only through the manager's supported visibility hook and preserve Storybook's responsive mobile layout instead of overriding it with CSS.

## Migration Plan

1. Deploy the code without Apple runtime credentials. Apple remains visibly unavailable and all current authentication methods are unchanged.
2. In staging, configure the Apple App ID, Services ID, Team ID, Sign in with Apple Key ID, base64-encoded private key, exact HTTPS callback, and private relay outbound source. Set the documented runtime variables and start the release; the complete set makes Apple available without a separate flag or pre-generated client secret.
3. Verify registration with personal and relay email, returning login without first-consent profile data, safe return paths, explicit linking, cancellation, invalid state/nonce, conflict handling, session rotation, and disabling the provider.
4. Deploy the complete production credential set only after automated checks, dependency audit, exact callback registration, private relay delivery, and staging journeys pass.
5. Roll back operationally by removing the Apple runtime credentials; existing D20 users and identity rows remain valid through local methods. A code rollback removes routes, UI availability, adapter/controller, configuration, and dependencies without a database rollback.

## Open Questions

None. Production Apple console setup and staging verification are explicit enablement gates, not unresolved implementation decisions.
