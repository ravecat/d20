# Discord Account Authentication Specification

## Purpose

Define Discord OAuth registration, returning login, explicit account linking, provider-data minimization, credential-derived availability, failure behavior, and the production verification gate.

## Requirements

### Requirement: Discord authentication is credential-derived and allowlisted

The system SHALL expose Discord authentication as available only when non-empty runtime client ID and client secret values are configured. Missing or blank Discord credentials MUST NOT prevent application startup, and explicit Discord request and callback routes MUST reject locally before starting a provider transaction while unavailable. The system SHALL expose only explicit Discord request, callback, and registration-completion routes and MUST NOT route an arbitrary provider name to an authentication strategy. Discord client credentials MUST NOT be exposed to the browser or application logs.

#### Scenario: Configured Discord provider is available

- **WHEN** Discord authentication has a non-empty runtime client ID and client secret
- **THEN** the shared authentication state reports `auth.providers.discord.available` as `true`
- **AND** the explicit Discord request and callback routes can participate in authentication

#### Scenario: Missing Discord credential degrades safely

- **WHEN** the Discord client ID or client secret is absent or blank
- **THEN** application startup continues with Discord omitted from the Register and Login provider choices
- **AND** a direct Discord request or callback does not initiate provider authorization
- **AND** no credential value is logged or exposed to the browser

#### Scenario: Unsupported provider path is requested

- **WHEN** a caller requests an authentication path for a provider other than the explicit Discord routes
- **THEN** no provider strategy or external authorization is started

### Requirement: Discord authorization uses a fixed minimal request

The system SHALL initiate Discord through normal full-document navigation and an authorization-code flow protected by Ueberauth state validation. The server SHALL fix the requested Discord scope to `identify email`, SHALL use the current Discord authorization, token, and current-user endpoints configured by the reviewed strategy, and MUST discard caller-supplied scope, prompt, permissions, guild, bot, redirect, locale, and other provider request parameters before authorization. The system MUST NOT request guild, connection, bot, or Discord API write access.

#### Scenario: Guest starts Discord from the account dialog

- **WHEN** a guest activates an available Discord action in Register or Login mode
- **THEN** the browser performs a full-document navigation to the explicit Discord request route
- **AND** the server redirects to Discord with only the fixed `identify email` scope and state protection

#### Scenario: Caller attempts to expand Discord authorization

- **WHEN** a Discord request includes caller-supplied scope, permissions, prompt, guild, bot, or redirect parameters
- **THEN** the server discards those values before Ueberauth builds the authorization redirect
- **AND** the resulting request contains no scope or permission beyond the fixed authentication request

### Requirement: Discord results normalize to minimal trusted identity data

The Discord web adapter SHALL accept only the configured Discord provider result with a non-empty stable subject that fits the provider identity limit and matches Discord's returned user ID. It SHALL use Discord's snowflake `id` as the opaque provider UID and SHALL trust Discord's transient email verification claim only when `verified` is exactly true and the raw email matches the normalized email. The registration policy SHALL additionally require a syntactically valid email for an unknown identity. The adapter MUST NOT pass Ueberauth structures into `D20.Accounts` or persist access tokens, refresh tokens, authorization codes, raw claims, email verification claims, display names, guilds, connections, or avatars.

#### Scenario: Valid Discord result is normalized

- **WHEN** Discord returns a non-empty user ID and a verified email for an unknown identity
- **THEN** the adapter returns only provider `discord`, the opaque user ID, and the verified email needed for registration policy
- **AND** provider credentials and unrelated claims are discarded

#### Scenario: Linked identity has changed profile or email data

- **WHEN** Discord returns the exact user ID of an existing identity with a missing or changed email or display name
- **THEN** the system resolves the existing D20 user by the stored Discord user ID
- **AND** it does not replace the D20 email, username, or profile from the callback

#### Scenario: Discord identity data is malformed

- **WHEN** the provider result has the wrong provider, a missing or oversized user ID, a user ID that disagrees with the normalized UID, or an unexpected raw user shape
- **THEN** no registration, linking, or authentication is completed

### Requirement: Returning Discord identity authenticates its D20 user

The system SHALL resolve a returning Discord player only by the exact `(discord, user_id)` identity mapping. A successful signed-out callback SHALL authenticate the owning D20 user through `D20Web.Auth`, rotate the browser session according to existing behavior, and redirect only to the accepted safe local return path. Discord email, username, display name, or other claims MUST NOT change which D20 user is selected.

#### Scenario: Returning player signs in with Discord

- **WHEN** a signed-out player completes Discord authorization for a user ID linked to a D20 user
- **THEN** the owning D20 user is authenticated through the existing D20 session boundary
- **AND** the previous browser session is rotated
- **AND** the player returns to the accepted safe local destination

#### Scenario: Authentication attempt submits an unsafe return destination

- **WHEN** a Discord authentication attempt contains an external, protocol-relative, malformed, or backslash-containing return destination
- **THEN** that value is not stored or used
- **AND** successful authentication uses the existing safe signed-in fallback

### Requirement: Unknown Discord identity completes registration atomically

An unknown Discord identity with an acceptable verified unused email SHALL require the guest to choose a valid unique D20 username through the provider-neutral registration-completion page shared with Magic Link, Apple, and Google. The callback SHALL redirect to a clean local completion URL before rendering the form. A signed, nonce-bound completion proof SHALL remain only in the initiating browser session, contain no provider credential, expire after at most 10 minutes, never appear in a URL or log, and be cleared after success, cancellation, expiry, or terminal failure. The system SHALL create the confirmed user with the verified email and username and link the Discord user ID in one database transaction. Any user or identity failure MUST roll back the complete transaction. Successful completion SHALL authenticate the new user through the existing D20 session boundary.

