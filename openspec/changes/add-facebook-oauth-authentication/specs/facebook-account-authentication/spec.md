## ADDED Requirements

### Requirement: Facebook availability is derived from runtime credentials

The system SHALL report Facebook authentication available only when both `FACEBOOK_OAUTH_CLIENT_ID` and `FACEBOOK_OAUTH_CLIENT_SECRET` are configured as non-blank runtime values. Missing or blank credentials MUST NOT prevent application startup, MUST keep Facebook absent from account choices, and MUST make direct Facebook request and callback routes fail locally without starting an external transaction. Credentials MUST NOT appear in Inertia props, logs, browser content, or repository-tracked environment files.

#### Scenario: Both Facebook credentials are configured

- **WHEN** both Facebook runtime credentials are non-blank
- **THEN** the server reports Facebook available
- **AND** shared account and settings journeys may expose Facebook actions
- **AND** neither credential is exposed to the browser

#### Scenario: A Facebook credential is absent

- **WHEN** either Facebook runtime credential is missing or blank
- **THEN** D20 starts normally with Facebook unavailable
- **AND** Facebook actions are omitted
- **AND** a direct Facebook request or callback fails locally without contacting Meta

### Requirement: Facebook uses a constrained current authorization-code flow

The Facebook request SHALL use an explicit allowlisted GET request and GET callback, Ueberauth state validation, the current configured Meta authorization endpoint, an explicit current versioned Graph token endpoint, and an explicit same-version Graph profile endpoint. D20 SHALL request only the `email` permission and `id,email` profile fields, SHALL rely on the app-scoped Facebook user ID as the stable provider identifier, and SHALL include the strategy's `appsecret_proof` in the profile request. Caller-supplied scope, auth type, display, locale, redirect, response type, client ID, state, and equivalent provider overrides MUST be removed before authorization.

#### Scenario: Guest starts Facebook authentication

- **WHEN** a guest follows the Facebook account link
- **THEN** D20 starts a full-document authorization-code flow with Ueberauth state validation
- **AND** the request uses the fixed minimum permission and fields
- **AND** token and profile calls use the configured current Graph API version

#### Scenario: Caller attempts to expand Facebook parameters

- **WHEN** a Facebook request includes caller-controlled scope or OAuth override parameters
- **THEN** D20 removes those parameters before Ueberauth executes
- **AND** the outgoing request retains only server-owned configuration

### Requirement: Facebook callback data is minimized at the web boundary

The Facebook adapter SHALL accept only a Facebook result whose non-empty app-scoped UID is no longer than 255 bytes and exactly matches the raw Graph user `id`. The adapter MAY expose a syntactically valid optional email candidate only when normalized and raw email values agree. Provider credentials, tokens, codes, profile names, avatars, and unrelated raw claims MUST NOT leave the Facebook web boundary or be persisted.

#### Scenario: Valid Facebook identity returns

- **WHEN** Meta returns a valid app-scoped user ID and a consistent valid email
- **THEN** the adapter emits only provider `facebook`, the exact provider UID, and the optional email candidate
- **AND** all credentials and unrelated profile data are discarded

#### Scenario: Facebook returns no acceptable email candidate

- **WHEN** Meta omits email or normalized and raw values are malformed or inconsistent
- **THEN** the adapter retains the exact provider UID with a null email candidate
- **AND** provider registration remains available

#### Scenario: Facebook UID is malformed or inconsistent

- **WHEN** the normalized UID is empty, too long, invalid, or differs from the raw Graph user ID
- **THEN** authentication fails without creating a D20 session, user, or identity

### Requirement: Returning Facebook identity authenticates its exact D20 owner

A normal Facebook authentication callback SHALL resolve a returning player only by the exact stored `(:facebook, provider_uid)` identity. An exact identity match SHALL authenticate that owner through the existing D20 session boundary, rotate the browser session, and return only to the accepted safe local path. Changed, missing, or conflicting Facebook email data MUST NOT alter identity selection or the stored account email.

#### Scenario: Known Facebook identity returns

- **WHEN** a signed-out player authorizes a Facebook UID already linked to a D20 user
- **THEN** D20 authenticates that exact user
- **AND** rotates the existing browser session
- **AND** returns to the accepted safe local destination

#### Scenario: Known Facebook identity returns different email data

