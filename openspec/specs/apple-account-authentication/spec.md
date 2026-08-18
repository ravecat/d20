# Apple Account Authentication Specification

## Purpose

Define secure Sign in with Apple registration, authentication, and explicit account linking while preserving D20 account ownership and session boundaries.

## Requirements

### Requirement: Apple authentication availability is credential-derived and allowlisted

The system SHALL expose Apple authentication when runtime Services ID, Team ID, Key ID, base64-encoded private key, and callback URL environment variables are all set, without requiring a separate enable flag. The complete set SHALL be treated as operator-approved configuration. All Apple source credentials SHALL have one runtime configuration source owned by the Ueberauth Apple strategy; availability checks, request configuration, and client-secret generation MUST read that same entry. D20 MUST preserve every supplied source value without normalization, trimming, parsing, or validation during startup. A supplied empty or whitespace-only value SHALL still count as present. When a provider flow builds its OAuth client, `D20Web.Auth.Apple` MUST decode the private key and delegate client-secret JWT signing to `UeberauthApple.generate_client_secret/1`. D20 MUST NOT require or store a pre-generated Apple client secret and MUST NOT cache the generated JWT. An unset or partial source credential set SHALL leave Apple unavailable without failing application startup. The system SHALL route only the explicit Apple request and POST callback paths and MUST NOT resolve an arbitrary provider name to an authentication strategy.

#### Scenario: Configured Apple provider is available

- **WHEN** all required Apple credential environment variables are set
- **THEN** shared authentication state reports Apple as available
- **AND** the explicit Apple request and POST callback routes can serve the provider flow

#### Scenario: Missing or partial Apple credentials remain unavailable

- **WHEN** one or more required Apple credential environment variables are unset
- **THEN** Apple remains visible as an unavailable account method
- **AND** a direct Apple request does not initiate provider authorization
- **AND** application startup continues

#### Scenario: Complete Apple credentials are trusted at startup

- **WHEN** every required Apple credential environment variable is set
- **THEN** application startup passes each supplied value through unchanged without trimming, parsing, or validating it
- **AND** an invalid supplied value fails through the provider flow when it is used

#### Scenario: Provider flow generates its client secret

- **WHEN** Ueberauth builds an OAuth client for an available Apple provider
- **THEN** the Apple provider module decodes the configured private key and delegates JWT signing to the installed Ueberauth Apple generator
- **AND** no pre-generated client-secret environment variable or manual JWT rotation is required
- **AND** the generated JWT is not cached or exposed outside the provider flow

#### Scenario: Apple runtime configuration has one source

- **WHEN** the Apple adapter checks availability or prepares the provider request
- **THEN** it reads the same Ueberauth Apple strategy configuration entry
- **AND** no duplicate D20 module configuration is required

#### Scenario: Unsupported provider path is requested

- **WHEN** a caller requests an authentication path for a provider other than the explicit Apple route
- **THEN** no provider strategy or external authorization starts

### Requirement: Apple authorization uses a fixed minimal POST callback flow

The system SHALL start Apple through normal full-document navigation and SHALL fix the authorization request to the `email` scope, `form_post` response mode, authorization-code and ID-token response, Ueberauth state validation, and Apple ID-token nonce validation. Caller-supplied scope, response mode, response type, callback, nonce, state, prompt, or other OAuth request options MUST NOT alter that request. The normal D20 session cookie SHALL retain its current SameSite policy, and only the explicit Apple POST callback SHALL omit Phoenix form-CSRF validation.

#### Scenario: Guest starts Apple from the account dialog

- **WHEN** a guest activates an available Apple provider action
- **THEN** the browser performs a full-document navigation to the explicit Apple request route
- **AND** the server redirects to Apple with only the fixed email scope and configured callback URL
- **AND** Ueberauth state is used as the Apple nonce

#### Scenario: Caller attempts to change Apple authorization

- **WHEN** an Apple request includes caller-supplied scope or other OAuth parameters
- **THEN** those values do not change the server-owned Apple authorization request

#### Scenario: Apple posts a callback

- **WHEN** Apple returns the scoped authorization response by cross-site POST
- **THEN** the dedicated callback accepts the form POST without weakening CSRF protection on D20 browser or Inertia forms
- **AND** invalid Ueberauth state or Apple nonce fails before D20 trusts the provider identity

### Requirement: Apple transactions use short-lived encrypted browser state

The system SHALL bind each Apple request to its intent, a safe local return path, and the expected D20 user for linking in the attempt phase of one encrypted, authenticated, HTTP-only, Secure flow cookie. The attempt phase SHALL be usable by the cross-site POST callback, expire after at most 10 minutes, and be consumed by the callback. Unknown-identity registration SHALL replace it with a same-site registration phase in the same cookie containing only the normalized subject, provider-authenticated email, and safe return path. The registration state MUST never appear in a URL, browser-visible prop, or log and SHALL expire after at most 10 minutes. D20 SHALL rely on the framework token primitive for encryption, integrity, and age validation while Ueberauth remains responsible for provider state, nonce, ID-token, and authorization-code validation.

