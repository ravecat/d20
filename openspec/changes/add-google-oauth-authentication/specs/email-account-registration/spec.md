## MODIFIED Requirements

### Requirement: Registration dialog exposes the supported account choices

The Register mode of the shared account dialog SHALL contain a persistently labelled email field, a Create account submit action, an `or` separator between email registration and provider choices, an action that switches the same dialog to Login mode, and visible Google, Facebook, Apple, and Discord choices. Google SHALL always be a normal full-document registration link. Facebook, Apple, and Discord SHALL remain marked unavailable and MUST NOT submit, navigate, or initiate authorization.

#### Scenario: Guest reviews registration choices

- **WHEN** the registration dialog opens
- **THEN** the guest can create an account with email or start Google registration
- **AND** an `or` separator distinguishes email registration from provider choices
- **AND** the Google action uses normal full-document navigation
- **AND** Facebook, Apple, and Discord are visible as disabled future methods
- **AND** the existing-user login action switches the same dialog to Login mode without navigation

### Requirement: Valid email creates an unconfirmed account

The system SHALL accept a syntactically valid unique email from an unauthenticated user, create one unconfirmed passwordless D20 user, create confirmation instructions through the existing magic-link mechanism, and report that the user must check their email. Registration MUST NOT authenticate the request before the magic link is consumed. A successful request SHALL replace only the completed email registration form with its check-email result while keeping the Register mode separator, provider choices, and Login mode switch available.

#### Scenario: Guest creates an account with email

- **WHEN** a guest submits a valid unique email and application-level delivery succeeds
- **THEN** exactly one unconfirmed user exists for that email
- **AND** the user has no password
- **AND** one confirmation instruction is requested
- **AND** the dialog replaces the email registration form with a check-email result
- **AND** the Register mode separator, provider choices, and Login mode switch remain available
- **AND** the guest request remains unauthenticated

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
