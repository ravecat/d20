## MODIFIED Requirements

### Requirement: Inertia pages expose one global authentication object

Every Inertia page SHALL expose one required `auth` object through the shared reactive Page props. The object SHALL contain required boolean `authenticated`, required nullable `prompt`, required boolean `local`, and required `providers` fields. `providers.apple.available`, `providers.discord.available`, and `providers.google.available` SHALL independently report whether each provider has its complete usable runtime credential set. `prompt` SHALL contain the existing authentication-prompt structure plus a server-owned `kind` of `info`, `warning`, or `error` when the server requests Login or sudo reauthentication and SHALL be `null` otherwise. `local` SHALL identify whether the local development mailbox is available. The former top-level `authenticated`, `authPrompt`, and `localMailboxAvailable` props MUST NOT be exposed. Provider credentials MUST NOT appear in shared props.

#### Scenario: Guest page has no prompt or local mailbox

- **WHEN** an unauthenticated guest receives an Inertia page without a stored prompt, without an available local mailbox, and without Discord credentials
- **THEN** `auth.authenticated` is `false`
- **AND** `auth.prompt` is `null`
- **AND** `auth.local` is `false`
- **AND** `auth.providers.discord.available` is `false`
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

#### Scenario: Discord availability is shared without credentials

- **WHEN** Discord has usable server-side credentials
- **THEN** every Inertia page reports `auth.providers.discord.available` as `true`
- **AND** no Discord client secret is present in the shared page props

### Requirement: Account dialog messages expose semantic severity

The shared authentication prompt SHALL include a server-owned severity kind of `info`, `warning`, or `error`. AuthDialog SHALL present prompt messages and local development guidance as visually distinct inline blocks with readable text on the left, a severity-specific circular symbol on the right, a tinted surface, and a visible semantic border. Info, warning, and error variants and any links in their child content SHALL use the matching global semantic theme color rather than the primary action color. Severity MUST NOT be communicated by color or icon shape alone. Informational and warning notices SHALL use polite status semantics, while error notices SHALL use alert semantics. The client MUST NOT infer severity from message text.

When the dialog is not requesting reauthentication, both Register and Login SHALL use the shared introduction `Save your game history and achievements. Share game sessions across devices and watch replays of completed games.`

#### Scenario: Matching Discord email requires an explicit link

- **WHEN** an unknown Discord identity returns an email already owned by a D20 account
- **THEN** the existing-method and explicit-link guidance is presented as a warning notice
- **AND** the notice remains distinguishable from the surrounding account description and forms
- **AND** assistive technology can determine that the message is a warning

#### Scenario: Local mailbox guidance is available

- **WHEN** the local development mailbox is available
- **THEN** `Development emails are available in the local mailbox.` and its mailbox link are presented as an informational notice
- **AND** the notice uses the global informational theme color
- **AND** the mailbox link inherits the informational accent
- **AND** assistive technology can determine that the message is informational

#### Scenario: Authentication operation fails

- **WHEN** an authentication prompt reports an expired, unavailable, or failed operation
- **THEN** the message is presented as an error notice with alert semantics
- **AND** the message remains readable without relying on color alone

#### Scenario: Guest opens either account mode

- **WHEN** a guest opens Register or Login without a reauthentication prompt
- **THEN** the shared introduction explains that game sessions can be shared across devices
- **AND** Register and Login show the same introduction

### Requirement: Login mode exposes magic-link and password alternatives

Login mode SHALL show a magic-link form, an `or` separator, and a username-or-email and password form. The magic-link form SHALL require an email address, the password form SHALL accept either username or email as its identifier, and the two local forms SHALL submit independently. Google, Apple, and Discord SHALL each be a normal full-document login link only when their shared provider availability reports true. Unavailable providers and Facebook SHALL be omitted. A second `or` separator and the provider group SHALL be present only when at least one provider link is available. Separators and the Register/Login mode switch SHALL use compact vertical spacing rather than reserving a separate large margin.

#### Scenario: Guest reviews login methods with Discord available

- **WHEN** Login mode opens while Discord is available
- **THEN** the guest can request a magic link with an email address
- **AND** the guest can submit either a username or email address with a password
- **AND** the guest can start Discord login through normal full-document navigation
- **AND** available Apple and Google links remain independently derived from their own credentials
- **AND** unavailable providers and Facebook are not rendered

#### Scenario: Guest reviews login methods with Discord unavailable

- **WHEN** Login mode opens while Discord is unavailable
- **THEN** the magic-link and password forms remain enabled
- **AND** Discord is not rendered while available Apple and Google links remain independent
- **AND** no unavailable provider choice or empty provider placeholder is rendered
- **AND** the external-provider separator and group are omitted when every provider is unavailable

## ADDED Requirements

### Requirement: Account Settings exposes Discord linking state

The sudo-protected Account Settings page SHALL report whether the current user owns a Discord identity. When Discord is available and not linked, the page SHALL expose a normal full-document action that starts an explicit link intent for that same user. When Discord is linked, the page SHALL report the linked state without offering a second link or an unlink action. When Discord is unavailable, the page SHALL report it unavailable and MUST NOT initiate authorization. Discord linking state and controls SHALL remain separate from username, email, and password forms.

#### Scenario: User can link an available Discord identity

- **WHEN** a sudo-valid user with no Discord identity opens Account Settings while Discord is available
- **THEN** Account Settings exposes a normal full-document Link Discord action
- **AND** the username, email, and password forms remain independent

#### Scenario: User already linked Discord

- **WHEN** a user with a Discord identity opens Account Settings
- **THEN** Account Settings reports Discord as linked
- **AND** it does not offer a second Discord link or an unlink action

#### Scenario: Discord linking is unavailable

- **WHEN** a user without a Discord identity opens Account Settings while Discord credentials are unavailable
- **THEN** Account Settings reports Discord as unavailable
- **AND** no Discord linking action submits, navigates, or initiates authorization