#### Scenario: Apple callback lacks a valid attempt

- **WHEN** the callback attempt cookie is missing, malformed, expired, or has an unexpected purpose or intent
- **THEN** no D20 user, identity, or authenticated session is created
- **AND** the player receives a safe local retry action

#### Scenario: Registration state is replayed or expires

- **WHEN** registration state is missing, malformed, expired, has an unexpected phase, or is reused after terminal consumption
- **THEN** no D20 user or identity is created
- **AND** the state cannot authenticate the caller

### Requirement: Apple results normalize to minimal trusted identity data

The Apple web adapter SHALL accept only a successful result from the configured Apple strategy with a non-empty stable subject within the provider identity limit. It SHALL use the Apple subject as the opaque provider UID. A returning stored subject MAY omit email. An unknown subject SHALL additionally require a syntactically valid email obtained from the strategy after signed ID-token validation. The adapter MUST NOT pass Ueberauth structures into Accounts or persist Apple access tokens, refresh tokens, ID tokens, authorization codes, raw claims, name, avatar, relay metadata, or unrelated profile data.

#### Scenario: Initial Apple result is normalized

- **WHEN** Apple returns a valid stable subject and email for an unknown identity
- **THEN** the adapter returns only provider `apple`, the opaque subject, and the transient email needed by D20 registration policy
- **AND** Apple credentials and unrelated claims are discarded

#### Scenario: Returning Apple result omits profile data

- **WHEN** Apple returns the exact subject of an existing identity without name or email
- **THEN** the system can resolve the existing D20 user from the stored Apple subject
- **AND** no D20 profile field is replaced

#### Scenario: Unknown Apple result lacks usable email

- **WHEN** an unknown Apple subject has a missing or malformed email
- **THEN** no registration completion starts
- **AND** no D20 user or identity is created

### Requirement: Returning Apple identity authenticates its D20 user

The system SHALL resolve a returning Apple player only by the exact `(apple, subject)` identity mapping. A successful signed-out callback SHALL authenticate the owning D20 user through `D20Web.Auth`, rotate the browser session according to existing behavior, and redirect only to the accepted safe local return path. Apple email, relay choice, name, or other profile claims MUST NOT change which D20 user is selected.

#### Scenario: Returning player signs in with Apple

- **WHEN** a signed-out player completes Apple authorization for a subject linked to a D20 user
- **THEN** the owning D20 user is authenticated through the existing D20 session boundary
- **AND** the browser session is rotated
- **AND** the player returns to the accepted safe local destination

#### Scenario: Returning Apple email changed or disappeared

- **WHEN** a linked Apple subject returns with a changed or missing email claim
- **THEN** the exact stored subject still selects the same D20 user
- **AND** the D20 account email remains unchanged

#### Scenario: Apple attempt contains an unsafe return target

- **WHEN** an Apple request supplies an external, protocol-relative, malformed, or backslash-containing return destination
- **THEN** that value is not stored or used
- **AND** successful authentication uses the existing safe signed-in fallback

### Requirement: Unknown Apple identity completes registration atomically

An unknown Apple identity with an acceptable unused personal or private relay email SHALL require the guest to choose a valid unique D20 username through the shared provider-neutral registration-completion page and short-lived Apple registration state. The system SHALL create one confirmed D20 user with that email and username and link the Apple subject in one database transaction. Any user or identity failure MUST roll back the complete transaction. Successful completion SHALL consume the state and authenticate the new user through the existing D20 session boundary. The completion page MUST NOT receive the Apple subject, encrypted state, token, or raw provider result.

#### Scenario: Guest completes Apple registration with personal email

- **WHEN** a guest with a valid unknown Apple subject and unused personal email submits a valid unique username before completion expiry
- **THEN** exactly one confirmed D20 user is created with that email and username
- **AND** exactly one Apple identity for that subject is linked to the new user
- **AND** the guest is authenticated through the existing D20 session boundary

#### Scenario: Guest completes Apple registration with private relay email

- **WHEN** Apple supplies a valid private relay email and the guest submits a valid unique username
- **THEN** D20 accepts the relay address without requiring the personal Apple email
- **AND** the resulting confirmed user and Apple identity are created atomically

#### Scenario: Username validation fails

- **WHEN** the guest submits an invalid or already-used username with otherwise valid unexpired completion state
- **THEN** no user or identity is created
- **AND** the completion page reports the username error
- **AND** the guest can retry before the registration state expires

#### Scenario: Concurrent Apple registrations race

- **WHEN** equivalent Apple registration completions race for the same email, username, or Apple subject
- **THEN** database constraints allow at most one complete user and identity pair
- **AND** every losing transaction creates no partial user or identity
- **AND** a losing request does not authenticate by resolving the winner

### Requirement: Apple email never silently merges accounts

