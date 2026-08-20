## MODIFIED Requirements

### Requirement: Account Settings presents only available providers

The sudo-protected Account Settings page SHALL receive one ordered `providers` collection rather than provider-specific top-level page props. Each supported provider entry MUST contain an explicit stable identifier, visible name, runtime availability, durable linked state, and a server-generated link URL. The page SHALL render an external sign-in provider only when that entry reports `available` as `true`. It MUST omit unavailable providers regardless of durable linked state and MUST omit the complete Sign-in methods section when no provider is available. Provider ordering and visibility MUST NOT change provider configuration, identity ownership, or linking authorization.

#### Scenario: Account Settings receives the provider collection

- **WHEN** an authenticated player opens Account Settings
- **THEN** the page receives one ordered collection containing every supported Account Settings provider
- **AND** each entry contains its explicit stable identifier, visible name, runtime availability, durable linked state, and server-generated link URL
- **AND** no provider-specific top-level page prop is present
- **AND** no provider credential is exposed

#### Scenario: Mixed provider availability

- **WHEN** an authenticated player opens Account Settings with one or more available providers and one or more unavailable providers
- **THEN** the page renders every available provider in the server-provided order
- **AND** no unavailable provider name, state, action, or placeholder is rendered

#### Scenario: Every provider is unavailable

- **WHEN** an authenticated player opens Account Settings while every external provider is unavailable
- **THEN** the Sign-in methods section is omitted
- **AND** the username, email, and password settings remain available
