## MODIFIED Requirements

### Requirement: Account forms keep independent Inertia state

Registration, magic-link login, password login, magic-link confirmation, email settings, and password settings SHALL use distinct Inertia form instances and SHALL expose flat field errors, processing, success, and failure only in the form that initiated the request. The forms MUST NOT require explicit error bags to isolate their local state. While a form is processing, its submit action MUST prevent repeated submission without disabling unrelated alternatives.

#### Scenario: Password validation fails while other login methods are visible

- **WHEN** the password form returns an invalid-credentials error through the complete Inertia redirect
- **THEN** the flat credentials error appears only in the password form
- **AND** the magic-link form and provider list do not display that error
- **AND** the guest can still request a magic link

#### Scenario: Magic-link request is processing

- **WHEN** the magic-link form is awaiting its response
- **THEN** its submit action communicates processing and cannot be submitted again
- **AND** the password form remains available

#### Scenario: Account-settings validation fails

- **WHEN** the email or password settings form returns a validation error through the complete Inertia redirect
- **THEN** the flat field error appears only in the settings form that submitted
- **AND** the sibling settings form remains available
