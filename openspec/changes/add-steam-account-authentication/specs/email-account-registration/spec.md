## MODIFIED Requirements

### Requirement: Registration dialog exposes the supported account choices

The Register mode of the shared account dialog SHALL contain a persistently labelled email field, a Create account submit action, and an action that switches the same dialog to Login mode. Google, Apple, Discord, and Steam SHALL each be a normal full-document provider link labelled `Sign up with <provider>` only when its provider configuration reports it available. Unavailable providers and Facebook SHALL be omitted. An `or` separator and provider group SHALL appear only when at least one provider link is available. Choosing Steam SHALL start provider-only Steam authentication and MUST NOT alter or prefill the direct-email form.

#### Scenario: Guest reviews registration choices with Apple available

- **WHEN** Register mode opens while Apple is available
- **THEN** the guest can create an account with email or start Apple registration
- **AND** available Discord, Google, and Steam links remain independently derived
- **AND** unavailable providers and Facebook are omitted

#### Scenario: Guest reviews registration choices with Discord available

- **WHEN** Register mode opens while Discord is available
- **THEN** the guest can create an account with email or start Discord registration
- **AND** available Apple, Google, and Steam links remain independently derived

#### Scenario: Guest reviews registration choices with Steam available

- **WHEN** Register mode opens while the expected community Steam strategy and API key are configured
- **THEN** the guest can start Steam through a full-document `Sign up with Steam` link
- **AND** the direct-email registration form remains unchanged and independent
- **AND** available Apple, Discord, and Google links remain independently derived
- **AND** no email or SteamID is passed in the provider link

#### Scenario: Steam is unavailable

- **WHEN** Register mode opens while Steam is unavailable
- **THEN** Steam is not rendered
- **AND** direct-email registration and independently available providers remain usable
- **AND** the provider separator and group are omitted when every provider is unavailable

#### Scenario: Guest switches to Login

- **WHEN** the guest activates the existing-user action
- **THEN** the same dialog switches to Login mode without navigation
