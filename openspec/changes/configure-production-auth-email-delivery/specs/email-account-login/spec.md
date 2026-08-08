## MODIFIED Requirements

### Requirement: Magic-link login request uses the Inertia account flow

The magic-link login form SHALL submit the email through the existing Phoenix login action using its own Inertia form instance. For an existing account, the action SHALL persistently enqueue login instructions and SHALL return without waiting for a provider API call. The response MUST use neutral language that does not reveal whether the email belongs to an account or whether enqueueing or later provider delivery succeeded. A completed request SHALL show a check-email result inside Login mode while leaving password and provider alternatives available.

#### Scenario: Existing email requests a magic link

- **WHEN** a guest submits the magic-link form with an existing account email
- **THEN** one persistent login-instruction delivery job is requested
- **AND** the HTTP request performs no provider API call
- **AND** the dialog reports that an email will arrive if the address is in the system
- **AND** the current Inertia page remains behind the open dialog

#### Scenario: Unknown email requests a magic link

- **WHEN** a guest submits the magic-link form with an email that does not belong to an account
- **THEN** no account is created, no delivery job is enqueued, and no authentication occurs
- **AND** the dialog presents the same neutral check-email result used for an existing email

#### Scenario: Existing email cannot be enqueued

- **WHEN** a guest submits an existing account email and persistent enqueueing fails
- **THEN** the failure is recorded for operators without exposing the submitted address
- **AND** the dialog presents the same neutral check-email result used for every magic-link request
- **AND** no provider API call runs in the HTTP request

#### Scenario: Queued login message reaches terminal failure

- **WHEN** a login delivery job reaches terminal provider failure after the HTTP response completes
- **THEN** the completed response remains neutral
- **AND** no Inertia HTML error dialog is produced
- **AND** the user can make a fresh magic-link request