The system MUST NOT use a matching Apple personal or private relay email as proof that an unknown Apple subject owns an existing D20 account. When the Apple email already belongs to a D20 user, the callback SHALL create no user, create no identity, and create no authenticated session. It SHALL direct the player to authenticate with an existing method and explicitly link Apple from Account Settings.

#### Scenario: Unknown Apple subject matches an existing email

- **WHEN** an unknown Apple subject returns an email already assigned to a D20 user
- **THEN** the existing user is not authenticated
- **AND** the Apple subject is not linked
- **AND** no additional user is created
- **AND** the player receives an understandable existing-method and explicit-link action

### Requirement: Authenticated player explicitly links Apple

The system SHALL offer Apple linking from Account Settings only when Apple is available from the complete runtime credential set and the current user has no Apple identity. Starting a link SHALL require a recently authenticated D20 user, and the callback SHALL remain bound to that exact user through the valid short-lived attempt. It SHALL link only the exact Apple subject returned by the validated transaction and MUST NOT switch accounts, infer ownership from email, or fall back from a failed link intent to login or registration. The Apple provider boundary SHALL carry a bounded link outcome from the cross-site callback in short-lived encrypted state, consume it on the first authenticated Account Settings request, convert it to one-use flash feedback, and redirect to the clean settings URL. Controllers MUST NOT parse Apple result query parameters or define Apple-specific result presentation. Account Settings page props SHALL expose only Apple availability and durable linked state and MUST NOT expose a callback-result field.

#### Scenario: Recently authenticated player links Apple

- **WHEN** a sudo-valid authenticated player explicitly starts linking and returns with an unowned Apple subject
- **THEN** that subject is linked to the same D20 user
- **AND** the current D20 account remains the selected account
- **AND** Account Settings reports Apple as linked

#### Scenario: Link start lacks recent authentication

- **WHEN** an unauthenticated or non-sudo player requests Apple linking
- **THEN** no Apple authorization for linking starts
- **AND** the player receives the existing authentication or reauthentication action

#### Scenario: Apple subject is already owned by the same user

- **WHEN** the same user completes linking with the Apple subject already linked to that user
- **THEN** the system reports Apple as linked without creating a duplicate identity

#### Scenario: Apple linking conflicts

- **WHEN** the returned Apple subject belongs to another D20 user or the expected user already owns a different Apple subject
- **THEN** no identity ownership changes
- **AND** the player receives one generic conflict result that does not disclose another account

#### Scenario: Apple link result reaches Account Settings

- **WHEN** the Apple callback redirects an authenticated player with a provider-owned encrypted linked, conflict, or failed outcome
- **THEN** the Apple provider boundary consumes the outcome on the first same-site Account Settings request and converts it to one-use flash feedback
- **AND** redirects to the clean Account Settings URL
- **AND** Apple result query parameters are not produced or trusted
- **AND** the rendered Apple provider state contains only availability and durable linked state

### Requirement: Apple failures fail closed and remain usable

Cancelled consent, state mismatch, nonce mismatch, missing or expired authorization, token or key failure, malformed provider data, expired flow state, duplicate ownership, and disabled-provider callbacks SHALL create no unauthorized D20 session or identity mutation. The system SHALL return to a safe local D20 surface with an understandable retry or local email authentication action. The Apple controller SHALL NOT emit application-specific failure logs until D20 has a shared logging design.

#### Scenario: Player cancels Apple consent

- **WHEN** Apple returns a cancellation or denial
- **THEN** no D20 session or identity mutation occurs
- **AND** the player can retry Apple or choose a local account method

#### Scenario: Apple state or nonce validation fails

- **WHEN** callback state is missing or mismatched or the validated ID token has an invalid nonce
- **THEN** the callback fails without trusting the provider identity
- **AND** no D20 session or identity mutation occurs

#### Scenario: Apple exchange or key lookup fails

- **WHEN** Apple rejects the token exchange or the strategy cannot validate the ID token
- **THEN** no D20 session or identity mutation occurs
- **AND** the browser receives a generic provider failure with retry and local-auth alternatives

### Requirement: Apple release is verified before production enablement

The system MUST keep Apple disabled until automated dependency, credential-gated request behavior, cookie, adapter, Accounts, controller, session, route, frontend, and regression checks pass and the exact configured HTTPS callback is verified in staging. Production enablement SHALL additionally require Apple Services ID configuration, registered private relay outbound email sources, and manual verification of personal and relay registration, returning login, explicit linking, failures, safe returns, session rotation, and operational disablement.

#### Scenario: Staging verification is incomplete

- **WHEN** Apple console configuration, private relay delivery, or the complete staging journey has not passed verification
- **THEN** the complete Apple runtime credential set is not deployed and Apple remains unavailable in production

#### Scenario: Operator removes Apple credentials after release

- **WHEN** one or more required Apple runtime credentials are removed
- **THEN** new Apple requests and links cannot start
- **AND** local email authentication remains available
- **AND** existing users and Apple identity mappings are preserved
