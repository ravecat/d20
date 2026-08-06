## ADDED Requirements

### Requirement: Server-required authentication opens the shared dialog once
When authentication or sudo mode is required, the system SHALL store the rejected safe local destination, redirect to the public home Inertia page, and expose a one-time server prompt that opens Login mode in the shared account dialog. The prompt SHALL identify sudo reauthentication when the caller is already authenticated and SHALL include an understandable message when authentication was requested because of a protected route or an invalid or expired magic link. The prompt MUST NOT be encoded in a query parameter and MUST be removed from the session after it is assigned to the next Inertia page.

#### Scenario: Guest requests a protected page
- **WHEN** an unauthenticated guest requests a protected local GET route
- **THEN** the server stores that route as the safe post-authentication destination
- **AND** redirects to the home page
- **AND** the home page opens Login mode with an authentication-required message

#### Scenario: Authenticated user requires sudo mode
- **WHEN** an authenticated user without recent sudo authentication requests a sudo-protected route
- **THEN** the server stores that route as the safe post-authentication destination
- **AND** the home page opens Login mode as reauthentication with the current email locked

#### Scenario: Magic link is invalid or expired
- **WHEN** a user opens an invalid or expired magic-link confirmation URL
- **THEN** the server redirects to the home page
- **AND** the home page opens Login mode with an invalid-link message

#### Scenario: Prompt is consumed
- **WHEN** an Inertia page receives a stored server auth prompt
- **THEN** that page exposes the prompt once
- **AND** a later page request does not expose the same prompt again

### Requirement: Magic link is the password recovery path
The Login mode magic-link form SHALL provide account recovery without requiring the current password. After authenticating through the standalone confirmation page, the user SHALL be able to set a new password through Account Settings. The system MUST NOT introduce a separate password-reset token or standalone forgot-password page as part of this capability.

#### Scenario: User no longer knows the password
- **WHEN** a user who cannot provide the current password requests a magic link
- **THEN** the existing neutral magic-link request flow is used
- **AND** successful confirmation authenticates the user
- **AND** the user can set a password through Account Settings

## MODIFIED Requirements

### Requirement: Successful authentication returns only to a safe local page
Account forms SHALL distinguish the local page receiving the immediate form response from the intended post-authentication destination. The server MUST accept either path only when it is a local absolute path without a scheme, host, or protocol-relative prefix. Password authentication SHALL return immediately to the accepted post-authentication path. Registration and magic-link request results SHALL return to the Inertia page behind the open dialog, while a magic link consumed in the same browser session SHALL return to the accepted post-authentication path. Missing or rejected values SHALL use safe route-specific fallbacks.

#### Scenario: Password login returns to the originating game page
- **WHEN** a guest opens Login on a game detail page and authenticates with a password
- **THEN** the authenticated response returns to that game detail path

#### Scenario: External return target is rejected
- **WHEN** an account form submits an external, protocol-relative, or malformed return target
- **THEN** the target is not stored or used for redirection
- **AND** authentication uses the existing safe signed-in fallback

#### Scenario: Prompted magic-link request stays on its host page before later authentication
- **WHEN** the server opens Login mode on the home page while a different safe post-authentication destination is stored
- **AND** the guest requests a magic link
- **THEN** the check-email response returns behind the open dialog on the home page
- **AND** consuming the link in the same browser session returns to the stored post-authentication destination

### Requirement: Direct account journeys use the Inertia presentation
Magic-link confirmation and account settings SHALL remain directly accessible and SHALL render through the Inertia application shell. Registration, ordinary login, and sudo reauthentication SHALL use the shared account dialog and MUST NOT expose standalone GET pages. The existing registration and login POST actions SHALL remain available to the dialog, and all retained journeys SHALL preserve the existing Accounts and UserAuth semantics without parallel HEEx auth templates.

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

#### Scenario: Authenticated user opens settings
- **WHEN** a recently authenticated user navigates to `/users/settings`
- **THEN** an Inertia settings page exposes independent email-change and password-change forms
- **AND** each form reports only its own validation and processing state
