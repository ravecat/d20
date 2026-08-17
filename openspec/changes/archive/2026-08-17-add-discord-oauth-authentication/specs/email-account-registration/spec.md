## MODIFIED Requirements

### Requirement: Registration dialog exposes the supported account choices

The Register mode of the shared account dialog SHALL contain a persistently labelled email field, a Create account submit action, and an action that switches the same dialog to Login mode. Google, Apple, and Discord SHALL each be a normal full-document registration link only when their shared provider availability reports true. Unavailable providers and Facebook SHALL be omitted. An `or` separator and the provider group SHALL be present only when at least one provider link is available. Separators and the Register/Login mode switch SHALL use compact vertical spacing rather than reserving a separate large margin.

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
