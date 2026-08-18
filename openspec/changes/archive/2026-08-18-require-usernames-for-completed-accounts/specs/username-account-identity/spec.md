## MODIFIED Requirements

### Requirement: Username has one canonical format

Username input fields during registration completion SHALL immediately trim surrounding whitespace and lowercase their values as the user enters them. The server MUST accept only canonical usernames containing between 3 and 32 lowercase ASCII characters, beginning and ending with an ASCII letter or digit, with lowercase ASCII letters, digits, underscores, or hyphens between those boundaries. The system SHALL expose validation failures as username field errors without completing the account with the invalid value.

#### Scenario: User enters a normalizable username

- **WHEN** a user types or pastes `  Table_Master  ` into a registration-completion username field
- **THEN** the field immediately contains `table_master`
- **AND** submitting the form stores `table_master`
- **AND** later username lookup treats equivalent letter case as the same identifier

#### Scenario: A direct completion submits a non-canonical username

- **WHEN** a registration-completion request bypasses the client and submits uppercase characters or surrounding whitespace
- **THEN** the server rejects the username with a field error
- **AND** the account remains incomplete

#### Scenario: User submits an invalid username

- **WHEN** a username is shorter than 3 characters, longer than 32 characters, contains unsupported characters, or begins or ends with a separator
- **THEN** the username is not assigned
- **AND** the submitting registration-completion form receives a username field error

### Requirement: Username is globally unique and immutable

Every assigned username SHALL identify at most one D20 user under case-insensitive comparison. The database MUST enforce this uniqueness, concurrent registration completions for equivalent usernames MUST allow at most one success, and no authenticated settings operation SHALL replace an assigned username.

#### Scenario: Equivalent username is already assigned

- **WHEN** a registration completion submits a username that is case-insensitively equivalent to another user's username
- **THEN** completion fails with a controlled username field error
- **AND** neither user's existing identity is changed

#### Scenario: Equivalent registration completions race

- **WHEN** two eligible registrations concurrently submit case-insensitively equivalent usernames
- **THEN** the database permits at most one completed account with that username
- **AND** the losing completion receives a controlled validation result rather than an exception

#### Scenario: Authenticated user opens Account Settings

- **WHEN** an authenticated user views the assigned username
- **THEN** Account Settings displays the username without an edit or replacement operation

### Requirement: Account presentation prefers username

The shared authenticated account profile SHALL use the username assigned during registration completion as its display name and MUST NOT fall back to the account email.

#### Scenario: Authenticated account profile is produced

- **WHEN** shared account props are produced for an authenticated user
- **THEN** the profile display name equals that user's username
- **AND** the account email is not used as a display-name fallback

## ADDED Requirements

### Requirement: Registration completion assigns username before authentication

An email registration MAY persist temporarily without a username while it remains unconfirmed and unauthenticated. Magic Link and provider registration completion SHALL require a valid unique username before creating an authenticated session. Account Settings SHALL display the username established by registration completion without offering a claim form.

#### Scenario: Email registration is awaiting completion

- **WHEN** a new email registration has been created but its valid completion form has not succeeded
- **THEN** the user remains unconfirmed and unauthenticated
- **AND** its username remains unassigned

#### Scenario: Registration completes successfully

- **WHEN** a Magic Link or provider registration completes with a valid unique username
- **THEN** the supported flow establishes the account with that username
- **AND** only then does the flow create an authenticated session

#### Scenario: Authenticated user opens Account Settings

- **WHEN** a user authenticated through a supported registration flow opens Account Settings
- **THEN** the page receives and displays the assigned username
- **AND** no username claim form or claim operation is available

## REMOVED Requirements

### Requirement: Every completed account has a username

**Reason**: Current product flows already assign username during registration completion before authentication. A database constraint and repeated authentication guards would defend a malformed state that no supported page flow can create.

**Migration**: Remove the experimental relational constraint and redundant authentication guards. Keep username validation and atomic assignment in Magic Link and provider registration completion.
