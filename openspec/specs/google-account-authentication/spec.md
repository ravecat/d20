# Google Account Authentication Specification

## Purpose

Define secure Google registration, returning sign-in, explicit account linking, failure handling, runtime availability, and release verification.

## Requirements

### Requirement: Google authentication availability is derived and allowlisted

The system SHALL derive Google availability only from whether both runtime client credential environment variables are set. Runtime configuration MUST read those values directly and MUST NOT substitute environment-specific or test-only credential defaults. D20 MUST pass supplied values through unchanged and MUST NOT normalize, trim, or inspect them. A supplied empty or whitespace-only value SHALL still count as present. An unset credential MUST NOT prevent application startup or local authentication. The system SHALL expose only explicit Google request and callback routes and MUST NOT route an arbitrary provider name to an authentication strategy. Google client credentials MUST NOT be exposed to the browser or application logs. Google authentication MUST NOT introduce a provider-specific runtime enable switch.

#### Scenario: Configured Google provider is available

- **WHEN** the application starts with both runtime credential environment variables set
- **THEN** Google registration, login, and linking actions are available
- **AND** the explicit Google request and callback routes are active

#### Scenario: Provider lacks a credential

- **WHEN** the application starts while its Google client ID or client secret environment variable is unset
- **THEN** application startup succeeds with Google marked unavailable
- **AND** Register, Login, and Account Settings render Google as unavailable without exposing either credential
- **AND** local email and password authentication remain usable

#### Scenario: Test runtime has no credential environment variables

- **WHEN** runtime configuration is evaluated for tests without Google credential environment variables
- **THEN** both runtime credential values remain unset
- **AND** runtime configuration does not inject synthetic Google credentials

#### Scenario: Unavailable Google route is requested directly

- **WHEN** a caller requests the explicit Google request or callback route while Google is unavailable
- **THEN** no external authorization or token exchange is started
- **AND** the caller returns to a safe local surface with a local-authentication alternative

#### Scenario: Unsupported provider path is requested

- **WHEN** a caller requests an authentication path for a provider other than the explicit Google routes
- **THEN** no provider strategy or external authorization is started

### Requirement: Google authorization uses a fixed minimal request

The system SHALL initiate Google through a normal full-document browser navigation and an authorization-code flow protected by Ueberauth state validation. The server SHALL fix the requested Google scope to `openid email`, SHALL use the configured current Google authorization, token, and userinfo endpoints, and MUST discard caller-supplied scope, prompt, offline-access, hosted-domain, login-hint, locale, and incremental-authorization parameters before the provider request. The system MUST NOT request profile or Google API access scopes.

#### Scenario: Guest starts Google from the account dialog

- **WHEN** a guest activates an available Google action in Register or Login mode
- **THEN** the browser performs a full-document navigation to the explicit Google request route
- **AND** the server redirects to Google with the fixed `openid email` scope and state protection

#### Scenario: Caller attempts to expand Google authorization

- **WHEN** a Google request includes caller-supplied scope or other provider request parameters
- **THEN** the server discards those values before Ueberauth builds the authorization redirect
- **AND** the resulting request contains no scope beyond `openid email`

### Requirement: Google results normalize to minimal trusted identity data

The Google web adapter SHALL accept the subject extracted by the configured Ueberauth Google strategy without imposing another provider-format validation and SHALL use it as the opaque provider UID. Provider-independent identity persistence constraints remain authoritative when the subject is stored. For unknown-identity registration it SHALL additionally require a syntactically valid email whose transient Google `email_verified` value is true and SHALL persist that address as the canonical D20 account email. A browser-submitted email MUST NOT override the verified Google address. It MUST NOT pass Ueberauth structures into `D20.Accounts` or persist access tokens, refresh tokens, ID tokens, authorization codes, raw claims, email verification claims, names, or avatars.

#### Scenario: Valid Google result is normalized

- **WHEN** the configured Google strategy returns a subject and a verified email for an unknown identity
- **THEN** the adapter returns only provider `google`, the opaque subject, and the verified email needed for registration policy
- **AND** the adapter does not impose an additional subject format check
- **AND** provider credentials and all unrelated claims are discarded

#### Scenario: Registration submits another email

- **WHEN** the browser submits a different email while completing registration from a valid Google proof
- **THEN** the new account stores the verified Google email
- **AND** the browser-submitted email is ignored

#### Scenario: Linked identity has changed email data

- **WHEN** Google returns the exact subject of an existing identity with a missing or changed email
- **THEN** the system resolves the existing D20 user by the stored Google subject
- **AND** it does not replace the D20 account email from the callback

#### Scenario: Unknown identity lacks a verified email

- **WHEN** an unknown Google subject has a missing, malformed, or unverified email
- **THEN** no registration completion is started
- **AND** no D20 user or identity is created

### Requirement: Returning Google identity authenticates its D20 user

The system SHALL resolve a returning Google player only by the exact `(google, subject)` identity mapping. A successful signed-out callback SHALL authenticate the owning D20 user through `D20Web.Auth`, rotate the browser session according to existing behavior, and redirect only to the accepted safe local return path. Google email or other profile claims MUST NOT change which D20 user is selected.

#### Scenario: Returning player signs in with Google

- **WHEN** a signed-out player completes Google authorization for a subject linked to a D20 user
- **THEN** the owning D20 user is authenticated through the existing D20 session boundary
- **AND** the previous browser session is rotated
- **AND** the player returns to the accepted safe local destination

#### Scenario: Callback submits an unsafe return destination

- **WHEN** a Google authentication attempt contains an external, protocol-relative, or malformed return destination
- **THEN** that value is not stored or used
- **AND** successful authentication uses the existing safe signed-in fallback

