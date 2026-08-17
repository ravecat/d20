# Email Account Registration Specification

## Purpose

Define email-only account registration through the shared Inertia account experience, including persistence, magic-link confirmation, duplicate handling, delivery failures, and accessible UI states.

## Requirements

### Requirement: Guest registration is available from the shared shell

The system SHALL show a Register action in the shared application header when `auth.authenticated` is `false` and SHALL NOT show that action when `auth.authenticated` is `true`. Activating Register SHALL open the email account-registration dialog without navigating away from the current Inertia page. Registration presentation SHALL be available only through this shared dialog and the system MUST NOT expose a standalone registration GET page.

#### Scenario: Guest opens registration from an application page

- **WHEN** an unauthenticated user with `auth.authenticated` set to `false` activates Register in the shared header
- **THEN** the registration dialog opens over the current page
- **AND** the current page remains available after the dialog closes

#### Scenario: Authenticated user uses the shared shell

- **WHEN** an authenticated user opens an Inertia application page with `auth.authenticated` set to `true`
- **THEN** the shared header does not render the Register action

#### Scenario: Client requests the removed registration page

- **WHEN** a client requests `GET /users/register`
- **THEN** no standalone registration route handles the request

### Requirement: Registration dialog exposes the supported account choices

The Register mode of the shared account dialog SHALL contain a persistently labelled email field, a Create account submit action, and an action that switches the same dialog to Login mode. Google and Discord SHALL each be a normal full-document provider link labelled `Sign up with <provider>` only when its own runtime configuration reports it available. Unavailable providers and Facebook SHALL be omitted. An `or` separator and the provider group SHALL be present only when at least one provider link is available. Separators and the Register/Login mode switch SHALL use compact vertical spacing rather than reserving a separate large margin.

#### Scenario: Guest reviews registration choices with Discord available

- **WHEN** the registration dialog opens while Discord is available
- **THEN** the guest can create an account with email or start Discord registration
- **AND** an `or` separator distinguishes email registration from provider choices
- **AND** the Discord action uses normal full-document navigation
- **AND** available Google links remain independently derived from their own credentials
- **AND** unavailable providers and Facebook are not rendered
- **AND** the existing-user login action switches the same dialog to Login mode without navigation

#### Scenario: Guest reviews registration choices with Discord unavailable

- **WHEN** the registration dialog opens while Discord is unavailable
- **THEN** email account creation and any independently available Google methods remain enabled
- **AND** Discord is not rendered while available Google links remain independent
- **AND** no unavailable provider choice or empty provider placeholder is rendered
- **AND** the provider separator and group are omitted when every provider is unavailable

### Requirement: Registration dialog is keyboard and viewport accessible

The registration dialog SHALL use native modal dialog semantics, expose an accessible name, declare the registration email field as its native autofocus target, move focus to that field when the dialog opens, support Escape and an explicit close action, preserve visible focus indicators, and keep all content operable at supported narrow and wide viewport sizes. At supported mobile viewport widths, Register mode SHALL use the shared dialog's near-full-viewport, safe-area-aware inset surface. The explicit close action SHALL remain aligned with the top of the title row when the Register title wraps. Register title copy SHALL be selected directly inside the rendered heading from component input properties and MUST NOT be stored in intermediate reactive state. The implementation SHALL leave post-close focus placement to native dialog behavior and MUST NOT require a caller-supplied return-focus element or explicitly focus the Register trigger after close. The registration dialog SHALL declare native light dismissal for browsers that support it and MUST NOT implement backdrop hit testing through scripted pointer-coordinate or dialog-bound calculations. Browsers without native light-dismiss support SHALL retain Escape and the explicit close action.

#### Scenario: Keyboard user opens and closes registration

- **WHEN** a keyboard user activates Register
- **THEN** the browser's native dialog focusing behavior moves focus to the registration email field
- **AND** focus is contained within the modal while it is open
- **WHEN** the keyboard user then closes the dialog with Escape
- **THEN** the application closes the dialog without explicitly focusing the Register action

#### Scenario: Browser supports native modal light dismissal

- **WHEN** Register mode is open in a browser that supports native modal light dismissal and the guest activates the CSS-styled backdrop
- **THEN** the browser closes the dialog without application pointer-coordinate or dialog-bound hit testing
- **AND** the application does not require the Register action as a return-focus element

#### Scenario: Browser does not support native modal light dismissal

- **WHEN** Register mode is open in a browser without native modal light-dismiss support
- **THEN** the guest can still close the dialog with Escape or the explicit close action

#### Scenario: Registration opens on a narrow viewport

