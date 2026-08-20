## MODIFIED Requirements

### Requirement: Registration dialog exposes the supported account choices

The Register mode of the shared account dialog SHALL contain a persistently labelled email field, a Create account submit action, and an action that switches the same dialog to Login mode. Google, Apple, and Discord SHALL each be a normal full-document provider link labelled `Sign up with <provider>` only when its own runtime configuration reports it available. Unavailable providers and Facebook SHALL be omitted. An `or` separator and the provider group SHALL be present only when at least one provider link is available. Separators and the Register/Login mode switch SHALL use compact vertical spacing rather than reserving a separate large margin.

#### Scenario: Guest reviews registration choices with Apple available

- **WHEN** the registration dialog opens while Apple is available
- **THEN** the guest can create an account with email or start Apple registration
- **AND** an `or` separator distinguishes email registration from provider choices
- **AND** every provider action uses the `Sign up with <provider>` label pattern
- **AND** the Apple action uses normal full-document navigation
- **AND** available Discord and Google links remain independently derived from their own runtime availability
- **AND** unavailable providers and Facebook are not rendered
- **AND** the existing-user login action switches the same dialog to Login mode without navigation

#### Scenario: Guest reviews registration choices with Apple unavailable

- **WHEN** the registration dialog opens while Apple is unavailable
- **THEN** email account creation and any independently available Discord or Google method remain enabled
- **AND** available Discord and Google links remain independently derived from their own runtime availability
- **AND** Apple, Facebook, and every other unavailable provider are not rendered

#### Scenario: Guest reviews registration choices with Discord available

- **WHEN** the registration dialog opens while Discord is available
- **THEN** the guest can create an account with email or start Discord registration
- **AND** an `or` separator distinguishes email registration from provider choices
- **AND** the Discord action uses normal full-document navigation
- **AND** available Apple and Google links remain independently derived from their own credentials
- **AND** unavailable providers and Facebook are not rendered
- **AND** the existing-user login action switches the same dialog to Login mode without navigation

#### Scenario: Guest reviews registration choices with Discord unavailable

- **WHEN** the registration dialog opens while Discord is unavailable
- **THEN** email account creation and any independently available Apple or Google methods remain enabled
- **AND** Discord is not rendered while available Apple and Google links remain independent
- **AND** no unavailable provider choice or empty provider placeholder is rendered
- **AND** the provider separator and group are omitted when every provider is unavailable

### Requirement: Valid email creates an unconfirmed account

The system SHALL accept a syntactically valid unique email from an unauthenticated user, create one unconfirmed passwordless D20 user, create confirmation instructions through the existing magic-link mechanism, and report that the user must check their email. Registration MUST NOT authenticate the request before the magic link is consumed. A successful request SHALL replace only the completed email registration form with an informational check-email inline notification while keeping the Register mode separator, provider choices, and Login mode switch available. When `auth.local` is `true`, the notification SHALL append a `/dev/mailbox` link after the production message. When `auth.local` is `false`, no mailbox guidance or link SHALL render. Apple availability MUST remain unchanged by completion of the email form.

#### Scenario: Guest creates an account with email

- **WHEN** a guest submits a valid unique email and application-level delivery succeeds
- **THEN** exactly one unconfirmed user exists for that email
- **AND** the user has no password
- **AND** one confirmation instruction is requested
- **AND** the dialog replaces the email registration form with an informational check-email status
- **AND** the Register mode separator, provider choices, and Login mode switch remain available
- **AND** the guest request remains unauthenticated

#### Scenario: Local email registration exposes the mailbox

- **WHEN** `auth.local` is `true` and email registration delivery succeeds
- **THEN** the informational result ends with a link to `/dev/mailbox`
- **AND** no standalone mailbox notice remains elsewhere in the dialog

### Requirement: Local mailbox guidance matches development availability

The shared account flow SHALL expose a local mailbox link only inside successful email registration and magic-link check-email notifications when `auth.local` is `true`. The server SHALL set `auth.local` to `true` only when development routes are enabled and `Swoosh.Adapters.Local` is the configured mail adapter and SHALL set it to `false` otherwise. AuthDialog SHALL read this value from the shared reactive Page props rather than requiring a caller-forwarded mailbox flag. AuthDialog MUST NOT render persistent local mailbox guidance before an email request succeeds.

#### Scenario: Local development mailbox is available

- **WHEN** development routes are enabled and the Local mail adapter is configured
- **THEN** `auth.local` is `true`
- **AND** initial Register and Login states do not render a mailbox link
- **AND** successful email registration and magic-link results each append a link to `/dev/mailbox`

#### Scenario: Local development mailbox is unavailable

- **WHEN** development routes are disabled or a non-Local mail adapter is configured
- **THEN** `auth.local` is `false`
- **AND** the account flow does not render a local mailbox link before or after an email request