### Requirement: Unknown Google identity completes registration atomically

An unknown Google identity with an acceptable verified email SHALL require the guest to choose a valid unique D20 username through the provider-neutral registration-completion page shared with Magic Link and future providers. The completion proof SHALL contain no provider credential, SHALL expire after at most 10 minutes, MUST NOT appear in a URL or log, and SHALL be cleared after success or a terminal failure. The Google subject and provider details MUST remain inside the authenticated session-bound proof and MUST NOT be exposed through shared-page props or form fields. The system SHALL create the confirmed user with the verified email and username and link the Google subject in one database transaction. Any user or identity failure MUST roll back the complete transaction. Successful completion SHALL authenticate the new user through the existing D20 session boundary.

#### Scenario: Guest completes a new Google registration

- **WHEN** a guest with a valid unknown Google subject and verified unused email submits a valid unique username before completion expiry
- **THEN** exactly one confirmed D20 user is created with that email and username
- **AND** exactly one Google identity for that subject is linked to the new user
- **AND** the guest is authenticated through the existing D20 session boundary
- **AND** the completion state is cleared

#### Scenario: Username validation fails

- **WHEN** the guest submits an invalid or already-used username with otherwise valid unexpired completion state
- **THEN** no user or identity is created
- **AND** the shared provider-neutral completion page reports the username error
- **AND** the guest can submit another username before expiry

#### Scenario: Completion state expires or changes session

- **WHEN** a registration completion proof is expired, malformed, missing, or not bound to the current browser session
- **THEN** no user or identity is created
- **AND** the proof cannot authenticate the caller
- **AND** the player receives a safe retry or local registration action

#### Scenario: Concurrent completions race

- **WHEN** equivalent Google registration completions race for the same email, username, or Google subject
- **THEN** database constraints allow at most one complete user and identity pair
- **AND** every losing transaction creates no partial user or identity
- **AND** a losing request does not authenticate by resolving the winner

### Requirement: Google email never silently merges accounts

The system MUST NOT use a matching Google email as proof that an unknown Google subject owns an existing D20 account. When the verified Google email already belongs to a D20 user, the callback SHALL create no user, create no identity, and create no authenticated session. It SHALL direct the player to authenticate with an existing method and explicitly link Google from Account Settings.

#### Scenario: Unknown Google subject matches an existing email

- **WHEN** an unknown Google subject returns a verified email already assigned to a D20 user
- **THEN** the existing user is not authenticated
- **AND** the Google subject is not linked
- **AND** no additional user is created
- **AND** the player receives an understandable existing-method and explicit-link action

### Requirement: Authenticated player explicitly links Google

The system SHALL offer Google linking from Account Settings when the current user has no Google identity. Starting and completing linking SHALL require the same authenticated D20 user and a current sudo proof. The callback SHALL link only the exact Google subject returned by the validated provider transaction. It MUST NOT switch the current account, infer ownership from email, or fall back from a failed link intent to login or registration.

#### Scenario: Recently authenticated player links Google

- **WHEN** a sudo-valid authenticated player explicitly starts linking and returns with an unowned Google subject
- **THEN** that subject is linked to the same D20 user
- **AND** the current D20 account remains authenticated
- **AND** Account Settings reports Google as linked

#### Scenario: Link callback loses its user binding

- **WHEN** the link callback has no initiating intent, a different current D20 user, or an expired sudo proof
- **THEN** no Google identity is linked
- **AND** the callback does not authenticate or switch to another account

#### Scenario: Google subject is already owned by the same user

- **WHEN** the same user completes linking with the Google subject already linked to that user
- **THEN** the system reports Google as linked without creating a duplicate identity

#### Scenario: Google linking conflicts with another owner or subject

- **WHEN** the returned Google subject belongs to another D20 user or the current user already owns a different Google subject
- **THEN** no identity ownership changes
- **AND** the current user receives one generic conflict result that does not disclose another account

### Requirement: Google failures fail closed and remain usable

Cancelled consent, Ueberauth state mismatch, missing or expired authorization, provider denial, token or userinfo failure, malformed provider data, expired completion, and identity conflict SHALL create no unauthorized D20 session or identity mutation. The system SHALL return to a safe local D20 surface with an understandable retry or local email authentication action. Diagnostics SHALL contain only the provider, outcome class, internal reason, and request ID and MUST NOT contain provider credentials, authorization codes, tokens, raw payloads, email, or provider subject.

#### Scenario: Player cancels Google consent

- **WHEN** Google returns a cancellation or denial
- **THEN** no D20 session or identity mutation occurs
- **AND** the player can retry Google or choose a local account method

#### Scenario: Callback state validation fails

- **WHEN** the callback state is missing or does not match the Ueberauth state cookie
- **THEN** the callback fails without exchanging or trusting provider identity data
- **AND** no D20 session or identity mutation occurs

#### Scenario: Provider exchange or userinfo lookup fails

- **WHEN** Google rejects or cannot complete the token exchange or userinfo request
- **THEN** no D20 session or identity mutation occurs
- **AND** the browser receives a generic provider failure with retry and local-auth alternatives
- **AND** server diagnostics contain no callback credential or provider payload

### Requirement: Google release is verified before production deployment

The Google-enabled release MUST NOT be deployed to production until automated dependency, adapter, controller, Accounts, session, frontend, and regression checks pass and the exact configured callback is verified in staging. Production deployment SHALL require an exact registered HTTPS callback and manual verification of registration, returning login, explicit linking, failure handling, safe returns, and session rotation.

#### Scenario: Staging verification is incomplete

- **WHEN** the configured Google strategy or complete staging journey has not passed the required verification
- **THEN** the Google-enabled application release is not deployed to production
