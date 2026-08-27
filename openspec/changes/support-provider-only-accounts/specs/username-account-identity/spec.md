## MODIFIED Requirements

### Requirement: Registration completion assigns username before authentication
A direct-email registration MAY persist temporarily without a username while it remains unconfirmed and unauthenticated. Magic Link and provider registration completion SHALL require a valid unique username before creating an authenticated session. Provider registration completion MUST NOT require email when the same atomic operation creates a uniquely owned external identity. Account Settings SHALL display the username established by registration completion without offering a claim form.

#### Scenario: Email registration is awaiting completion
- **WHEN** a new direct-email registration has been created but its valid completion form has not succeeded
- **THEN** the user remains unconfirmed and unauthenticated
- **AND** its username remains unassigned

#### Scenario: Direct-email registration completes successfully
- **WHEN** a Magic Link registration completes with a valid unique username
- **THEN** the supported flow establishes the account with that username and verified email
- **AND** only then does the flow create an authenticated session

#### Scenario: Provider registration completes without email
- **WHEN** an unknown verified provider identity completes registration with a valid unique username and no acceptable email candidate
- **THEN** the flow atomically establishes the account with that username and provider identity
- **AND** the account email remains null
- **AND** only then does the flow create an authenticated session

#### Scenario: Provider registration username fails
- **WHEN** provider registration submits an invalid or already assigned username
- **THEN** no user or external identity is created
- **AND** no authenticated session is created

#### Scenario: Authenticated user opens Account Settings
- **WHEN** a user authenticated through a supported registration flow opens Account Settings
- **THEN** the page receives and displays the assigned username regardless of email presence
- **AND** no username claim form or claim operation is available