- **WHEN** a linked Facebook UID returns with a changed or missing email field
- **THEN** D20 still resolves only the stored identity owner
- **AND** does not change the canonical D20 email

### Requirement: Facebook sudo reauthentication is account-bound

A Facebook reauthentication request SHALL start only for an authenticated current user and SHALL bind its intent to that user's D20 ID. The callback SHALL succeed only when the returned Facebook UID is linked to that exact current user. A missing current user, unlinked Facebook UID, UID owned by another user, expired intent, provider failure, or unavailable provider MUST fail closed, preserve the current D20 account, and return an understandable reauthentication prompt. The flow MUST NOT fall back to ordinary login, registration, or account switching and MUST remain valid when the current user has null email.

#### Scenario: Current user reauthenticates with linked Facebook

- **WHEN** an authenticated user authorizes a Facebook UID linked to that same D20 account through a reauthentication intent
- **THEN** D20 refreshes authentication for the current account
- **AND** returns to the accepted safe local destination

#### Scenario: Different Facebook owner attempts reauthentication

- **WHEN** a Facebook reauthentication callback resolves to a D20 account other than the current user
- **THEN** reauthentication fails without switching the browser session
- **AND** the current user receives a retry or alternate linked-method prompt

#### Scenario: Provider-only user reauthenticates with Facebook

- **WHEN** the current user has null email and authorizes a Facebook UID linked to that account
- **THEN** reauthentication succeeds without requiring a Magic Link destination or adding email

### Requirement: Unknown Facebook identity uses username-only completion

An unknown valid Facebook identity SHALL require the guest to choose a valid unique D20 username through the same provider-neutral registration-completion page used by Google, Discord, and Apple. Provider UID and optional email candidate SHALL remain in short-lived session-bound server state. The page and completion request MUST NOT contain an editable email field, provider UID, authorization code, provider token, or raw claims.

#### Scenario: Unknown identity has an unused email candidate

- **WHEN** an unknown Facebook identity returns an acceptable unused email candidate
- **THEN** the shared completion page may display that server-owned candidate as read-only text
- **AND** asks only for username
- **AND** the browser cannot replace the email candidate

#### Scenario: Unknown identity has no email candidate

- **WHEN** an unknown Facebook identity returns without an acceptable email candidate
- **THEN** the shared completion page asks only for username
- **AND** renders no email field or email-specific guidance
- **AND** registration remains available

#### Scenario: Browser submits an email replacement

- **WHEN** the Facebook completion request includes a browser-controlled email
- **THEN** D20 ignores that value
- **AND** uses only the server-owned candidate from completion state

### Requirement: Facebook registration is provider-only capable and atomic

The Facebook completion SHALL call the provider-neutral Accounts operation that atomically creates one confirmed user with the chosen username and optional server-owned email candidate plus one Facebook identity with the exact provider UID. An absent, malformed, or already-owned candidate MUST result in null email rather than blocking registration. An email uniqueness race SHALL retry once with null email. Username and identity conflicts MUST roll back the complete transaction and MUST NOT authenticate a losing request or resolve a concurrent winner as fallback.

#### Scenario: Facebook registration persists an unused email candidate

- **WHEN** the username, Facebook UID, and server-owned email candidate remain available
- **THEN** one completed D20 user and one Facebook identity are created in one transaction
- **AND** the candidate becomes the account email
- **AND** the player is authenticated through a rotated D20 session

#### Scenario: Facebook registration has no email candidate

- **WHEN** an unknown Facebook identity submits an available username without an acceptable email candidate
- **THEN** one completed D20 user with null email and one Facebook identity are created atomically
- **AND** the player is authenticated
- **AND** the player may later add and D20-verify email through Account Settings

#### Scenario: Facebook email candidate is already owned

- **WHEN** an unknown Facebook identity returns an email candidate owned by another D20 user
- **THEN** D20 creates the new account with null email
- **AND** does not authenticate, link, merge, or modify the existing email owner

#### Scenario: Concurrent Facebook completions race

- **WHEN** equivalent completion requests overlap
- **THEN** database constraints permit at most one user and identity ownership result for that username and Facebook UID
- **AND** every losing request receives a controlled conflict without authentication

### Requirement: Facebook never merges account ownership by email

Facebook identity ownership SHALL be determined only by exact provider UID. A Facebook email candidate matching an existing user MUST NOT authenticate, merge, or link that existing account. The player SHALL authenticate the existing D20 account through an existing method and explicitly link Facebook from sudo-protected Account Settings when that is the desired ownership result.

