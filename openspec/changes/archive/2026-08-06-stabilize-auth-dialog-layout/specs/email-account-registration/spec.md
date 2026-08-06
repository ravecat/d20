## MODIFIED Requirements

### Requirement: Valid email creates an unconfirmed account

The system SHALL accept a syntactically valid unique email from an unauthenticated user, create one unconfirmed passwordless D20 user, create confirmation instructions through the existing magic-link mechanism, and report that the user must check their email. Registration MUST NOT authenticate the request before the magic link is consumed. A successful request SHALL replace only the completed email registration form with its check-email result while keeping the Register mode separator, unavailable provider choices, and Login mode switch available.

#### Scenario: Guest creates an account with email

- **WHEN** a guest submits a valid unique email and application-level delivery succeeds
- **THEN** exactly one unconfirmed user exists for that email
- **AND** the user has no password
- **AND** one confirmation instruction is requested
- **AND** the dialog replaces the email registration form with a check-email result
- **AND** the Register mode separator, provider choices, and Login mode switch remain available
- **AND** the guest request remains unauthenticated
