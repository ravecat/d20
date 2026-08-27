## ADDED Requirements

### Requirement: Completed accounts have a username and verified authentication identity
A completed D20 account SHALL have one valid immutable unique username and at least one verified authentication identity. A verified authentication identity SHALL be either a non-null account email whose ownership was verified by D20 or an accepted provider, or an external identity uniquely owned through the exact provider and provider UID pair. A password alone MUST NOT satisfy the verified-identity invariant. A pending direct-email registration MAY temporarily have email without username or completed confirmation state, but it MUST remain unauthenticated until Magic Link completion.

#### Scenario: Provider identity completes an account without email
- **WHEN** an unknown verified provider identity completes registration with a valid unique username and no acceptable email candidate
- **THEN** the resulting account has that username and provider identity
- **AND** its email is null
- **AND** it is a completed account eligible for authentication through the provider

#### Scenario: Direct-email registration remains pending
- **WHEN** a guest starts direct-email registration but has not completed the Magic Link username step
- **THEN** the pending user may contain the candidate email
- **AND** it has no completed username or authenticated session
- **AND** it is not treated as a completed account

#### Scenario: Password does not replace verified identity
- **WHEN** an account has a password but has neither a verified email nor an external provider identity
- **THEN** the account does not satisfy the completed-account invariant
- **AND** the password alone MUST NOT activate it

### Requirement: Account email is nullable and unique when present
The `users.email` field SHALL permit null without storing a placeholder, while every non-null email SHALL remain case-insensitively unique and syntactically valid. Application schemas, fixtures, projections, forms, and operational code SHALL represent absence as null and MUST NOT coerce it to an empty string, fabricated address, or provider UID.

#### Scenario: Multiple provider-only accounts are persisted
- **WHEN** distinct external identities create distinct provider-only accounts
- **THEN** each user row may contain null email
- **AND** no placeholder value is required to distinguish the accounts

#### Scenario: Equivalent non-null emails conflict
- **WHEN** two users would receive case-insensitively equivalent non-null emails
- **THEN** the database unique constraint permits at most one owner
- **AND** the losing operation receives a controlled result

### Requirement: Provider registration treats verified email as optional
An unknown verified provider identity SHALL be able to complete registration after the player chooses a valid unique username, whether or not the provider supplies email. A syntactically valid provider-asserted verified email SHALL be persisted automatically only when it is case-insensitively unowned at account creation. A missing, malformed, unverified, or already-owned provider email SHALL be discarded for account persistence and the user SHALL instead be created with null email. Provider email MUST NOT select, authenticate, merge, or link an existing D20 account.

#### Scenario: Provider supplies an unused verified email
- **WHEN** an unknown verified provider identity completes registration with a valid username and an acceptable unowned verified email
- **THEN** one user is created with that username and email
- **AND** the exact external identity is linked to that user in the same transaction

#### Scenario: Provider supplies no usable email
- **WHEN** an unknown verified provider identity completes registration with a missing, malformed, or unverified email
- **THEN** one user is created with null email and the selected username
- **AND** the exact external identity is linked to that user in the same transaction

#### Scenario: Provider email belongs to another account
- **WHEN** an unknown verified provider identity supplies an email already owned by a D20 user
- **THEN** the existing user is not selected, authenticated, or linked
- **AND** a distinct provider-only account may be created with null email after valid username completion

#### Scenario: Email ownership changes during provider completion
- **WHEN** an acceptable provider email becomes owned concurrently with provider registration
- **THEN** the provider registration may retry atomically without that email
- **AND** at most one user owns the email
- **AND** the provider user and identity are either both created or both absent

### Requirement: Provider-only users can add a verified email
A sudo-valid authenticated user whose email is null SHALL be able to submit a candidate email in Account Settings and receive the existing D20 email-change verification message. The user row SHALL retain null email until the confirmation token is successfully consumed. Confirmation SHALL revalidate case-insensitive uniqueness and atomically attach the email. An invalid, expired, replayed, or conflicting token MUST NOT change the user email.

#### Scenario: Provider-only user requests email addition
- **WHEN** a sudo-valid provider-only user submits a valid currently unowned email
- **THEN** verification instructions are sent to the candidate address
- **AND** the persisted user email remains null before confirmation

#### Scenario: Provider-only user confirms the email
- **WHEN** the same user consumes a valid unexpired confirmation token while the candidate remains unowned
- **THEN** the candidate becomes the user's canonical email
- **AND** email Magic Link and notification features may use it

#### Scenario: Candidate becomes owned before confirmation
- **WHEN** another account acquires the candidate email before the provider-only user consumes the token
- **THEN** confirmation returns a controlled unavailable-address result
- **AND** the provider-only user's email remains null
- **AND** no account ownership changes

### Requirement: Email-dependent operations require a verified destination
The system SHALL create Magic Link, email-change, recovery, or notification delivery only when that operation has a verified non-null destination. An operation without a destination SHALL be omitted from an authenticated user's available methods or return a controlled unavailable result before creating a token, delivery job, or message. Public signed-out login responses SHALL remain neutral and MUST NOT disclose whether an entered address belongs to an account.

#### Scenario: Provider-only account has no email delivery
- **WHEN** an email-dependent operation targets a provider-only user with null email
- **THEN** no email token, delivery job, or message is created for that user
- **AND** no empty or fabricated recipient is used

#### Scenario: Signed-out user requests an unknown email
- **WHEN** a guest submits an email that belongs to no account, including when the intended person has a provider-only account
- **THEN** the response uses the same neutral language as an existing-email request
- **AND** no account existence or provider linkage is disclosed

### Requirement: Existing access survives the optional-email migration
The migration SHALL preserve every existing user ID, non-null email, username, password hash, confirmation timestamp, session token, and external identity ownership while removing only the email not-null constraint. Existing authenticated sessions SHALL remain valid. A rollback that restores the not-null constraint MUST refuse to fabricate addresses and SHALL require all null-email rows to be explicitly resolved first.

#### Scenario: Existing account crosses the migration
- **WHEN** the nullable-email migration is deployed over existing users
- **THEN** each existing account retains its prior fields, linked identities, and session access
- **AND** its non-null email remains protected by the existing case-insensitive unique index

#### Scenario: Rollback encounters provider-only users
- **WHEN** rollback is requested after one or more users have null email
- **THEN** the not-null constraint is not restored until each affected account has an explicitly verified resolution
- **AND** no placeholder email is generated
