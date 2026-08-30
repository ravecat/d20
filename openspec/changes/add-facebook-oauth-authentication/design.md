## Context

D20 owns users, local authentication, session rotation, sudo checks, a provider-neutral identity table, and complete Google, Discord, and Apple provider flows. The current account model permits completed users with null email when the same transaction creates a uniquely owned external identity.

Facebook returns an app-scoped stable user `id` and may return an `email` field when the `email` permission is granted. The email can be absent and Facebook exposes no verification assertion equivalent to Google `email_verified` or Discord `verified`. D20 therefore cannot use Facebook email as identity or merge proof. Product policy nevertheless accepts a syntactically valid email returned consistently by the Facebook callback as an optional account candidate, using the same server-owned registration transaction and null-email fallback as the other providers. The browser must never collect or replace that value.

`ueberauth_facebook` 0.10.0 is the current Hex release but was published in 2022. Its default token URL is Graph API v2.8, while its OAuth client accepts runtime overrides for `site`, `authorize_url`, and `token_url`. D20 must override both Graph requests to the explicit Graph API v26.0 endpoints, fix scope and fields, strip supported request overrides, pin and audit the package, and keep credentials absent from production until a real Meta compatibility journey passes.

## Goals / Non-Goals

**Goals:**

- Add Facebook as a credential-derived method to Register, Login, Account Settings, and Storybook authentication workflows.
- Resolve returning players only through exact `(:facebook, app_scoped_user_id)` ownership and create D20 sessions only through `D20Web.Auth`.
- Give Facebook the same username-only registration completion and optional-email provider-only fallback as Google, Discord, and Apple.
- Keep provider UID and optional email candidate in short-lived server-owned state and reject browser-controlled email.
- Atomically create the completed user and Facebook identity without implicit email matching or partial persistence.
- Preserve safe local returns, Ueberauth state validation, sudo-bound linking and reauthentication, session rotation, generic ownership conflicts, redacted diagnostics, and credential-removal rollback.
- Use `FACEBOOK_OAUTH_CLIENT_ID` and `FACEBOOK_OAUTH_CLIENT_SECRET`, exact callback registration, and Meta app-role or test-user constraints.

**Non-Goals:**

- Treat Facebook email, profile data, account verification, or a matching D20 email as identity or ownership proof.
- Collect or verify a replacement email during Facebook registration.
- Import names, avatars, friends, contacts, posts, pages, or other social data.
- Persist Facebook access tokens, refresh tokens, authorization codes, raw claims, or profile payloads.
- Unlink or replace a Facebook identity, support more than one Facebook identity per user, or sign the player out of Facebook.
- Generalize all providers or replace the accepted Ueberauth boundary in this slice.
- Claim production readiness without current Meta console and end-to-end staging evidence.

## Decisions

### Keep Ueberauth but override every stale Facebook endpoint

Add and pin `ueberauth_facebook` 0.10.0. Configure the provider with fixed `default_scope: "email"` and `profile_fields: "id,email"`. Configure its OAuth client with `site: "https://graph.facebook.com/v26.0"` and `token_url: "https://graph.facebook.com/v26.0/oauth/access_token"`; keep the current authorization endpoint `https://www.facebook.com/dialog/oauth`. This makes both token exchange and `/me` lookup explicitly versioned while retaining the package's state validation and `appsecret_proof` behavior.

The controller removes caller-supplied `auth_type`, `scope`, `locale`, `display`, `redirect_uri`, `response_type`, `client_id`, and `state` before Ueberauth runs. Only explicit Facebook routes are exposed.

A custom OAuth implementation was rejected because it would duplicate state, token exchange, and callback error mapping. Switching all providers to Assent was rejected as unrelated scope. Using package defaults was rejected because Graph API v2.8 is obsolete. The missing strategy-level PKCE support is accepted for the confidential server-side client only while state, exact callbacks, client-secret exchange, and HTTPS staging remain mandatory.

### Normalize the app-scoped user ID and optional email candidate

`D20Web.Auth.Facebook` accepts only Facebook `Ueberauth.Auth`, requires a non-empty UID within the existing 255-byte limit, and verifies that the raw `/me` `id` equals the Ueberauth UID. It returns only provider, provider UID, and an optional normalized email candidate when raw and normalized email values agree and the value passes D20 syntax validation. Credentials and all unrelated raw fields stop at this adapter.

The app-scoped Facebook ID is the only identity key. Email does not affect returning login, linking, or reauthentication. For a new account, the candidate is carried only in signed, session-bound registration state. No page prop or form field can replace it.

Facebook exposes no separate email-verification assertion. Accepting the returned email as a candidate is an explicit product decision for consistent provider onboarding, not evidence that email identifies the Facebook account. D20's exact provider UID and identity uniqueness remain authoritative.

### Use the provider-neutral username-only registration sequence

An unknown Facebook callback stores short-lived session-bound registration state containing only provider UID, optional email candidate, nonce, and safe return path, then renders the shared provider-neutral registration-completion page. The page displays the candidate as read-only text when present, asks only for username, and displays no email field or email-specific action.

The completion POST accepts username and remember-me only. The controller injects the server-owned email candidate and calls `Accounts.register_user_with_identity/3`, the same atomic operation used by Google, Discord, and Apple. A successful transaction creates one confirmed user and one Facebook identity, clears completion state, rotates the D20 session, and returns to the accepted local destination.

