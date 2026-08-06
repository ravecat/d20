## MODIFIED Requirements

### Requirement: Guest registration is available from the shared shell
The system SHALL show a Register action in the shared application header to unauthenticated users and SHALL NOT show that action to authenticated users. Activating Register SHALL open the email account-registration dialog without navigating away from the current Inertia page. Registration presentation SHALL be available only through this shared dialog and the system MUST NOT expose a standalone registration GET page.

#### Scenario: Guest opens registration from an application page
- **WHEN** an unauthenticated user activates Register in the shared header
- **THEN** the registration dialog opens over the current page
- **AND** the current page remains available after the dialog closes

#### Scenario: Authenticated user uses the shared shell
- **WHEN** an authenticated user opens an Inertia application page
- **THEN** the shared header does not render the Register action

#### Scenario: Client requests the removed registration page
- **WHEN** a client requests `GET /users/register`
- **THEN** no standalone registration route handles the request

## REMOVED Requirements

### Requirement: Direct registration remains available through Inertia
**Reason**: Registration presentation is consolidated into the shared account dialog and the standalone GET page is intentionally removed.

**Migration**: Open Register from the shared application header and continue submitting the existing `POST /users/register` form action.
