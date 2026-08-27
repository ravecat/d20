## MODIFIED Requirements

### Requirement: Discord results normalize to minimal trusted identity data
The Discord web adapter SHALL accept only the configured Discord provider result with a non-empty stable subject that fits the provider identity limit and matches Discord's returned user ID. It SHALL use Discord's snowflake `id` as the opaque provider UID and SHALL treat Discord email as an optional verified registration candidate only when `verified` is exactly true, the raw email matches the normalized email, and the address is syntactically valid. Missing, malformed, or unverified email SHALL normalize to no candidate and MUST NOT block provider-only registration. The adapter MUST NOT pass Ueberauth structures into `D20.Accounts` or persist access tokens, refresh tokens, authorization codes, raw claims, email verification claims, display names, guilds, connections, or avatars.

#### Scenario: Valid Discord result includes verified email
- **WHEN** Discord returns a non-empty user ID and a valid verified email for an unknown identity
- **THEN** the adapter returns only provider `discord`, the opaque user ID, and the optional verified email candidate
- **AND** provider credentials and unrelated claims are discarded

#### Scenario: Linked identity has changed profile or email data
- **WHEN** Discord returns the exact user ID of an existing identity with a missing or changed email or display name
- **THEN** the system resolves the existing D20 user by the stored Discord user ID
- **AND** it does not replace the D20 email, username, or profile from the callback

#### Scenario: Unknown Discord identity lacks verified email
- **WHEN** Discord returns a valid unknown user ID with missing, malformed, or unverified email
- **THEN** the adapter retains the valid provider UID with no email candidate
- **AND** provider-only registration completion may start

#### Scenario: Discord identity data is malformed
- **WHEN** the provider result has the wrong provider, a missing or oversized user ID, a user ID that disagrees with the normalized UID, or an unexpected raw user shape
- **THEN** no registration, linking, or authentication is completed

### Requirement: Unknown Discord identity completes registration atomically
An unknown valid Discord identity SHALL require the guest to choose a valid unique D20 username through the provider-neutral registration-completion page shared with Magic Link, Apple, and Google. The callback SHALL redirect to a clean local completion URL before rendering the form. A signed, nonce-bound completion proof SHALL remain only in the initiating browser session, contain no provider credential, contain at most the provider UID and optional verified email candidate required by the server transaction, expire after at most 10 minutes, never appear in a URL or log, and be cleared after success, cancellation, expiry, or terminal failure. The system SHALL create the completed user with the username and an unowned valid verified email when available, otherwise null email, and link the Discord user ID in one database transaction. Any user or identity failure MUST roll back the complete transaction. Successful completion SHALL authenticate the new user through the existing D20 session boundary.

#### Scenario: Guest completes Discord registration with unused verified email
- **WHEN** a guest with a valid unknown Discord identity and unused verified email submits a valid unique username before completion expiry
- **THEN** exactly one completed D20 user is created with that email and username
- **AND** exactly one Discord identity for that user ID is linked to the new user
- **AND** the guest is authenticated through the existing D20 session boundary
- **AND** completion state is cleared

#### Scenario: Guest completes Discord registration without verified email
- **WHEN** a guest with a valid unknown Discord identity and no acceptable email candidate submits a valid unique username before completion expiry
- **THEN** exactly one completed D20 user is created with null email and that username
- **AND** exactly one Discord identity for that user ID is linked to the new user
- **AND** the guest is authenticated

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
- **WHEN** equivalent Discord registration completions race for the same username, Discord user ID, or optional email
- **THEN** database constraints allow at most one owner for each username, non-null email, and Discord user ID
- **AND** every losing transaction creates no partial user or identity
- **AND** a losing request does not authenticate by resolving the winner

### Requirement: Discord email never silently merges accounts
The system MUST NOT use a matching Discord email as proof that an unknown Discord user ID owns an existing D20 account. When Discord omits email, reports it unverified, returns a malformed address, or returns an email already assigned to a D20 user, the callback SHALL still allow provider-only username completion for the valid unknown Discord identity. Missing or unusable email SHALL be stored as null. An already-owned email SHALL NOT authenticate or link its existing owner and SHALL be discarded from the new account. Guidance SHALL explain that linking Discord to an existing account requires authenticating that account and explicitly linking from Account Settings.

#### Scenario: Unknown Discord identity matches an existing email
- **WHEN** an unknown Discord user ID returns a verified email already assigned to a D20 user
- **THEN** the existing user is not authenticated
- **AND** the Discord identity is not linked to the existing user
- **AND** the player may complete a distinct Discord-backed account with null email
- **AND** explicit linking to the existing account still requires authenticating that account first

#### Scenario: Unknown Discord identity lacks a verified email
- **WHEN** an unknown valid Discord user ID has a missing, malformed, or unverified email
- **THEN** provider-only Discord registration can continue to username completion
- **AND** the resulting account stores null email
- **AND** no local email ownership is inferred
