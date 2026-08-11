## ADDED Requirements

### Requirement: Username has one canonical format

Username input fields SHALL immediately trim surrounding whitespace and lowercase their values as the user enters them. The server MUST accept only canonical usernames containing between 3 and 32 lowercase ASCII characters, beginning and ending with an ASCII letter or digit, with lowercase ASCII letters, digits, underscores, or hyphens between those boundaries. The system SHALL expose validation failures as username field errors without assigning the invalid value.

#### Scenario: User enters a normalizable username

- **WHEN** a user types or pastes `  Table_Master  ` into a username field
- **THEN** the field immediately contains `table_master`
- **AND** submitting the form stores `table_master`
- **AND** later username lookup treats equivalent letter case as the same identifier

#### Scenario: A direct claim submits a non-canonical username

- **WHEN** a username claim bypasses the client and submits uppercase characters or surrounding whitespace
- **THEN** the server rejects the username with a field error
- **AND** no username is assigned

#### Scenario: User submits an invalid username

- **WHEN** a username is shorter than 3 characters, longer than 32 characters, contains unsupported characters, or begins or ends with a separator
- **THEN** the username is not assigned
- **AND** the submitting form receives a username field error

### Requirement: Username is globally unique and immutable

Every assigned username SHALL identify at most one D20 user under case-insensitive comparison. The database MUST enforce this uniqueness, concurrent claims for equivalent usernames MUST allow at most one success, and a user with an assigned username MUST NOT replace it through the username claim operation.

#### Scenario: Equivalent username is already assigned

- **WHEN** a user claims a username that is case-insensitively equivalent to another user's username
- **THEN** the claim fails with a controlled username field error
- **AND** neither user's existing identity is changed

#### Scenario: Equivalent username claims race

- **WHEN** two eligible users concurrently claim case-insensitively equivalent usernames
- **THEN** the database permits at most one assignment
- **AND** the losing claim receives a controlled validation result rather than an exception

#### Scenario: User attempts to replace an assigned username

- **WHEN** a user who already has a username submits the username claim operation again
- **THEN** the operation is rejected
- **AND** the assigned username remains unchanged

### Requirement: Existing accounts remain usable and can adopt a username

The username column SHALL remain nullable for accounts created before username support and for registrations that have not completed confirmation. An authenticated existing user without a username SHALL be offered a dedicated account-settings form to claim one. Existing email, password, magic-link, and linked-provider authentication MUST remain valid whether or not the account has claimed a username.

#### Scenario: Legacy user opens account settings

- **WHEN** an authenticated user without a username opens account settings
- **THEN** the page provides a username claim form
- **AND** the user's existing authentication methods remain unchanged

#### Scenario: User has already claimed a username

- **WHEN** an authenticated user with a username opens account settings
- **THEN** the page displays the assigned username
- **AND** it does not offer a username replacement form

### Requirement: Account presentation prefers username

The shared authenticated account profile SHALL use the assigned username as its display name and SHALL fall back to email only for a user without a username.

#### Scenario: Authenticated user has a username

- **WHEN** shared account props are produced for a user with an assigned username
- **THEN** the profile display name equals that username

#### Scenario: Legacy user has no username

- **WHEN** shared account props are produced for a user without an assigned username
- **THEN** the profile display name equals the user's email
