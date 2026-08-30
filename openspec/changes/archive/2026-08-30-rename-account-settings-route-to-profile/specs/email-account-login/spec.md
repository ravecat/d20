## MODIFIED Requirements

### Requirement: Direct account journeys use the Inertia presentation

Magic-link confirmation and Account Settings SHALL remain directly accessible and SHALL render through the Inertia application shell. Account Settings SHALL use `/profile` as its only route family for the page, account updates, email confirmation, and provider-link starts. The system MUST NOT route or redirect requests through the former `/users/settings` family. Registration, ordinary login, and sudo reauthentication SHALL use the shared account dialog and MUST NOT expose standalone GET pages. The existing registration and login POST actions SHALL remain available to the dialog, and all retained journeys SHALL preserve the existing Accounts and Auth semantics without parallel HEEx auth templates.

#### Scenario: Client requests the removed login page

- **WHEN** a client requests `GET /users/log-in`
- **THEN** no standalone login route handles the request

#### Scenario: User opens a valid magic link

- **WHEN** a user navigates to a valid `/users/log-in/:token` URL
- **THEN** an Inertia confirmation page identifies the account email and submits the existing token-confirmation action
- **AND** confirmation preserves the existing session rotation and safe return behavior

#### Scenario: Authenticated user must reauthenticate

- **WHEN** an authenticated user is rejected by a sudo-protected route
- **THEN** the shared account dialog explains that reauthentication is required
- **AND** it pre-fills and locks the authenticated email according to existing behavior

#### Scenario: Authenticated user opens profile

- **WHEN** a recently authenticated user navigates to `/profile`
- **THEN** an Inertia Account Settings page exposes independent email-change and password-change forms
- **AND** each form reports only its own validation and processing state
- **AND** account updates submit to `/profile`
- **AND** provider-link actions use `/profile/auth/:provider`
- **AND** email confirmation links use `/profile/confirm-email/:token`

#### Scenario: Client requests the removed Account Settings route family

- **WHEN** a client requests `/users/settings` or a descendant of `/users/settings`
- **THEN** no route handles the request
- **AND** the system does not issue a compatibility redirect to `/profile`
