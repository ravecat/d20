## MODIFIED Requirements

### Requirement: Invalid and equivalent email submissions do not duplicate accounts
The system SHALL reject invalid email input without creating a user. Repeated or concurrent submissions whose email values are equivalent under the database's case-insensitive email identity MUST leave at most one user and MUST convert the losing submission into a controlled validation response rather than an exception. After the complete Inertia redirect, the submitting registration form MUST receive a flat email error without repeated form-scope keys.

#### Scenario: Guest submits an invalid email
- **WHEN** a guest submits an email that fails Accounts validation
- **THEN** no user is created
- **AND** the dialog remains open with an email error
- **AND** the email error belongs directly to the submitting registration form

#### Scenario: Equivalent emails are submitted repeatedly
- **WHEN** registration receives repeated case-insensitively equivalent email values
- **THEN** at most one user exists for those values
- **AND** later submissions do not request another registration email
- **AND** the dialog provides a login action without exposing internal constraint details
- **AND** the duplicate-email error is visible after the registration redirect

#### Scenario: Equivalent emails race at the database boundary
- **WHEN** two registration inserts for case-insensitively equivalent email values overlap
- **THEN** the unique database constraint permits at most one user
- **AND** the conflicting request receives a controlled validation response

### Requirement: Application-level delivery failure is recoverable
If confirmation delivery reports failure after the user has been created, the system SHALL keep the created account and token, SHALL NOT automatically retry delivery in the registration request, and SHALL return a controlled failure state with an action leading to the existing email login journey. The delivery failure MUST remain a flat error on the submitting registration form after the complete Inertia redirect. Provider configuration, background jobs, bounded retries, and delivery telemetry are outside this capability.

#### Scenario: Confirmation mailer reports failure
- **WHEN** account persistence succeeds and the mailer reports a delivery error
- **THEN** the request does not crash
- **AND** the created account remains unconfirmed
- **AND** the dialog explains that the email could not be sent
- **AND** the dialog offers its Login mode as the recovery path
- **AND** the registration request performs no automatic delivery retry
- **AND** the delivery error is visible after the registration redirect
