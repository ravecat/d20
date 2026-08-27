## MODIFIED Requirements

### Requirement: Account methods share registration completion
The system SHALL use one provider-neutral registration-completion page whenever a new account needs a D20 username. The page SHALL ask for one username and SHALL display an accepted provider email only when the server currently treats it as an optional account-email candidate; absence of email MUST NOT block provider completion. Magic Link completion SHALL display the pending direct-registration email and submit its confirmation token. Provider completion SHALL carry the provider identity and any optional verified email candidate only in authenticated session-bound completion state and MUST NOT expose the provider subject, authorization code, provider token, or browser-editable email through page props or form fields. Adding another authentication provider MUST NOT require another provider-specific registration-completion page.

#### Scenario: Magic Link registration needs a username
- **WHEN** an unconfirmed direct-email user opens a valid Magic Link
- **THEN** the shared registration-completion page displays the pending account email and username field
- **AND** its submission carries the existing Magic Link confirmation token

#### Scenario: Provider registration has an acceptable email candidate
- **WHEN** an unknown provider identity reaches valid registration completion with an acceptable verified email candidate
- **THEN** the shared registration-completion page asks for the username and may identify the candidate as provider-supplied account email
- **AND** the browser cannot replace the candidate
- **AND** no provider identity or credential is exposed in browser props or form fields

#### Scenario: Provider registration has no acceptable email candidate
- **WHEN** an unknown provider identity reaches valid registration completion without an acceptable verified email candidate
- **THEN** the same shared registration-completion page asks for the username without requiring email
- **AND** it renders no email value or additional email guidance
- **AND** no provider identity or credential is exposed in browser props or form fields

### Requirement: Provider registration preserves an available verified account email
Every external-provider integration SHALL request only the minimal email-address claim when the provider supports and needs that scope, but provider registration MUST NOT require providers to supply email. New-account registration SHALL automatically persist a syntactically valid provider-asserted verified address as the canonical D20 `users.email` value only when it is case-insensitively unowned when the account transaction succeeds. A missing, invalid, unverified, or already-owned provider address SHALL result in provider registration with null email rather than separate email collection. Browser parameters MUST NOT replace the trusted candidate. The system MUST NOT request mailbox, contacts, or unrelated provider API access for this purpose.

Persisting an account email MUST NOT by itself opt the user into marketing communication. Marketing consent and notification preferences are separate product policies.

#### Scenario: Provider supplies an unused verified email
- **WHEN** an unknown external identity supplies an acceptable provider-verified email and the player completes registration
- **THEN** the new D20 account stores that address as its canonical email
- **AND** a browser-submitted replacement email is ignored
- **AND** no mailbox or contacts permission is requested

#### Scenario: Provider supplies no verified email
- **WHEN** an unknown external identity supplies no email or supplies a malformed or unverified email
- **THEN** the player can complete provider registration with a valid unique username
- **AND** the new account stores null email
- **AND** the player may later add and D20-verify email through Account Settings

#### Scenario: Provider supplies an email already owned by D20
- **WHEN** an unknown external identity supplies an acceptable verified email already assigned to another D20 user
- **THEN** that address is not assigned to the new account
- **AND** the player can complete provider registration with null email
- **AND** no existing account is selected, linked, or authenticated by the email match

### Requirement: Account ownership never merges implicitly by email
The canonical D20 email SHALL remain case-insensitively unique across non-null values. External identity ownership SHALL be resolved only by the exact `(provider, provider UID)` pair. A matching provider email MUST NOT authenticate an existing account or link an unknown provider identity. When such an email is already owned, the unknown provider identity MAY create a distinct account with null email after username completion. A duplicate direct-email registration MUST NOT create another account. A Magic Link sent to an existing provider-created account email SHALL authenticate that same D20 account. Linking another provider identity SHALL require the user to authenticate the existing D20 account and explicitly link from the protected Account Settings flow.

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
- **THEN** the existing account is not authenticated or linked by email
- **AND** the player may complete a distinct provider-only account with null email and a unique username
- **AND** explicit linking to the existing account still requires authenticating that account first
