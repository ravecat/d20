## MODIFIED Requirements

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

### Requirement: Local mailbox guidance matches development availability

The shared account flow SHALL expose the local mailbox link when `auth.local` is `true`. The server SHALL set `auth.local` to `true` only when development routes are enabled and `Swoosh.Adapters.Local` is the configured mail adapter and SHALL set it to `false` otherwise. AuthDialog SHALL read this value from the shared reactive Page props rather than requiring a caller-forwarded mailbox flag.

#### Scenario: Local development mailbox is available

- **WHEN** development routes are enabled and the Local mail adapter is configured
- **THEN** `auth.local` is `true`
- **AND** Login mode provides a link to `/dev/mailbox`

#### Scenario: Local development mailbox is unavailable

- **WHEN** development routes are disabled or a non-Local mail adapter is configured
- **THEN** `auth.local` is `false`
- **AND** the account flow does not render a local mailbox link