If the candidate is absent or invalid, registration proceeds with null email. If it is already owned, Accounts discards it without resolving or modifying the owner. If the email unique constraint loses a race, Accounts retries the complete transaction once with null email. Username and identity conflicts remain terminal and controlled. A losing request never authenticates through a concurrent winner.

A Facebook-only mailbox confirmation, email token, second Facebook authorization, pending-registration table, and strict email-backed transaction were rejected because the current provider-only account invariant makes them unnecessary and they introduce avoidable abandonment points.

### Preserve no-merge ownership semantics

An exact existing identity under normal authentication logs in its owner through `Auth.log_in_user/3`. Unknown identity starts username completion even when its email candidate matches another D20 user. No email branch authenticates, merges, or links an existing account.

Initial authentication and link intents use issued-at session state and expire after 10 minutes. Link intent is bound to the initiating D20 user and both request and callback enforce current sudo mode. Reauthentication is bound to the current D20 user and succeeds only when the returned Facebook identity belongs to that same user. No branch falls back from reauthentication or linking to normal login or registration.

### Keep the completion UI provider-neutral

Magic Link continues to render its pending email as read-only text and submit its confirmation token. Google, Discord, Apple, and Facebook all ask only for username, display an optional server-owned email candidate when present, and remain completable when it is absent. Provider identity, credentials, authorization codes, tokens, and raw callback data never appear in page props or form fields.

The removed editable-email and check-email branches simplify autofocus, button copy, validation, tests, Storybook states, and mobile completion. The username remains a labelled required input with `autocomplete="username"` and `enterkeyhint="done"`. Storybook uses the generic Auth Provider Registration Completion story for this shared page; focused frontend and controller tests retain Facebook-specific coverage with and without an email candidate instead of duplicating visual stories.

### Derive Facebook availability from runtime credentials

Facebook is available only when both `FACEBOOK_OAUTH_CLIENT_ID` and `FACEBOOK_OAUTH_CLIENT_SECRET` are non-blank. Missing credentials do not prevent startup. Shared Inertia props expose only `auth.providers.facebook.available`; AuthDialog and Account Settings omit Facebook when unavailable. Direct request and callback routes fail locally before Ueberauth starts an external transaction.

No separate provider enable flag is added. Production credentials remain absent until compatibility and staging checks pass.

### Keep failure output understandable and diagnostics redacted

Provider cancellation, state mismatch, missing code, token or `/me` failure, malformed UID, expired registration state, duplicate username, provider ownership conflict, replay, and link conflict create no unauthorized session or partial identity. Browser messages provide retry, local authentication, or Account Settings recovery without exposing another account. Logs contain provider, outcome class, internal reason, and request ID only.

## Risks / Trade-offs

- [The Facebook strategy is old and defaults to Graph API v2.8] -> Pin it, override token and profile requests to v26.0, test resolved client configuration, run dependency audit, and require a real Meta staging journey before production credentials are installed.
- [The strategy has no PKCE support] -> Use it only as a confidential server-side client with state, exact HTTPS callback registration, client-secret exchange, and redacted credentials; revise the design if PKCE becomes mandatory.
- [Meta can omit email] -> Complete registration with the exact Facebook identity and null email; users may later add and D20-verify email in Account Settings.
- [Meta exposes no separate email-verification assertion] -> Never use email as identity or merge proof, accept it only from the validated server callback, never permit browser replacement, and preserve exact UID ownership as the authentication authority.
- [Two provider accounts can return the same email] -> Keep one canonical email owner through the existing unique index and create later accounts with null email without merging.
- [Credential removal can strand provider-only users] -> Keep local email and password addition available in Account Settings, preserve identity rows, document the risk, and verify credential-removal behavior before production enablement.
- [Development mode excludes ordinary Facebook accounts] -> Document app roles and Meta test users and require those accounts for local and staging checks.
- [Meta may reject plain local HTTP configuration] -> Register the exact local callback when accepted; otherwise use an HTTPS tunnel with matching Phoenix external URL and Meta redirect configuration.

## Migration Plan

1. Add the pinned dependency, explicit current endpoints, runtime credentials, adapter, controller, routes, shared props, UI, Storybook workflows, and focused tests.
2. Align Facebook registration with the current nullable-email provider-only account model: keep an optional server-owned email candidate, ask only for username, use the generic atomic Accounts transaction, and remove the obsolete mailbox-verification sequence.
3. Run formatting, targeted backend/frontend tests, dependency audit, strict OpenSpec validation, broad `just check`, and browser validation with Facebook unavailable and configured test stand-ins.
4. Create a Meta Development-mode app, add Facebook Login, register the exact local or HTTPS-tunnel callback `/auth/facebook/callback`, add app-role users or Meta test users, and verify registration with unused, missing, malformed, and already-owned email candidates, returning login, explicit linking, cancellation, invalid state, safe return, session rotation, and credential removal.
5. Register the exact staging and production HTTPS callbacks. Configure production credentials only after staging evidence and current Graph API compatibility are accepted.
6. Roll back operationally by removing either Facebook credential. This disables new Facebook requests and links while preserving local authentication, users, and identity mappings. Before removal, ensure provider-only Facebook users retain another authentication method or restore provider availability.

## Open Questions

None. Manual Meta console and end-to-end evidence remain required delivery tasks and cannot be replaced by automated tests.
