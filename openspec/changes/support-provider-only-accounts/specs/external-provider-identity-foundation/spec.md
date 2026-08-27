## ADDED Requirements

### Requirement: Accounts atomically registers a user with an external identity
`D20.Accounts` SHALL expose a provider-library-independent operation that creates one completed user and links one accepted provider and opaque provider UID in one database transaction. The operation SHALL require a valid unique username, SHALL accept only an optional normalized provider-verified email candidate, and SHALL set completed confirmation state only when both the user and identity inserts succeed. It MUST NOT accept provider credentials, raw claims, or caller-controlled identity ownership.

#### Scenario: Provider-only user is registered
- **WHEN** Accounts receives a valid unique username, accepted provider and UID, and no email candidate
- **THEN** it returns one completed user with null email
- **AND** exactly one external identity owned by that user is committed

#### Scenario: User insert fails
- **WHEN** the username or another user attribute fails validation or uniqueness
- **THEN** no external identity is persisted
- **AND** no completed user is returned

#### Scenario: Identity insert fails
- **WHEN** the provider identity is invalid, already owned, or conflicts with the user's provider cardinality
- **THEN** the user insert is rolled back
- **AND** no authenticated account is returned

### Requirement: Provider email conflict does not change identity ownership
When provider registration receives a syntactically valid verified email candidate, Accounts SHALL persist it only if the existing case-insensitive email unique constraint accepts it. If that candidate is already owned or loses a concurrent uniqueness race, Accounts MAY retry the complete transaction once with null email. It MUST retry only for the named email uniqueness conflict. Username and provider-identity conflicts MUST remain controlled terminal results, and a losing request MUST NOT resolve or authenticate the winning user.

#### Scenario: Email candidate is unowned
- **WHEN** a provider registration transaction receives an unowned valid verified email candidate
- **THEN** the transaction commits the user with that email and the external identity together

#### Scenario: Email candidate is already owned
- **WHEN** a provider registration transaction receives a valid verified email candidate already owned by another user
- **THEN** Accounts creates no link to the existing user
- **AND** it may commit the new user and external identity together with null email

#### Scenario: Concurrent identity registrations race
- **WHEN** two provider registration transactions race for the same provider and UID
- **THEN** database constraints allow at most one identity owner
- **AND** the losing transaction leaves no partial user
- **AND** the losing request does not authenticate by resolving the winner

#### Scenario: Concurrent email registrations race
- **WHEN** distinct provider identities concurrently register with equivalent verified email candidates and distinct valid usernames
- **THEN** at most one resulting user owns the non-null email
- **AND** another successful resulting user has null email and its own external identity
