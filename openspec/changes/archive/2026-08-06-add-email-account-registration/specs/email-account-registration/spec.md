## ADDED Requirements

### Requirement: Guest registration is available from the shared shell
The system SHALL show a Register action in the shared application header to unauthenticated users and SHALL NOT show that action to authenticated users. Activating Register SHALL open the email account-registration dialog without navigating away from the current Inertia page.

#### Scenario: Guest opens registration from an application page
- **WHEN** an unauthenticated user activates Register in the shared header
- **THEN** the registration dialog opens over the current page
- **AND** the current page remains available after the dialog closes

#### Scenario: Authenticated user uses the shared shell
- **WHEN** an authenticated user opens an Inertia application page
- **THEN** the shared header does not render the Register action

### Requirement: Registration dialog exposes the supported account choices
The Register mode of the shared account dialog SHALL contain a persistently labelled email field, a Create account submit action, an `or` separator between email registration and provider choices, an action that switches the same dialog to Login mode, and visible Google, Facebook, Apple, and Discord choices marked as unavailable. Unavailable provider choices MUST NOT submit, navigate, or initiate authorization.

#### Scenario: Guest reviews registration choices
- **WHEN** the registration dialog opens
- **THEN** email account creation is the only enabled registration method
- **AND** an `or` separator distinguishes email registration from provider choices
- **AND** Google, Facebook, Apple, and Discord are visible as disabled future methods
- **AND** the existing-user login action switches the same dialog to Login mode without navigation

### Requirement: Registration dialog is keyboard and viewport accessible
The registration dialog SHALL use native dialog semantics, expose an accessible name, move focus into the open dialog, support Escape and an explicit close action, restore focus to the Register trigger after close, preserve visible focus indicators, and keep all content operable at supported narrow and wide viewport sizes.

#### Scenario: Keyboard user opens and closes registration
- **WHEN** a keyboard user activates Register and then closes the dialog with Escape
- **THEN** focus is contained within the modal while it is open
- **AND** focus returns to the Register action after it closes

#### Scenario: Registration opens on a narrow viewport
- **WHEN** a guest opens registration at a supported mobile viewport width
- **THEN** the email field, Create account action, provider choices, login action, status messages, and close action remain visible or reachable by scrolling

### Requirement: Valid email creates an unconfirmed account
The system SHALL accept a syntactically valid unique email from an unauthenticated user, create one unconfirmed passwordless D20 user, create confirmation instructions through the existing magic-link mechanism, and report that the user must check their email. Registration MUST NOT authenticate the request before the magic link is consumed.

#### Scenario: Guest creates an account with email
- **WHEN** a guest submits a valid unique email and application-level delivery succeeds
- **THEN** exactly one unconfirmed user exists for that email
- **AND** the user has no password
- **AND** one confirmation instruction is requested
- **AND** the dialog reports that the user must check their email
- **AND** the guest request remains unauthenticated

### Requirement: Invalid and equivalent email submissions do not duplicate accounts
The system SHALL reject invalid email input without creating a user. Repeated or concurrent submissions whose email values are equivalent under the database's case-insensitive email identity MUST leave at most one user and MUST convert the losing submission into a controlled validation response rather than an exception.

#### Scenario: Guest submits an invalid email
- **WHEN** a guest submits an email that fails Accounts validation
- **THEN** no user is created
- **AND** the dialog remains open with an email error

#### Scenario: Equivalent emails are submitted repeatedly
- **WHEN** registration receives repeated case-insensitively equivalent email values
- **THEN** at most one user exists for those values
- **AND** later submissions do not request another registration email
- **AND** the dialog provides a login action without exposing internal constraint details

#### Scenario: Equivalent emails race at the database boundary
- **WHEN** two registration inserts for case-insensitively equivalent email values overlap
- **THEN** the unique database constraint permits at most one user
- **AND** the conflicting request receives a controlled validation response

### Requirement: Application-level delivery failure is recoverable
If confirmation delivery reports failure after the user has been created, the system SHALL keep the created account and token, SHALL NOT automatically retry delivery in the registration request, and SHALL return a controlled failure state with an action leading to the existing email login journey. Provider configuration, background jobs, bounded retries, and delivery telemetry are outside this capability.

#### Scenario: Confirmation mailer reports failure
- **WHEN** account persistence succeeds and the mailer reports a delivery error
- **THEN** the request does not crash
- **AND** the created account remains unconfirmed
- **AND** the dialog explains that the email could not be sent
- **AND** the dialog offers its Login mode as the recovery path
- **AND** the registration request performs no automatic delivery retry

### Requirement: Magic-link confirmation preserves the created D20 identity
The existing valid confirmation magic link SHALL confirm and authenticate the exact user created by registration, rotate the browser authentication session according to the existing authentication behavior, and expose that user's stable TypeID-backed actor identity on later authenticated requests.

#### Scenario: Registered user confirms by magic link
- **WHEN** the email owner consumes the valid confirmation magic link created for registration
- **THEN** the same user record becomes confirmed and authenticated
- **AND** later authenticated actor tokens identify the same D20 user id

### Requirement: Local mailbox guidance matches development availability
The shared account flow SHALL expose the local mailbox link only when development routes are enabled and `Swoosh.Adapters.Local` is the configured mail adapter. The link MUST NOT render when either condition is false.

#### Scenario: Local development mailbox is available
- **WHEN** development routes are enabled and the Local mail adapter is configured
- **THEN** Login mode provides a link to `/dev/mailbox`

#### Scenario: Local development mailbox is unavailable
- **WHEN** development routes are disabled or a non-Local mail adapter is configured
- **THEN** the account flow does not render a local mailbox link

### Requirement: Direct registration remains available through Inertia
The existing `/users/register` journey SHALL remain directly available to guests through the Inertia application and SHALL use the same account surface, account-creation orchestration, and delivery behavior as the shared-shell dialog. Application-level delivery failure SHALL produce an understandable page state instead of an exception.

#### Scenario: Guest registers from the direct page
- **WHEN** a guest submits valid registration data through the direct Inertia page
- **THEN** the same unconfirmed account and magic-link behavior is used
- **AND** success or delivery failure returns to an understandable state on that page