#### Scenario: Facebook registration returns an existing D20 email

- **WHEN** an unknown Facebook identity returns an email already owned by a D20 account
- **THEN** the existing user's ownership and authentication state do not change
- **AND** the new Facebook identity may create a distinct provider-only account after username completion

### Requirement: Facebook linking is explicit and user-bound

A Facebook link request SHALL start only for an authenticated sudo-valid user, SHALL bind the intent to that user, and SHALL recheck the same user and current sudo status at callback. A Facebook UID already owned by that user SHALL be idempotent success. A UID owned by another user or a second Facebook UID for the current user SHALL return one generic conflict without revealing ownership. Link intent MUST NOT fall back to normal login or registration.

#### Scenario: Sudo-valid user links an unowned Facebook identity

- **WHEN** a sudo-valid user explicitly starts Facebook linking and the callback returns an unowned UID
- **THEN** D20 links that UID to the initiating user
- **AND** returns to Account Settings without switching accounts

#### Scenario: Link callback user binding changes

- **WHEN** the callback session no longer contains the initiating user or current sudo proof
- **THEN** no identity is linked
- **AND** the callback does not authenticate another account

#### Scenario: Facebook identity has another owner

- **WHEN** a link callback returns a Facebook UID owned by another D20 user
- **THEN** linking fails with generic conflict feedback
- **AND** the other owner's identity is not disclosed

### Requirement: Facebook failures are safe and redacted

Cancellation, invalid state, expired intent, missing authorization code, token failure, Graph profile failure, unavailable configuration, malformed callback data, expired completion state, username conflict, identity conflict, and revoked access SHALL create no unauthorized D20 session or partial ownership mutation. The browser SHALL receive understandable retry, local authentication, or Account Settings guidance. Server diagnostics SHALL contain only provider, outcome class, internal reason, and request ID and MUST exclude credentials, tokens, codes, email, provider UID, raw claims, and Ueberauth structures.

#### Scenario: Provider authorization is cancelled

- **WHEN** Facebook returns cancellation or provider failure
- **THEN** D20 creates no user, identity, or authenticated session
- **AND** offers a safe retry or local authentication action

#### Scenario: Failure is logged

- **WHEN** any Facebook flow fails
- **THEN** diagnostics identify only the provider, bounded outcome class, internal reason, and request ID
- **AND** no sensitive callback or account data is logged

### Requirement: Facebook delivery requires real Meta verification

The repository SHALL document the exact `/auth/facebook/callback`, `FACEBOOK_OAUTH_CLIENT_ID`, `FACEBOOK_OAUTH_CLIENT_SECRET`, Meta Development-mode app roles or test users, local HTTP limitations and HTTPS-tunnel fallback, current Graph API compatibility gate, staging enablement, and credential-removal rollback. Production availability MUST NOT be claimed until registration with unused, absent, malformed, and already-owned email candidates, returning login, linking, cancellation, state rejection, safe return, session rotation, and rollback are manually verified with the exact registered staging callback.

#### Scenario: Developer prepares local Facebook testing

- **WHEN** a developer follows repository environment guidance
- **THEN** the required variables, exact callback, Meta app mode, eligible test accounts, and HTTPS fallback are identifiable without exposing secrets

#### Scenario: Production readiness is evaluated

- **WHEN** automated validation passes but the real staging journey has not been verified
- **THEN** the change records the external verification as incomplete
- **AND** production Facebook credentials remain outside the readiness claim

### Requirement: Storybook represents Facebook authentication states

Storybook authentication workflows SHALL include deterministic Facebook available, unavailable, linked, and unlinked states without contacting Meta or embedding credentials. The generic Auth Provider Registration Completion story SHALL represent Facebook's provider-neutral completion UI, while focused frontend and controller tests SHALL cover provider-specific completion data with and without an email candidate. The catalog MUST NOT add Facebook-specific Registration Completion stories.

#### Scenario: Developer reviews Facebook workflows in Storybook

- **WHEN** the authentication stories are built
- **THEN** Facebook account choices and Account Settings states can be reviewed with deterministic fixtures
- **AND** the generic Auth Provider story represents the shared username-only completion UI
- **AND** no Facebook-specific Registration Completion story, external provider request, or secret is required
