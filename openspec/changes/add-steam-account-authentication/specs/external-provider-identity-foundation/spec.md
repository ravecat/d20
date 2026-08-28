## MODIFIED Requirements

### Requirement: Minimal external identity records

The system SHALL represent a linked external identity with an `identity`-prefixed TypeID, an owning D20 user, one supported provider, and the provider's opaque stable UID. The supported providers SHALL be Google, Facebook, Apple, Discord, and Steam. The record SHALL NOT store provider access tokens, refresh tokens, OpenID assertions, raw claims, email, display name, or avatar.

#### Scenario: Supported identity is represented

- **WHEN** an external identity is linked to an existing D20 user with a supported provider and non-empty provider UID
- **THEN** the system persists an `identity`-prefixed TypeID, user ownership, provider, provider UID, and record timestamps

#### Scenario: Unsupported provider is rejected

- **WHEN** an identity link uses a provider outside Google, Facebook, Apple, Discord, and Steam
- **THEN** the system returns a controlled validation error and persists no identity

#### Scenario: Provider payload data is excluded

- **WHEN** an external identity is persisted
- **THEN** the identity record contains no provider credential, OpenID assertion, raw claim, email, display name, or avatar fields
