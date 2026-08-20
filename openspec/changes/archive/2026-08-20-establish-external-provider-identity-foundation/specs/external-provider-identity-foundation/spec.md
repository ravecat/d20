## ADDED Requirements

### Requirement: Minimal external identity records

The system SHALL represent a linked external identity with an `identity`-prefixed TypeID, an owning D20 user, one supported provider, and the provider's opaque stable UID. The supported providers SHALL be Google, Facebook, Apple, and Discord. The record SHALL NOT store provider access tokens, refresh tokens, raw claims, email, display name, or avatar.

#### Scenario: Supported identity is represented

- **WHEN** an external identity is linked to an existing D20 user with a supported provider and non-empty provider UID
- **THEN** the system persists an `identity`-prefixed TypeID, user ownership, provider, provider UID, and record timestamps

#### Scenario: Unsupported provider is rejected

- **WHEN** an identity link uses a provider outside Google, Facebook, Apple, and Discord
- **THEN** the system returns a controlled validation error and persists no identity

#### Scenario: Provider payload data is excluded

- **WHEN** an external identity is persisted
- **THEN** the identity record contains no provider credential, raw claim, email, display name, or avatar fields

### Requirement: External identity ownership is unique

The system SHALL enforce that each provider and provider UID pair belongs to at most one D20 user. The system SHALL enforce that each D20 user owns at most one identity for a given provider. These invariants MUST be enforced by database constraints and surfaced as controlled changeset errors.

#### Scenario: Provider identity cannot be linked to another user

- **WHEN** an identity with the same provider and provider UID is already linked to one D20 user
- **THEN** linking it to another D20 user fails with a controlled changeset error

#### Scenario: User cannot link a second identity for one provider

- **WHEN** a D20 user already owns an identity for a provider
- **THEN** linking a different provider UID for that provider fails with a controlled changeset error

#### Scenario: User can link different providers

- **WHEN** a D20 user has an identity for one supported provider
- **THEN** the user can link an identity for another supported provider

#### Scenario: Equal UIDs from different providers remain distinct

- **WHEN** two supported providers return the same opaque UID text
- **THEN** each provider and UID pair can be linked independently

### Requirement: Accounts links external identities to existing users

`D20.Accounts` SHALL expose a provider-library-independent operation that links a supported provider and opaque UID to an existing `%D20.Accounts.User{}`. Ownership SHALL be taken from the supplied user rather than caller-provided attributes.

#### Scenario: Existing user identity is linked

- **WHEN** Accounts receives an existing user, supported provider, and valid provider UID that do not conflict with another link
- **THEN** it returns the persisted `D20.Accounts.UserIdentity`

#### Scenario: Missing identity data is rejected

- **WHEN** Accounts receives a missing provider or empty provider UID for a new link
- **THEN** it returns a controlled changeset error and persists no identity

### Requirement: Accounts resolves users by external identity

`D20.Accounts` SHALL resolve a D20 user only from an exact supported provider and provider UID pair. It SHALL return `nil` when a valid pair is not linked and SHALL NOT infer identity ownership from email or other profile claims. Provider and UID arguments outside the typed context contract SHALL be treated as calling-code errors rather than normalized by the lookup operation.

#### Scenario: Linked identity resolves its owner

- **WHEN** Accounts receives the exact provider and provider UID of a linked identity
- **THEN** it returns the owning D20 user

#### Scenario: Unknown identity does not resolve

- **WHEN** Accounts receives a supported provider and provider UID pair that is not linked
- **THEN** it returns `nil`

### Requirement: Accounts lists user identities

`D20.Accounts` SHALL list only the external identity records owned by the supplied D20 user.

#### Scenario: User identities are listed

- **WHEN** a user owns identities for multiple supported providers
- **THEN** Accounts returns those identity records and no records owned by another user

### Requirement: Identity lifecycle follows the owning user

The system SHALL delete a user's external identity records when the owning user is deleted.

#### Scenario: User deletion cascades to identities

- **WHEN** a D20 user with linked external identities is deleted
- **THEN** the database removes all identity records owned by that user
