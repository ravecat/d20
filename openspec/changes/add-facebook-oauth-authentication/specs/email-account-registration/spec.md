## MODIFIED Requirements

### Requirement: Registration dialog exposes the supported account choices

The Register mode of the shared account dialog SHALL contain a persistently labelled email field, a Create account submit action, and an action that switches the same dialog to Login mode. Google, Apple, Discord, and Facebook SHALL each be a normal full-document provider link labelled `Sign up with <provider>` only when its own runtime configuration reports it available. Unavailable providers SHALL be omitted. An `or` separator and the provider group SHALL be present only when at least one provider link is available. Separators and the Register/Login mode switch SHALL use compact vertical spacing rather than reserving a separate large margin.

#### Scenario: Guest reviews registration choices with Facebook available

- **WHEN** the registration dialog opens while Facebook is available
- **THEN** the guest can create an account with email or start Facebook registration
- **AND** an `or` separator distinguishes email registration from provider choices
- **AND** every provider action uses the `Sign up with <provider>` label pattern
- **AND** the Facebook action uses normal full-document navigation
- **AND** available Apple, Discord, and Google links remain independently derived from their own runtime availability
- **AND** unavailable providers are not rendered
- **AND** the existing-user login action switches the same dialog to Login mode without navigation

#### Scenario: Guest reviews registration choices with Facebook unavailable

- **WHEN** the registration dialog opens while Facebook is unavailable
- **THEN** email account creation and any independently available Apple, Discord, or Google method remain enabled
- **AND** Facebook and every other unavailable provider are not rendered
- **AND** the provider separator and group are omitted when every provider is unavailable

#### Scenario: Guest reviews registration choices with Apple available

- **WHEN** the registration dialog opens while Apple is available
- **THEN** the guest can create an account with email or start Apple registration
- **AND** an `or` separator distinguishes email registration from provider choices
- **AND** every provider action uses the `Sign up with <provider>` label pattern
- **AND** the Apple action uses normal full-document navigation
- **AND** available Discord, Facebook, and Google links remain independently derived from their own runtime availability
- **AND** unavailable providers are not rendered
- **AND** the existing-user login action switches the same dialog to Login mode without navigation

#### Scenario: Guest reviews registration choices with Apple unavailable

- **WHEN** the registration dialog opens while Apple is unavailable
- **THEN** email account creation and any independently available Discord, Facebook, or Google methods remain enabled
- **AND** available provider links remain independently derived from their own runtime availability
- **AND** Apple and every other unavailable provider are not rendered

#### Scenario: Guest reviews registration choices with Discord available

- **WHEN** the registration dialog opens while Discord is available
- **THEN** the guest can create an account with email or start Discord registration
- **AND** an `or` separator distinguishes email registration from provider choices
- **AND** the Discord action uses normal full-document navigation
- **AND** available Apple, Facebook, and Google links remain independently derived from their own credentials
- **AND** unavailable providers are not rendered
- **AND** the existing-user login action switches the same dialog to Login mode without navigation

#### Scenario: Guest reviews registration choices with Discord unavailable

- **WHEN** the registration dialog opens while Discord is unavailable
- **THEN** email account creation and any independently available Apple, Facebook, or Google methods remain enabled
- **AND** Discord is not rendered while other available provider links remain independent
- **AND** no unavailable provider choice or empty provider placeholder is rendered
- **AND** the provider separator and group are omitted when every provider is unavailable

### Requirement: Account methods share registration completion

The system SHALL use one provider-neutral registration-completion page whenever a new account needs a D20 username. Magic Link completion SHALL display the pending direct-registration email and submit its confirmation token. Google, Discord, Apple, and Facebook completion SHALL carry provider identity and any optional email candidate only in authenticated server-owned state and MUST NOT expose provider subject, authorization code, provider token, raw claims, or a browser-editable replacement email through page props or form fields. Every provider completion SHALL ask only for username, MAY display an accepted optional email candidate as read-only text, and MUST remain completable when that candidate is absent. Adding another authentication provider MUST NOT require another provider-specific registration-completion page.

