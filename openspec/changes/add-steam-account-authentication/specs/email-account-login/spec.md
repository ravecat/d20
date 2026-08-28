## MODIFIED Requirements

### Requirement: Inertia pages expose one global authentication object

Every Inertia page SHALL expose one required `auth` object through the shared reactive Page props. The object SHALL contain required boolean `authenticated`, required nullable `prompt`, required boolean `local`, and required `providers` fields. `providers.apple.available`, `providers.discord.available`, `providers.google.available`, and `providers.steam.available` SHALL independently report their bounded runtime availability. `prompt` SHALL contain the existing authentication-prompt structure plus a server-owned `kind` of `info`, `warning`, or `error` when the server requests Login or sudo reauthentication and SHALL be `null` otherwise. `local` SHALL identify whether the local development mailbox is available. The former top-level `authenticated`, `authPrompt`, and `localMailboxAvailable` props MUST NOT be exposed. Provider credentials, OpenID assertion values, and callback data MUST NOT appear in shared props.

#### Scenario: Guest page has no prompt or local mailbox

- **WHEN** an unauthenticated guest receives an Inertia page without a stored prompt and without an available local mailbox
- **THEN** `auth.authenticated` is `false`
- **AND** `auth.prompt` is `null`
- **AND** `auth.local` is `false`
- **AND** `auth.providers.apple.available` reflects only the bounded runtime availability state
- **AND** `auth.providers.discord.available` reflects only the bounded runtime availability state
- **AND** `auth.providers.google.available` reflects only the bounded runtime availability state
- **AND** `auth.providers.steam.available` reflects only the expected community Steam strategy and nonblank server-side API key
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

#### Scenario: Steam availability is shared without assertion data

- **WHEN** the expected community Steam strategy is allowlisted with a nonblank server-side API key
- **THEN** every Inertia page reports `auth.providers.steam.available` as `true`
- **AND** no SteamID, profile field, state, nonce, signature, assertion parameter, callback query, or API key is present in shared page props

### Requirement: Login mode exposes magic-link and password alternatives

Login mode SHALL show a magic-link form, an `or` separator, and a username-or-email and password form. The magic-link form SHALL require an email address, the password form SHALL accept either username or email as its identifier, and the two local forms SHALL submit independently. Google, Apple, Discord, and Steam SHALL each be a normal full-document provider link labelled `Sign in with <provider>` only when its provider configuration reports it available. Unavailable providers and Facebook SHALL be omitted. A second `or` separator and the provider group SHALL be present only when at least one provider link is available. Separators and the Register/Login mode switch SHALL use compact vertical spacing rather than reserving a separate large margin.

#### Scenario: Guest reviews login methods with Apple available

- **WHEN** Login mode opens while Apple is available
- **THEN** the guest can request a magic link with an email address
- **AND** the guest can submit either a username or email address with a password
- **AND** every provider action uses the `Sign in with <provider>` label pattern
- **AND** the guest can start Apple login through normal full-document navigation
- **AND** available Discord, Google, and Steam links remain independently derived from their own runtime availability
- **AND** unavailable providers and Facebook are not rendered

#### Scenario: Guest reviews login methods with Apple unavailable

- **WHEN** Login mode opens while Apple is unavailable
- **THEN** the magic-link and password forms remain enabled
- **AND** available Discord, Google, and Steam links remain independently derived from their own runtime availability
- **AND** Apple, Facebook, and every other unavailable provider are not rendered

#### Scenario: Guest reviews login methods with Discord available

- **WHEN** Login mode opens while Discord is available
- **THEN** the guest can request a magic link with an email address
- **AND** the guest can submit either a username or email address with a password
- **AND** the guest can start Discord login through normal full-document navigation
- **AND** available Apple, Google, and Steam links remain independently derived from their own provider configuration
- **AND** unavailable providers and Facebook are not rendered

#### Scenario: Guest reviews login methods with Discord unavailable

- **WHEN** Login mode opens while Discord is unavailable
- **THEN** the magic-link and password forms remain enabled
- **AND** Discord is not rendered while available Apple, Google, and Steam links remain independent
- **AND** no unavailable provider choice or empty provider placeholder is rendered
- **AND** the external-provider separator and group are omitted when every provider is unavailable

#### Scenario: Guest reviews login methods with Steam available

- **WHEN** Login mode opens while the expected community Steam strategy and API key are configured
- **THEN** the guest can request a magic link with an email address
- **AND** the guest can submit either a username or email address with a password
- **AND** the guest can start Steam login through normal full-document navigation
- **AND** available Apple, Discord, and Google links remain independently derived from their own credentials
- **AND** unavailable providers and Facebook are not rendered

#### Scenario: Guest reviews login methods with Steam unavailable

- **WHEN** Login mode opens while Steam is unavailable
- **THEN** the magic-link and password forms remain enabled
- **AND** Steam is not rendered while available Apple, Discord, and Google links remain independent
- **AND** no unavailable provider choice or empty provider placeholder is rendered
- **AND** the external-provider separator and group are omitted when every provider is unavailable
