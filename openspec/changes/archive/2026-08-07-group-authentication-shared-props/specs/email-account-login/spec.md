## ADDED Requirements

### Requirement: Inertia pages expose one global authentication object

Every Inertia page SHALL expose one required `auth` object through the shared reactive Page props. The object SHALL contain required boolean `authenticated`, required nullable `prompt`, and required boolean `local` fields. `prompt` SHALL contain the existing authentication-prompt structure when the server requests Login or sudo reauthentication and SHALL be `null` otherwise. `local` SHALL identify whether the local development mailbox is available. The former top-level `authenticated`, `authPrompt`, and `localMailboxAvailable` props MUST NOT be exposed.

#### Scenario: Guest page has no prompt or local mailbox

- **WHEN** an unauthenticated guest receives an Inertia page without a stored prompt and without an available local mailbox
- **THEN** `auth.authenticated` is `false`
- **AND** `auth.prompt` is `null`
- **AND** `auth.local` is `false`
- **AND** none of the former flat authentication props is present

#### Scenario: Authenticated page reports account state

- **WHEN** an authenticated user receives an Inertia page
- **THEN** `auth.authenticated` is `true`
- **AND** the shared header derives its account actions from that nested value

#### Scenario: Stored prompt is nested in auth

- **WHEN** the server assigns a stored authentication prompt to an Inertia response
- **THEN** the existing prompt structure is available at `auth.prompt`
- **AND** reactive Page consumers can open the requested account dialog from that nested value

## MODIFIED Requirements

### Requirement: Password login uses the existing Phoenix session security

The password login form SHALL require an email and current password, SHALL offer an unchecked Keep me signed in choice, and SHALL authenticate through the existing Accounts password verification and UserAuth session creation. Successful authentication MUST rotate the browser session according to existing behavior. Selecting Keep me signed in SHALL use the existing remember-me cookie behavior.

#### Scenario: Guest logs in with valid email and password

- **WHEN** a guest submits valid email and password credentials
- **THEN** the existing D20 user is authenticated
- **AND** the browser authentication session is rotated
- **AND** the shared `auth.authenticated` value no longer exposes guest account actions

#### Scenario: Guest chooses persistent login

- **WHEN** a guest submits valid credentials with Keep me signed in selected
- **THEN** the existing signed remember-me cookie is issued

#### Scenario: Guest submits invalid credentials

- **WHEN** a guest submits an unknown email, an incorrect password, or an account without a password
- **THEN** the request does not authenticate the caller
- **AND** Login mode displays one generic invalid email or password error only in the password form

### Requirement: Server-required authentication opens the shared dialog once

When authentication or sudo mode is required, the system SHALL store the rejected safe local destination, redirect to the public home Inertia page, and expose a one-time server prompt at `auth.prompt` that opens Login mode in the shared account dialog. The prompt SHALL identify sudo reauthentication when the caller is already authenticated and SHALL include an understandable message when authentication was requested because of a protected route or an invalid or expired magic link. The prompt MUST NOT be encoded in a query parameter and MUST be removed from the session after it is assigned to the next Inertia page.

#### Scenario: Guest requests a protected page

- **WHEN** an unauthenticated guest requests a protected local GET route
- **THEN** the server stores that route as the safe post-authentication destination
- **AND** redirects to the home page
- **AND** the home page opens Login mode with an authentication-required message from `auth.prompt`

#### Scenario: Authenticated user requires sudo mode

- **WHEN** an authenticated user without recent sudo authentication requests a sudo-protected route
- **THEN** the server stores that route as the safe post-authentication destination
- **AND** the home page opens Login mode as reauthentication with the current email locked

#### Scenario: Magic link is invalid or expired

- **WHEN** a user opens an invalid or expired magic-link confirmation URL
- **THEN** the server redirects to the home page
- **AND** the home page opens Login mode with an invalid-link message

#### Scenario: Prompt is consumed

- **WHEN** an Inertia page receives a stored server auth prompt at `auth.prompt`
- **THEN** that page exposes the prompt once
- **AND** a later page request exposes `auth.prompt` as `null`
