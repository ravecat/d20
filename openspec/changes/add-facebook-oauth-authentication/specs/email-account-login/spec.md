## MODIFIED Requirements

### Requirement: Inertia pages expose one global authentication object

Every Inertia page SHALL expose one required `auth` object through the shared reactive Page props. The object SHALL contain required boolean `authenticated`, required nullable `prompt`, required boolean `local`, and required `providers` fields. `providers.apple.available`, `providers.discord.available`, `providers.facebook.available`, and `providers.google.available` SHALL independently report their bounded runtime availability. `prompt` SHALL contain the existing authentication-prompt structure plus a server-owned `kind` of `info`, `warning`, or `error` when the server requests Login or sudo reauthentication and SHALL be `null` otherwise. A sudo prompt SHALL expose the current username identifier and represent current email as nullable without exposing password presence, linked-provider membership, or provider UIDs. `local` SHALL identify whether the local development mailbox is available. The former top-level `authenticated`, `authPrompt`, and `localMailboxAvailable` props MUST NOT be exposed. Provider credentials and callback data MUST NOT appear in shared props.

#### Scenario: Guest page has no prompt or local mailbox

- **WHEN** an unauthenticated guest receives an Inertia page without a stored prompt and without an available local mailbox
- **THEN** `auth.authenticated` is `false`
- **AND** `auth.prompt` is `null`
- **AND** `auth.local` is `false`
- **AND** every provider availability value reflects only that provider's bounded runtime state
- **AND** none of the former flat authentication props is present

#### Scenario: Authenticated page reports account state

- **WHEN** an authenticated user receives an Inertia page
- **THEN** `auth.authenticated` is `true`
- **AND** the shared header derives its account actions from that nested value

#### Scenario: Stored prompt is nested in auth

- **WHEN** the server assigns a stored authentication prompt to an Inertia response
- **THEN** the existing prompt structure is available at `auth.prompt`
- **AND** its `kind` explicitly identifies the server-selected semantic severity
- **AND** reactive Page consumers can open the requested account dialog from that nested value

#### Scenario: Provider secrets remain server-side

- **WHEN** any Inertia page receives the shared authentication object
- **THEN** it contains no provider client ID, client secret, token, subject, email, or callback payload

#### Scenario: Facebook availability is shared without credentials

- **WHEN** Facebook has both usable server-side credentials
- **THEN** every Inertia page reports `auth.providers.facebook.available` as `true`
- **AND** no Facebook credential is present in shared page props

#### Scenario: Provider-only user receives a sudo prompt

- **WHEN** an authenticated user with null email requires sudo reauthentication
- **THEN** `auth.prompt.email` is `null`
- **AND** `auth.prompt.identifier` contains the current username
- **AND** Facebook availability remains derived from runtime credentials rather than account email

### Requirement: Login mode exposes magic-link and password alternatives

Login mode SHALL show a magic-link form, an `or` separator, and a username-or-email and password form. The magic-link form SHALL require an email address, the password form SHALL accept either username or email as its identifier, and the two local forms SHALL submit independently. Google, Apple, Discord, and Facebook SHALL each be a normal full-document provider link labelled `Sign in with <provider>` only when its own runtime configuration reports it available. Unavailable providers SHALL be omitted. A second `or` separator and the provider group SHALL be present only when at least one provider link is available. Separators and the Register/Login mode switch SHALL use compact vertical spacing rather than reserving a separate large margin.

#### Scenario: Guest reviews login methods with Facebook available

- **WHEN** Login mode opens while Facebook is available
- **THEN** the guest can request a magic link with an email address
- **AND** the guest can submit either a username or email address with a password
- **AND** every provider action uses the `Sign in with <provider>` label pattern
- **AND** the guest can start Facebook login through normal full-document navigation
- **AND** available Apple, Discord, and Google links remain independently derived from their own runtime availability
- **AND** unavailable providers are not rendered

#### Scenario: Guest reviews login methods with Facebook unavailable

- **WHEN** Login mode opens while Facebook is unavailable
- **THEN** the magic-link and password forms remain enabled
- **AND** available Apple, Discord, and Google links remain independently derived from their own runtime availability
- **AND** Facebook and every other unavailable provider are not rendered
- **AND** the external-provider separator and group are omitted when every provider is unavailable

#### Scenario: Guest reviews login methods with Apple available

- **WHEN** Login mode opens while Apple is available
- **THEN** the guest can request a magic link with an email address
- **AND** the guest can submit either a username or email address with a password
- **AND** every provider action uses the `Sign in with <provider>` label pattern
- **AND** the guest can start Apple login through normal full-document navigation
- **AND** available Discord, Facebook, and Google links remain independently derived from their own runtime availability
- **AND** unavailable providers are not rendered

#### Scenario: Guest reviews login methods with Apple unavailable

- **WHEN** Login mode opens while Apple is unavailable
- **THEN** the magic-link and password forms remain enabled
- **AND** available Discord, Facebook, and Google links remain independently derived from their own runtime availability
- **AND** Apple and every other unavailable provider are not rendered

#### Scenario: Guest reviews login methods with Discord available

- **WHEN** Login mode opens while Discord is available
- **THEN** the guest can request a magic link with an email address
- **AND** the guest can submit either a username or email address with a password
- **AND** the guest can start Discord login through normal full-document navigation
- **AND** available Apple, Facebook, and Google links remain independently derived from their own credentials
- **AND** unavailable providers are not rendered

#### Scenario: Guest reviews login methods with Discord unavailable

- **WHEN** Login mode opens while Discord is unavailable
- **THEN** the magic-link and password forms remain enabled
- **AND** Discord is not rendered while other available provider links remain independent
- **AND** no unavailable provider choice or empty provider placeholder is rendered
- **AND** the external-provider separator and group are omitted when every provider is unavailable

## ADDED Requirements

### Requirement: Account Settings exposes Facebook linking state

The sudo-protected Account Settings page SHALL report whether the current user owns a Facebook identity when Facebook is available. When Facebook is available and not linked, the page SHALL expose a normal full-document action that starts an explicit link intent for that same user. When Facebook is available and linked, the page SHALL report the linked state without offering a second link or an unlink action. When Facebook is unavailable, the page SHALL omit Facebook and MUST NOT initiate authorization. Facebook linking state and controls SHALL remain separate from username, nullable email, and password forms, and a provider-only user MUST NOT be required to add email before linking Facebook.

#### Scenario: User can link an available Facebook identity

- **WHEN** a sudo-valid user with no Facebook identity opens Account Settings while Facebook is available
- **THEN** Account Settings exposes a normal full-document Link Facebook action
- **AND** the username, email, and password forms remain independent

#### Scenario: Provider-only user can link Facebook

- **WHEN** a sudo-valid user with null email and no Facebook identity opens Account Settings while Facebook is available
- **THEN** Account Settings exposes the same Link Facebook action
- **AND** linking does not require adding email or change the account's null email

#### Scenario: User already linked available Facebook

- **WHEN** a user with a Facebook identity opens Account Settings while Facebook is available
- **THEN** Account Settings reports Facebook as linked
- **AND** it does not offer a second Facebook link or an unlink action

#### Scenario: Facebook linking is unavailable

- **WHEN** a user opens Account Settings while Facebook credentials are unavailable
- **THEN** Account Settings omits the Facebook provider item
- **AND** no Facebook linking action submits, navigates, or initiates authorization
