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

The Register mode of the shared account dialog SHALL contain a persistently labelled email field, a Create account submit action, and an action that switches the same dialog to Login mode. Google, Apple, and Discord SHALL each be a normal full-document provider link labelled `Sign up with <provider>` only when its own runtime configuration reports it available. Unavailable providers and Facebook SHALL be omitted. An `or` separator and the provider group SHALL be present only when at least one provider link is available. Separators and the Register/Login mode switch SHALL use compact vertical spacing rather than reserving a separate large margin.

#### Scenario: Guest reviews registration choices with Apple available

- **WHEN** the registration dialog opens while Apple is available
- **THEN** the guest can create an account with email or start Apple registration
- **AND** an `or` separator distinguishes email registration from provider choices
- **AND** every provider action uses the `Sign up with <provider>` label pattern
- **AND** the Apple action uses normal full-document navigation
- **AND** available Discord and Google links remain independently derived from their own runtime availability
- **AND** unavailable providers and Facebook are not rendered
- **AND** the existing-user login action switches the same dialog to Login mode without navigation

#### Scenario: Guest reviews registration choices with Apple unavailable

- **WHEN** the registration dialog opens while Apple is unavailable
- **THEN** email account creation and any independently available Discord or Google method remain enabled
- **AND** available Discord and Google links remain independently derived from their own runtime availability
- **AND** Apple, Facebook, and every other unavailable provider are not rendered

#### Scenario: Guest reviews registration choices with Discord available

- **WHEN** the registration dialog opens while Discord is available
- **THEN** the guest can create an account with email or start Discord registration
- **AND** an `or` separator distinguishes email registration from provider choices
- **AND** the Discord action uses normal full-document navigation
- **AND** available Apple and Google links remain independently derived from their own credentials
- **AND** unavailable providers and Facebook are not rendered
- **AND** the existing-user login action switches the same dialog to Login mode without navigation

#### Scenario: Guest reviews registration choices with Discord unavailable

- **WHEN** the registration dialog opens while Discord is unavailable
- **THEN** email account creation and any independently available Apple or Google methods remain enabled
- **AND** Discord is not rendered while available Apple and Google links remain independent
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

The system SHALL accept a syntactically valid unique email from an unauthenticated user, create one unconfirmed passwordless D20 user, create confirmation instructions through the existing magic-link mechanism, and report that the user must check their email. Registration MUST NOT authenticate the request before the magic link is consumed. A successful request SHALL replace only the completed email registration form with an informational check-email inline notification while keeping the Register mode separator, provider choices, and Login mode switch available. When `auth.local` is `true`, the notification SHALL append a `/dev/mailbox` link after the production message. When `auth.local` is `false`, no mailbox guidance or link SHALL render. Apple availability MUST remain unchanged by completion of the email form.

#### Scenario: Guest creates an account with email

- **WHEN** a guest submits a valid unique email and application-level delivery succeeds
- **THEN** exactly one unconfirmed user exists for that email
- **AND** the user has no password
- **AND** one confirmation instruction is requested
- **AND** the dialog replaces the email registration form with an informational check-email status
- **AND** the Register mode separator, provider choices, and Login mode switch remain available
- **AND** the guest request remains unauthenticated

#### Scenario: Local email registration exposes the mailbox

- **WHEN** `auth.local` is `true` and email registration delivery succeeds
- **THEN** the informational result ends with a link to `/dev/mailbox`
- **AND** no standalone mailbox notice remains elsewhere in the dialog

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

The existing valid confirmation magic link SHALL display a non-mutating registration-completion page for the exact unconfirmed user created by registration. The completion view SHALL render directly as page content in the existing application layout and MUST NOT wrap that content in a dialog-like card surface. The completion page SHALL require a username, and its POST SHALL atomically assign that username, confirm the same user, consume the confirmation tokens, and create the existing rotated browser authentication session. Username validation or uniqueness failure MUST NOT confirm the user, consume the token, or authenticate the request. Later authenticated requests SHALL expose the same stable TypeID-backed actor identity created during email registration.

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

- **WHEN** a user who completed registration consumes a valid login magic link
- **THEN** the user is authenticated through the existing flow with the username assigned during registration completion

### Requirement: Account methods share registration completion