#### Scenario: Guest completes a new Discord registration

- **WHEN** a guest with a valid unknown Discord identity and verified unused email submits a valid unique username before completion expiry
- **THEN** exactly one confirmed D20 user is created with that email and username
- **AND** exactly one Discord identity for that user ID is linked to the new user
- **AND** the guest is authenticated through the existing D20 session boundary
- **AND** completion state is cleared

#### Scenario: Username validation fails

- **WHEN** the guest submits an invalid or already-used username with otherwise valid unexpired completion state
- **THEN** no user or identity is created
- **AND** the completion page reports the username error
- **AND** the guest can submit another username before expiry

#### Scenario: Completion state expires or changes session

- **WHEN** registration completion state is expired, malformed, missing, or not present in the initiating signed browser session
- **THEN** no user or identity is created
- **AND** the state cannot authenticate the caller
- **AND** the player receives a safe Discord retry or local registration action

#### Scenario: Concurrent completions race

- **WHEN** equivalent Discord registration completions race for the same email, username, or Discord user ID
- **THEN** database constraints allow at most one complete user and identity pair
- **AND** every losing transaction creates no partial user or identity
- **AND** a losing request does not authenticate by resolving the winner

### Requirement: Discord email never silently merges accounts

The system MUST NOT use a matching Discord email as proof that an unknown Discord user ID owns an existing D20 account. When Discord omits email, reports it unverified, returns a malformed address, or returns an email already assigned to a D20 user, the callback SHALL create no user, create no identity, and create no authenticated session. It SHALL provide an understandable local email registration or authentication action and explain that Discord can be linked explicitly from Account Settings after local ownership is established.

#### Scenario: Unknown Discord identity matches an existing email

- **WHEN** an unknown Discord user ID returns a verified email already assigned to a D20 user
- **THEN** the existing user is not authenticated
- **AND** the Discord identity is not linked
- **AND** no additional user is created
- **AND** the player receives an existing-method and explicit-link action

#### Scenario: Unknown Discord identity lacks a verified email

- **WHEN** an unknown Discord user ID has a missing, malformed, or unverified email
- **THEN** direct Discord registration does not start
- **AND** no D20 user or identity is created
- **AND** the player receives a local email ownership and later linking action

### Requirement: Authenticated player explicitly links Discord

The system SHALL offer Discord linking from Account Settings only when Discord credentials make the provider available and the current user has no Discord identity. Starting and completing linking SHALL require the same authenticated D20 user and a current sudo proof. The callback SHALL link only the exact Discord user ID returned by the validated provider transaction. It MUST NOT switch the current account, infer ownership from email, or fall back from a failed link intent to login or registration.

#### Scenario: Recently authenticated player links Discord

- **WHEN** a sudo-valid authenticated player explicitly starts linking and returns with an unowned Discord user ID
- **THEN** that user ID is linked to the same D20 user
- **AND** the current D20 account remains authenticated
- **AND** Account Settings reports Discord as linked

#### Scenario: Link callback loses its user binding

- **WHEN** the link callback has no initiating intent, a different current D20 user, or an expired sudo proof
- **THEN** no Discord identity is linked
- **AND** the callback does not authenticate or switch to another account

#### Scenario: Discord user ID is already owned by the same user

- **WHEN** the same user completes linking with the Discord user ID already linked to that user
- **THEN** the system reports Discord as linked without creating a duplicate identity

#### Scenario: Discord linking conflicts with another owner or user ID

- **WHEN** the returned Discord user ID belongs to another D20 user or the current user already owns a different Discord user ID
- **THEN** no identity ownership changes
- **AND** the current user receives one generic conflict result that does not disclose another account

### Requirement: Discord failures fail closed and remain usable

Cancelled consent, Ueberauth state mismatch, missing or expired authorization, provider denial, token or current-user lookup failure, malformed provider data, expired completion, credential unavailability, and identity conflict SHALL create no unauthorized D20 session or identity mutation. The system SHALL return to a safe local D20 surface with an understandable Discord retry or local email authentication action. Diagnostics SHALL contain only the provider, outcome class, internal reason, and request ID and MUST NOT contain provider credentials, authorization codes, tokens, raw payloads, email, or Discord user ID.

#### Scenario: Player cancels Discord consent

- **WHEN** Discord returns a cancellation or denial
- **THEN** no D20 session or identity mutation occurs
- **AND** the player can retry Discord or choose a local account method

#### Scenario: Callback state validation fails

- **WHEN** the callback state is missing or does not match the Ueberauth state cookie
- **THEN** the callback fails without exchanging or trusting provider identity data
- **AND** no D20 session or identity mutation occurs

#### Scenario: Provider exchange or current-user lookup fails

- **WHEN** Discord rejects or cannot complete the token exchange or current-user request
- **THEN** no D20 session or identity mutation occurs
- **AND** the browser receives a generic provider failure with retry and local-auth alternatives
- **AND** server diagnostics contain no callback credential or provider payload

### Requirement: Discord release is verified before production enablement

The system MUST keep Discord production credentials absent until automated dependency, adapter, controller, Accounts, session, frontend, and regression checks pass and the exact configured callback is verified in staging. Production availability SHALL require an exact registered HTTPS callback and manual verification of registration, returning login, explicit linking, missing or unverified email, failure handling, safe returns, session rotation, and credential-removal rollback.

#### Scenario: Staging verification is incomplete

- **WHEN** the configured Discord strategy or complete staging journey has not passed the required verification
- **THEN** Discord credentials remain absent in production and the provider remains unavailable

#### Scenario: Operator removes Discord credentials after release

- **WHEN** either runtime Discord credential is removed
- **THEN** new Discord requests and links cannot start
- **AND** local email authentication remains available
- **AND** existing users and Discord identity mappings are preserved
