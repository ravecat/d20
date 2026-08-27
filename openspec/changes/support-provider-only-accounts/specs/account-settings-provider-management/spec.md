## MODIFIED Requirements

### Requirement: Account Settings presents only available providers
The sudo-protected Account Settings page SHALL receive one ordered `providers` collection rather than provider-specific top-level page props. Each supported provider entry MUST contain an explicit stable identifier, visible name, runtime availability, durable linked state, and a server-generated link URL. The page SHALL render an external sign-in provider only when that entry reports `available` as `true`. It MUST omit unavailable providers regardless of durable linked state and MUST omit the complete Sign-in methods section when no provider is available. Provider ordering and visibility MUST NOT change provider configuration, identity ownership, linking authorization, or whether account email is present. Username, email-add-or-change, and password settings SHALL remain independent of provider availability.

#### Scenario: Account Settings receives the provider collection
- **WHEN** an authenticated player opens Account Settings
- **THEN** the page receives one ordered collection containing every supported Account Settings provider
- **AND** each entry contains its explicit stable identifier, visible name, runtime availability, durable linked state, and server-generated link URL
- **AND** no provider-specific top-level page prop is present
- **AND** no provider credential or provider UID is exposed

#### Scenario: Mixed provider availability
- **WHEN** an authenticated player opens Account Settings with one or more available providers and one or more unavailable providers
- **THEN** the page renders every available provider in the server-provided order
- **AND** no unavailable provider name, state, action, or placeholder is rendered

#### Scenario: Every provider is unavailable
- **WHEN** an authenticated player opens Account Settings while every external provider is unavailable
- **THEN** the Sign-in methods section is omitted
- **AND** the username, email-add-or-change, and password settings remain available
- **AND** a provider-only player is informed when no currently usable provider action is available

## ADDED Requirements

### Requirement: Account Settings distinguishes absent and present email
Account Settings SHALL represent email absence as null. A user with null email SHALL receive an `Add email` form and an explanation that email Magic Link recovery and email notifications remain unavailable until verification. A user with non-null email SHALL receive the existing `Change email` form. Both forms SHALL use the same candidate-address verification flow, and the password form SHALL remain independent. The page MUST NOT render an empty string, provider UID, username, or fabricated address as the current email.

#### Scenario: Provider-only user opens Account Settings
- **WHEN** a sudo-valid user with null email opens Account Settings
- **THEN** the page displays the immutable username and an `Add email` form
- **AND** it explains the unavailable email-dependent methods
- **AND** the independent password and available provider controls remain operable

#### Scenario: User with email opens Account Settings
- **WHEN** a sudo-valid user with a non-null email opens Account Settings
- **THEN** the page displays that email and the existing `Change email` form
- **AND** existing password and provider controls remain operable
