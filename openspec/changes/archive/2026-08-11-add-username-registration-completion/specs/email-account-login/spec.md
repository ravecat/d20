## MODIFIED Requirements

### Requirement: Login mode exposes magic-link and password alternatives

Login mode SHALL show a magic-link form, an `or` separator, a username-or-email and password form, another `or` separator, and visible Google, Facebook, Apple, and Discord sign-in choices marked unavailable. The magic-link form SHALL require an email address, the password form SHALL accept either username or email as its identifier, the two enabled forms SHALL submit independently, and unavailable provider choices MUST NOT submit, navigate, or initiate authorization.

#### Scenario: Guest reviews login methods

- **WHEN** Login mode opens
- **THEN** the guest can request a magic link with an email address
- **AND** the guest can submit either a username or email address with a password
- **AND** Google, Facebook, Apple, and Discord are visible but disabled

### Requirement: Password login uses the existing Phoenix session security

The password login form SHALL require a username-or-email identifier and current password, SHALL offer an unchecked Keep me signed in choice, and SHALL authenticate through Accounts password verification and the existing UserAuth session creation. Username and email comparison SHALL be case-insensitive. Successful authentication MUST rotate the browser session according to existing behavior. Selecting Keep me signed in SHALL use the existing remember-me cookie behavior.

#### Scenario: Guest logs in with valid email and password

- **WHEN** a guest submits valid email and password credentials
- **THEN** the existing D20 user is authenticated
- **AND** the browser authentication session is rotated
- **AND** the shared `auth.authenticated` value no longer exposes guest account actions

#### Scenario: Guest logs in with valid username and password

- **WHEN** a guest submits a case-insensitively equivalent username and the user's valid password
- **THEN** the existing D20 user is authenticated
- **AND** the browser authentication session is rotated

#### Scenario: Guest chooses persistent login

- **WHEN** a guest submits valid username-or-email credentials with Keep me signed in selected
- **THEN** the existing signed remember-me cookie is issued

#### Scenario: Guest submits invalid credentials

- **WHEN** a guest submits an unknown identifier, an incorrect password, or an account without a password
- **THEN** the request does not authenticate the caller
- **AND** Login mode displays one generic invalid username, email, or password error only in the password form

### Requirement: Account forms keep independent Inertia state

Registration, magic-link login, password login, magic-link confirmation, username settings, email settings, and password settings SHALL use distinct Inertia form instances and SHALL expose flat field errors, processing, success, and failure only in the form that initiated the request. The forms MUST NOT require explicit error bags to isolate their local state. While a form is processing, its submit action MUST prevent repeated submission without disabling unrelated alternatives.

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

- **WHEN** the username, email, or password settings form returns a validation error through the complete Inertia redirect
- **THEN** the flat field error appears only in the settings form that submitted
- **AND** the sibling settings forms remain available