The system SHALL use one provider-neutral registration-completion page whenever a new account needs a D20 username. The page SHALL display the accepted email, ask for one username, and submit the credential required by the initiating method without provider-specific UI. Magic Link completion SHALL submit its confirmation token. OAuth completion SHALL carry the provider identity only in authenticated session-bound completion state and MUST NOT expose the provider subject, authorization code, or provider token through page props or form fields. Adding another OAuth provider MUST NOT require another provider-specific registration-completion page.

#### Scenario: Magic Link registration needs a username

- **WHEN** an unconfirmed user opens a valid Magic Link
- **THEN** the shared registration-completion page displays the account email and username field
- **AND** its submission carries the existing Magic Link confirmation token

#### Scenario: OAuth registration needs a username

- **WHEN** an unknown OAuth identity reaches valid registration completion
- **THEN** the same shared registration-completion page displays the verified email and username field
- **AND** no provider identity or credential is exposed in browser props or form fields

### Requirement: Provider registration preserves a verified account email

Every external-provider integration SHALL request the minimal email-address claim when the provider can supply one. New-account registration SHALL persist a syntactically valid provider-asserted verified address as the canonical D20 `users.email` value. Browser parameters MUST NOT replace that trusted address. The system MUST NOT request mailbox, contacts, or unrelated provider API access for this purpose. A future provider that cannot supply a verified email MUST require a separately collected and D20-verified address before creating the account.

Persisting an account email MUST NOT by itself opt the user into marketing communication. Marketing consent and notification preferences are separate product policies.

#### Scenario: Provider supplies a verified email

- **WHEN** an unknown external identity supplies an acceptable provider-verified email and the player completes registration
- **THEN** the new D20 account stores that address as its canonical email
- **AND** a browser-submitted replacement email is ignored
- **AND** no mailbox or contacts permission is requested

#### Scenario: Provider cannot supply a verified email

- **WHEN** a future external provider cannot assert an acceptable verified email
- **THEN** the provider identity alone does not create a D20 account
- **AND** account creation requires a separately collected and D20-verified email

### Requirement: Account ownership never merges implicitly by email

The canonical D20 email SHALL remain case-insensitively unique across users. External identity ownership SHALL be resolved only by the exact `(provider, provider UID)` pair. A matching provider email MUST NOT authenticate an existing account or link an unknown provider identity. A duplicate direct-email registration MUST NOT create another account. A Magic Link sent to an existing provider-created account email SHALL authenticate that same D20 account. Linking another provider identity SHALL require the user to authenticate the existing D20 account and explicitly link from the protected account-settings flow.

#### Scenario: Provider-created account repeats direct email registration

- **WHEN** a direct email registration submits the canonical email of an existing provider-created D20 account
- **THEN** no additional user is created
- **AND** no existing identity ownership changes
- **AND** the player can use Login mode to request a Magic Link for the existing account

#### Scenario: Provider-created account uses Magic Link

- **WHEN** the mailbox owner consumes a valid Magic Link sent to a provider-created account email
- **THEN** the existing D20 account is authenticated
- **AND** no additional user or identity is created

#### Scenario: Unknown provider identity matches an existing email account

- **WHEN** an unknown provider identity supplies the canonical email of an existing D20 account
- **THEN** the provider identity does not authenticate or link by email
- **AND** the player must authenticate the existing account and explicitly link the provider

### Requirement: Local mailbox guidance matches development availability

The shared account flow SHALL expose a local mailbox link only inside successful email registration and magic-link check-email notifications when `auth.local` is `true`. The server SHALL set `auth.local` to `true` only when development routes are enabled and `Swoosh.Adapters.Local` is the configured mail adapter and SHALL set it to `false` otherwise. AuthDialog SHALL read this value from the shared reactive Page props rather than requiring a caller-forwarded mailbox flag. AuthDialog MUST NOT render persistent local mailbox guidance before an email request succeeds.

#### Scenario: Local development mailbox is available

- **WHEN** development routes are enabled and the Local mail adapter is configured
- **THEN** `auth.local` is `true`
- **AND** initial Register and Login states do not render a mailbox link
- **AND** successful email registration and magic-link results each append a link to `/dev/mailbox`

#### Scenario: Local development mailbox is unavailable

- **WHEN** development routes are disabled or a non-Local mail adapter is configured
- **THEN** `auth.local` is `false`
- **AND** the account flow does not render a local mailbox link before or after an email request