#### Scenario: Magic Link registration needs a username

- **WHEN** an unconfirmed direct-email user opens a valid Magic Link
- **THEN** the shared registration-completion page displays the pending account email and username field
- **AND** its submission carries the existing Magic Link confirmation token

#### Scenario: Provider registration has an acceptable email candidate

- **WHEN** an unknown provider identity supplies an acceptable email candidate
- **THEN** the shared registration-completion page asks only for username and may identify the candidate as provider-supplied account email
- **AND** the browser cannot replace the candidate
- **AND** no provider identity or credential is exposed in browser props or form fields

#### Scenario: Provider registration has no acceptable email candidate

- **WHEN** an unknown provider identity supplies no acceptable email candidate
- **THEN** the same shared registration-completion page asks only for username without requiring email
- **AND** it renders no email value or additional email guidance
- **AND** no provider identity or credential is exposed in browser props or form fields

#### Scenario: Facebook registration uses the shared completion contract

- **WHEN** an unknown Facebook identity reaches registration completion
- **THEN** the same shared page asks only for username
- **AND** any accepted Facebook email candidate remains server-owned and read-only
- **AND** submitting a valid username creates the account without a mailbox-verification step

### Requirement: Provider registration preserves an available account email

Every external-provider integration SHALL request only the minimal email-address claim when the provider supports and needs that scope. The provider adapter SHALL reduce callback data to the stable provider UID and an optional acceptable email candidate. Registration SHALL automatically persist a syntactically valid candidate only when it is case-insensitively unowned and SHALL otherwise complete with null email rather than collecting a browser replacement. Facebook SHALL follow the same provider-only-capable contract as Google, Discord, and Apple. Because Meta exposes no separate email-verification assertion, the Facebook adapter SHALL accept a candidate only when normalized and raw callback values agree and syntax validation succeeds. Email MUST NOT select, authenticate, merge, or link an account. The system MUST NOT request mailbox, contacts, or unrelated provider API access for this purpose.

Persisting an account email MUST NOT by itself opt the user into marketing communication. Marketing consent and notification preferences are separate product policies.

#### Scenario: Provider supplies an unused acceptable email

- **WHEN** an unknown external identity supplies an acceptable unowned email candidate and the player completes registration
- **THEN** the new D20 account stores that address as its canonical email
- **AND** a browser-submitted replacement email is ignored
- **AND** no mailbox or contacts permission is requested

#### Scenario: Provider supplies no acceptable email

- **WHEN** an unknown external identity supplies no email or supplies a malformed or unacceptable email
- **THEN** the player can complete provider registration with a valid unique username
- **AND** the new account stores null email
- **AND** the player may later add and D20-verify email through Account Settings

#### Scenario: Provider supplies an email already owned by D20

- **WHEN** an unknown external identity supplies an acceptable email already assigned to another D20 user
- **THEN** that address is not assigned to the new account
- **AND** the player can complete provider registration with null email
- **AND** no existing account is selected, linked, or authenticated by the email match

#### Scenario: Facebook supplies a consistent valid email

- **WHEN** an unknown Facebook identity supplies matching normalized and raw valid email values
- **THEN** the server retains the address only as an optional registration candidate
- **AND** the completion page does not render an editable email field
- **AND** the address is persisted only when it remains unowned

#### Scenario: Facebook supplies no usable email

- **WHEN** an unknown Facebook identity supplies no usable email field
- **THEN** the shared page still asks only for username
- **AND** the account is created with null email

#### Scenario: Facebook email candidate becomes unavailable

- **WHEN** a Facebook email candidate becomes owned before atomic account creation
- **THEN** registration retries with null email
- **AND** the Facebook user and identity may still be created atomically without merging accounts