- **WHEN** a guest opens registration at a supported mobile viewport width
- **THEN** Register uses the near-full-viewport account surface with a small safe-area-aware outer inset
- **AND** the surface remains distinguishable from the backdrop through its border, rounded corners, and shadow
- **AND** the email field, Create account action, provider choices, login action, status messages, and close action remain visible or reachable by scrolling

#### Scenario: Registration title wraps on a narrow viewport

- **WHEN** the Register title occupies more than one line
- **THEN** the close action aligns with the top of the title row rather than the row's vertical center

#### Scenario: Registration heading selects localizable copy

- **WHEN** the shared dialog renders Register mode
- **THEN** its heading selects `Create your free account` directly from component input properties at the markup consumption site
- **AND** the selected display string is not stored in intermediate reactive state

### Requirement: Valid email creates an unconfirmed account

The system SHALL accept a syntactically valid unique email from an unauthenticated user, create one unconfirmed passwordless D20 user, create confirmation instructions through the existing magic-link mechanism, and report that the user must check their email. Registration MUST NOT authenticate the request before the magic link is consumed. A successful request SHALL replace only the completed email registration form with its check-email result while keeping the Login mode switch available and keeping the provider separator and choices only when at least one configured provider remains available.

#### Scenario: Guest creates an account with email

- **WHEN** a guest submits a valid unique email and application-level delivery succeeds
- **THEN** exactly one unconfirmed user exists for that email
- **AND** the user has no password
- **AND** one confirmation instruction is requested
- **AND** the dialog replaces the email registration form with a check-email result
- **AND** available provider choices, their separator, and the Login mode switch remain available
- **AND** the guest request remains unauthenticated

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

### Requirement: Magic-link confirmation preserves the created D20 identity

The existing valid confirmation magic link SHALL display a non-mutating registration-completion page for the exact unconfirmed user created by registration. The completion view SHALL render directly as page content in the existing application layout and MUST NOT wrap that content in a dialog-like card surface. The completion page SHALL require a username, and its POST SHALL atomically assign that username, confirm the same user, consume the confirmation tokens, and make the user eligible for the existing rotated browser authentication session. Username validation or uniqueness failure MUST NOT confirm the user, consume the token, or authenticate the request. A confirmed user consuming a valid login magic link SHALL continue to authenticate without a username requirement. Later authenticated requests SHALL expose the same stable TypeID-backed actor identity created during email registration.

#### Scenario: Registered user completes confirmation with an available username

- **WHEN** the email owner opens the valid confirmation link and submits an available valid username
- **THEN** the username is assigned to the same user record created by registration
- **AND** that user becomes confirmed and authenticated
- **AND** the browser authentication session is rotated according to existing behavior
- **AND** later authenticated actor tokens identify the same D20 user id

#### Scenario: Confirmation page is opened but not submitted

- **WHEN** a mail scanner or person performs only the valid confirmation GET
- **THEN** no username is assigned
- **AND** the user remains unconfirmed and unauthenticated
- **AND** the confirmation token remains usable

#### Scenario: Registration completion is presented as a page

- **WHEN** the email owner opens a valid registration confirmation link
- **THEN** the completion content is rendered directly in the application page layout
- **AND** no bordered, elevated, or rounded dialog-like card wraps the content

#### Scenario: Registered user submits an unavailable or invalid username

- **WHEN** the email owner submits an invalid username or one already assigned to another user
- **THEN** the completion page displays a username field error
- **AND** no username is assigned to the registering user
- **AND** the user remains unconfirmed and unauthenticated
- **AND** the confirmation token remains usable for another submission

#### Scenario: Confirmed user consumes a login magic link

- **WHEN** a confirmed user consumes a valid login magic link
- **THEN** the user is authenticated through the existing flow without being required to claim a username

### Requirement: Local mailbox guidance matches development availability

The shared account flow SHALL expose the local mailbox link throughout every AuthDialog mode and state when `auth.local` is `true`. The server SHALL set `auth.local` to `true` only when development routes are enabled and `Swoosh.Adapters.Local` is the configured mail adapter and SHALL set it to `false` otherwise. AuthDialog SHALL read this value from the shared reactive Page props rather than requiring a caller-forwarded mailbox flag.

#### Scenario: Local development mailbox is available

- **WHEN** development routes are enabled and the Local mail adapter is configured
- **THEN** `auth.local` is `true`
- **AND** AuthDialog provides a link to `/dev/mailbox` in Register mode, Login mode, and their form-result states

#### Scenario: Local development mailbox is unavailable

- **WHEN** development routes are disabled or a non-Local mail adapter is configured
- **THEN** `auth.local` is `false`
- **AND** the account flow does not render a local mailbox link
