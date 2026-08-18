## MODIFIED Requirements

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
