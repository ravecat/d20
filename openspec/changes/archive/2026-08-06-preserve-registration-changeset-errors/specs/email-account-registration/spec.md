## MODIFIED Requirements

### Requirement: Invalid and equivalent email submissions do not duplicate accounts

The system SHALL reject invalid email input without creating a user. Repeated or concurrent submissions whose email values are equivalent under the database's case-insensitive email identity MUST leave at most one user and MUST convert the losing submission into a controlled validation response rather than an exception. After the complete Inertia redirect, the submitting registration form MUST receive a flat email error without repeated form-scope keys. The flat error MUST preserve the first translated field message emitted by the Accounts changeset and MUST NOT replace duplicate-email feedback with controller-owned copy.

#### Scenario: Guest submits an invalid email

- **WHEN** a guest submits an email that fails Accounts validation
- **THEN** no user is created
- **AND** the dialog remains open with an email error
- **AND** the email error belongs directly to the submitting registration form
- **AND** the error preserves the first translated email message from the Accounts changeset

#### Scenario: Equivalent emails are submitted repeatedly

- **WHEN** registration receives repeated case-insensitively equivalent email values
- **THEN** at most one user exists for those values
- **AND** later submissions do not request another registration email
- **AND** the dialog provides a login action
- **AND** the duplicate-email error is visible after the registration redirect
- **AND** the error preserves the changeset's translated `has already been taken` message

#### Scenario: Equivalent emails race at the database boundary

- **WHEN** two registration inserts for case-insensitively equivalent email values overlap
- **THEN** the unique database constraint permits at most one user
- **AND** the conflicting request receives a controlled validation response
