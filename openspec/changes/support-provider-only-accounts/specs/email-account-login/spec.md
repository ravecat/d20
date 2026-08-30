## MODIFIED Requirements

### Requirement: Password login uses the existing Phoenix session security
The password login form SHALL require a username-or-email identifier and current password, SHALL offer an unchecked Keep me signed in choice, and SHALL authenticate through Accounts password verification and the existing Auth session creation. Username and non-null email comparison SHALL be case-insensitive. A provider-only account with null email and a password SHALL remain eligible for password login by username. Successful authentication MUST rotate the browser session according to existing behavior. Selecting Keep me signed in SHALL use the existing remember-me cookie behavior.

#### Scenario: Guest logs in with valid email and password
- **WHEN** a guest submits valid email and password credentials for an account with that email
- **THEN** the existing D20 user is authenticated
- **AND** the browser authentication session is rotated
- **AND** the shared `auth.authenticated` value no longer exposes guest account actions

#### Scenario: Guest logs in with valid username and password
- **WHEN** a guest submits a case-insensitively equivalent username and the user's valid password
- **THEN** the existing D20 user is authenticated whether the user's email is present or null
- **AND** the browser authentication session is rotated

#### Scenario: Guest chooses persistent login
- **WHEN** a guest submits valid username-or-email credentials with Keep me signed in selected
- **THEN** the existing signed remember-me cookie is issued

#### Scenario: Guest submits invalid credentials
- **WHEN** a guest submits an unknown identifier, an incorrect password, or an account without a password
- **THEN** the request does not authenticate the caller
- **AND** Login mode displays one generic invalid username, email, or password error only in the password form

### Requirement: Server-required authentication opens the shared dialog once
When authentication or sudo mode is required, the system SHALL store the rejected safe local destination, redirect to the public home Inertia page, and expose a one-time server prompt at `auth.prompt` that opens Login mode in the shared account dialog. The prompt SHALL identify sudo reauthentication when the caller is already authenticated, SHALL expose the current username as the password identifier, and SHALL represent the current email as nullable without exposing password-presence or per-provider account flags. Login mode SHALL retain one stable Magic Link form, one stable username-or-email password form, and one provider block governed by ordinary runtime provider availability rather than composing different markup for account-method combinations. Magic Link requests without a verified destination MUST create no token or delivery, password authentication for an account without a password MUST fail generically, and every successful sudo result MUST resolve to the expected current user. A different provider identity MUST fail closed and MUST NOT switch to another account. The prompt SHALL include an understandable message when authentication was requested because of a protected route or an invalid or expired Magic Link. The prompt MUST NOT be encoded in a query parameter and MUST be removed from the session after it is assigned to the next Inertia page.

#### Scenario: Guest requests a protected page
- **WHEN** an unauthenticated guest requests a protected local GET route
- **THEN** the server stores that route as the safe post-authentication destination
- **AND** redirects to the home page
- **AND** the home page opens Login mode with an authentication-required message from `auth.prompt`

#### Scenario: Authenticated user with email requires sudo mode
- **WHEN** an authenticated user with email but without recent sudo authentication requests a sudo-protected route
- **THEN** the server stores that route as the safe post-authentication destination
- **AND** the home page opens Login mode as reauthentication with the current email locked
- **AND** the stable Magic Link, password, and runtime-available provider sections remain present

#### Scenario: Provider-only user requires sudo mode
- **WHEN** an authenticated user with null email and no recent sudo authentication requests a sudo-protected route
- **THEN** the prompt identifies the current username and represents email as null
- **AND** the stable Magic Link, password, and runtime-available provider sections remain present without account-specific method flags
- **AND** an email-less Magic Link request creates no token or delivery and a missing password fails generically

#### Scenario: Different provider account completes sudo callback
- **WHEN** a provider reauthentication callback resolves to a D20 user other than the expected current user
- **THEN** sudo authentication fails closed
- **AND** the browser session is not switched to the other user

#### Scenario: Magic link is invalid or expired
- **WHEN** a user opens an invalid or expired Magic Link confirmation URL
- **THEN** the server redirects to the home page
- **AND** the home page opens Login mode with an invalid-link message

#### Scenario: Prompt is consumed
- **WHEN** an Inertia page receives a stored server auth prompt at `auth.prompt`
- **THEN** that page exposes the prompt once
- **AND** a later page request exposes `auth.prompt` as `null`

### Requirement: Magic Link is the email recovery path
The Login mode Magic Link form SHALL provide account recovery for accounts with verified email without requiring the current password. After authenticating through the standalone confirmation page, the user SHALL be able to set a new password through Account Settings. An account with null email SHALL have no Magic Link recovery destination until its owner authenticates through another existing method and adds and verifies email. The system MUST NOT introduce a separate password-reset token or standalone forgot-password page as part of this capability.

#### Scenario: User with email no longer knows the password
- **WHEN** a user who cannot provide the current password requests a Magic Link for the account email
- **THEN** the existing neutral Magic Link request flow is used
- **AND** successful confirmation authenticates the user
- **AND** the user can set a password through Account Settings

#### Scenario: Provider-only user has no email recovery
- **WHEN** an authenticated provider-only user reviews recovery options before adding email
- **THEN** Account Settings explains that Magic Link recovery is unavailable until email is verified
- **AND** no email token or delivery is created for the null address

### Requirement: Direct account journeys use the Inertia presentation
Magic Link confirmation and Account Settings SHALL remain directly accessible and SHALL render through the Inertia application shell. Registration, ordinary login, and sudo reauthentication SHALL use the shared account dialog and MUST NOT expose standalone GET pages. The existing registration and login POST actions SHALL remain available to the dialog, and all retained journeys SHALL preserve the existing Accounts and Auth semantics without parallel HEEx auth templates. Account Settings SHALL display `Add email` for a user with null email and `Change email` for a user with non-null email, while keeping the independent password form available under existing sudo protection.

#### Scenario: Client requests the removed login page
- **WHEN** a client requests `GET /users/log-in`
- **THEN** no standalone login route handles the request

#### Scenario: User opens a valid Magic Link
- **WHEN** a user navigates to a valid `/users/log-in/:token` URL
- **THEN** an Inertia confirmation page identifies the non-null account email and submits the existing token-confirmation action
- **AND** confirmation preserves the existing session rotation and safe return behavior

#### Scenario: Authenticated user with email must reauthenticate
- **WHEN** an authenticated user with email is rejected by a sudo-protected route
- **THEN** the shared account dialog explains that reauthentication is required
- **AND** it pre-fills and locks the authenticated email according to existing behavior

#### Scenario: Authenticated provider-only user must reauthenticate
- **WHEN** an authenticated user with null email is rejected by a sudo-protected route
- **THEN** the shared account dialog identifies the username while keeping the existing Magic Link, password, and provider sections
- **AND** successful password, Magic Link, or provider reauthentication remains bound to the current account

#### Scenario: Provider-only user opens settings
- **WHEN** a recently authenticated user with null email navigates to `/profile`
- **THEN** the Inertia settings page exposes an Add email form and the independent password form
- **AND** it does not render null as an email value or claim that Magic Link recovery is available
