## MODIFIED Requirements

### Requirement: Inertia pages expose one global authentication object

Every Inertia page SHALL expose one required `auth` object through the shared reactive Page props. The object SHALL contain required boolean `authenticated`, required nullable `prompt`, required boolean `local`, and required `providers` fields. `providers.apple.available`, `providers.discord.available`, and `providers.google.available` SHALL independently report their bounded runtime availability. `prompt` SHALL contain the existing authentication-prompt structure plus a server-owned `kind` of `info`, `warning`, or `error` when the server requests Login or sudo reauthentication and SHALL be `null` otherwise. `local` SHALL identify whether the local development mailbox is available. The former top-level `authenticated`, `authPrompt`, and `localMailboxAvailable` props MUST NOT be exposed. Provider credentials and callback data MUST NOT appear in shared props.

#### Scenario: Guest page has no prompt or local mailbox

- **WHEN** an unauthenticated guest receives an Inertia page without a stored prompt and without an available local mailbox
- **THEN** `auth.authenticated` is `false`
- **AND** `auth.prompt` is `null`
- **AND** `auth.local` is `false`
- **AND** `auth.providers.apple.available` reflects only the bounded runtime availability state
- **AND** `auth.providers.discord.available` reflects only the bounded runtime availability state
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

#### Scenario: Apple secrets remain server-side

- **WHEN** any Inertia page receives the shared authentication object
- **THEN** it contains no Apple client ID, client secret, token, subject, email, or callback payload

#### Scenario: Discord availability is shared without credentials

- **WHEN** Discord has usable server-side credentials
- **THEN** every Inertia page reports `auth.providers.discord.available` as `true`
- **AND** no Discord client secret is present in the shared page props

### Requirement: Account dialog messages expose semantic severity

The shared authentication prompt SHALL include a server-owned severity kind of `info`, `warning`, or `error`. AuthDialog SHALL present prompt messages and successful email registration or magic-link results as visually distinct inline blocks with readable text on the left, a severity-specific circular symbol on the right, a tinted surface, and a visible semantic border. Multi-line notice content SHALL align the trailing symbol with its first line, improve body-copy wrapping where the browser supports it, and keep short linked action labels intact. Info, warning, and error variants and any links in their child content SHALL use the matching global semantic theme color rather than the primary action color. Severity MUST NOT be communicated by color or icon shape alone. Informational and warning notices SHALL use polite status semantics, while error notices SHALL use alert semantics. Successful email registration and magic-link results SHALL use the informational variant. The client MUST NOT infer prompt severity from message text.

When the dialog is not requesting reauthentication, both Register and Login SHALL use the shared introduction `Save your game history and achievements. Share game sessions across devices and watch replays of completed games.`

#### Scenario: Matching Discord email requires an explicit link

- **WHEN** an unknown Discord identity returns an email already owned by a D20 account
- **THEN** the existing-method and explicit-link guidance is presented as a warning notice
- **AND** the notice remains distinguishable from the surrounding account description and forms
- **AND** assistive technology can determine that the message is a warning

#### Scenario: Local mailbox guidance follows a successful email request

- **WHEN** the local development mailbox is available before an email registration or magic-link request succeeds
- **THEN** AuthDialog does not render a standalone mailbox notice or link
- **WHEN** either email request succeeds
- **THEN** its informational check-email result appends a link to `/dev/mailbox`
- **AND** the mailbox link inherits the informational accent
- **AND** assistive technology can determine that the result is informational

#### Scenario: Authentication operation fails

- **WHEN** an authentication prompt reports an expired, unavailable, or failed operation
- **THEN** the message is presented as an error notice with alert semantics
- **AND** the message remains readable without relying on color alone

#### Scenario: Informational message wraps across lines

- **WHEN** an informational message requires multiple lines
- **THEN** its severity symbol aligns with the first line rather than the vertical midpoint of the complete paragraph
- **AND** supported browsers improve the text rag without changing the notification width
- **AND** short linked action labels remain unbroken

#### Scenario: Guest opens either account mode

- **WHEN** a guest opens Register or Login without a reauthentication prompt
- **THEN** the shared introduction explains that game sessions can be shared across devices
- **AND** Register and Login show the same introduction

### Requirement: Login mode exposes magic-link and password alternatives

Login mode SHALL show a magic-link form, an `or` separator, and a username-or-email and password form. The magic-link form SHALL require an email address, the password form SHALL accept either username or email as its identifier, and the two local forms SHALL submit independently. Google, Apple, and Discord SHALL each be a normal full-document provider link labelled `Sign in with <provider>` only when its own runtime configuration reports it available. Unavailable providers and Facebook SHALL be omitted. A second `or` separator and the provider group SHALL be present only when at least one provider link is available. Separators and the Register/Login mode switch SHALL use compact vertical spacing rather than reserving a separate large margin.

#### Scenario: Guest reviews login methods with Apple available

- **WHEN** Login mode opens while Apple is available
- **THEN** the guest can request a magic link with an email address
- **AND** the guest can submit either a username or email address with a password
- **AND** every provider action uses the `Sign in with <provider>` label pattern
- **AND** the guest can start Apple login through normal full-document navigation
- **AND** available Discord and Google links remain independently derived from their own runtime availability
- **AND** unavailable providers and Facebook are not rendered

#### Scenario: Guest reviews login methods with Apple unavailable

- **WHEN** Login mode opens while Apple is unavailable
- **THEN** the magic-link and password forms remain enabled
- **AND** available Discord and Google links remain independently derived from their own runtime availability
- **AND** Apple, Facebook, and every other unavailable provider are not rendered

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

### Requirement: Magic-link login request uses the Inertia account flow

The magic-link login form SHALL submit the email through the existing Phoenix login action using its own Inertia form instance. The response MUST use neutral language that does not reveal whether the email belongs to an account. A successful request SHALL replace the magic-link form with an informational check-email inline notification inside Login mode while leaving password and provider alternatives available. When `auth.local` is `true`, the notification SHALL append a `/dev/mailbox` link after the neutral production message. When `auth.local` is `false`, no mailbox guidance or link SHALL render.

#### Scenario: Existing email requests a magic link

- **WHEN** a guest submits the magic-link form with an existing account email
- **THEN** the existing login-instruction delivery is requested
- **AND** the dialog reports in an informational status that an email will arrive if the address is in the system
- **AND** the current Inertia page remains behind the open dialog

#### Scenario: Unknown email requests a magic link

- **WHEN** a guest submits the magic-link form with an email that does not belong to an account
- **THEN** no account is created and no authentication occurs
- **AND** the dialog presents the same neutral informational check-email result used for an existing email

#### Scenario: Local magic-link request exposes the mailbox

- **WHEN** `auth.local` is `true` and a magic-link request succeeds
- **THEN** the informational result ends with a link to `/dev/mailbox`
- **AND** no standalone mailbox notice remains elsewhere in the dialog
