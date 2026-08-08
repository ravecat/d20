## MODIFIED Requirements

### Requirement: Valid email creates an unconfirmed account

The system SHALL accept a syntactically valid unique email from an unauthenticated user, create one unconfirmed passwordless D20 user, persistently enqueue confirmation instructions through the existing magic-link mechanism, and report that the user must check their email without waiting for the provider API call. Registration MUST NOT authenticate the request before the magic link is consumed. A successful request SHALL replace only the completed email registration form with its check-email result while keeping the Register mode separator, unavailable provider choices, and Login mode switch available.

#### Scenario: Guest creates an account with email

- **WHEN** a guest submits a valid unique email and persistent enqueueing succeeds
- **THEN** exactly one unconfirmed user exists for that email
- **AND** the user has no password
- **AND** one confirmation delivery job is accepted
- **AND** the registration request performs no provider API call
- **AND** the dialog replaces the email registration form with a check-email result
- **AND** the Register mode separator, provider choices, and Login mode switch remain available
- **AND** the guest request remains unauthenticated

### Requirement: Application-level delivery failure is recoverable

If persistent confirmation enqueueing reports failure after the user has been created, the system SHALL keep the created account, SHALL NOT call the provider in the registration request, and SHALL return a controlled failure state with an action leading to the existing email login journey. The enqueue failure MUST remain a flat error on the submitting registration form after the complete Inertia redirect. If a persistently accepted job later reaches terminal provider failure, the system SHALL keep the account, generated token, and terminal job evidence, SHALL NOT alter the completed registration HTTP response, and SHALL support a fresh delivery request through the existing email login journey.

#### Scenario: Confirmation job enqueueing fails

- **WHEN** account persistence succeeds and persistent job enqueueing reports an error
- **THEN** the request does not crash
- **AND** the created account remains unconfirmed
- **AND** the registration request makes no provider API call
- **AND** the dialog explains that the email could not be scheduled
- **AND** the dialog offers its Login mode as the recovery path
- **AND** the enqueue error is visible after the registration redirect

#### Scenario: Queued confirmation reaches terminal failure

- **WHEN** the registration response has completed and its queued confirmation job reaches terminal provider failure
- **THEN** the created account remains unconfirmed
- **AND** the generated token and terminal job evidence remain available for their configured retention periods
- **AND** no Inertia HTML error dialog is produced
- **AND** a fresh Login mode magic-link request remains the player recovery path
