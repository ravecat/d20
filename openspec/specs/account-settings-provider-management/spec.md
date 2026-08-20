# Account Settings Provider Management Specification

## Purpose

Define how Account Settings presents available external sign-in providers and lays out independent account controls across supported viewport sizes.

## Requirements

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

### Requirement: Available providers expose one compact state

Each available provider item SHALL contain two adjacent blocks: a neutral non-interactive identity block with the provider's recognizable icon and visible name, and a separate same-height state control. The outer provider item MUST NOT present a clickable surface or pointer affordance. An available provider without a linked identity SHALL expose a normal full-document `Link` anchor as a visually distinct button control whose accessible name identifies the provider. An available provider with a linked identity SHALL replace the anchor with a muted non-interactive `Linked` control of the same geometry and MUST NOT show a second link, an unlink action, or a separate `Not linked` status line.

#### Scenario: Available provider can be linked

- **WHEN** an available provider is not linked to the current player
- **THEN** its neutral identity block shows the provider icon and name
- **AND** a separate provider-specific `Link` anchor has a distinct button surface
- **AND** activating the action starts the existing explicit provider-link route through full-document navigation

#### Scenario: Available provider is already linked

- **WHEN** an available provider is linked to the current player
- **THEN** its neutral identity block shows the provider icon and name beside a same-height muted non-interactive `Linked` control
- **AND** no link, unlink action, or `Not linked` status is rendered for that provider

#### Scenario: Provider interaction target remains unambiguous

- **WHEN** linked and unlinked provider items are rendered together
- **THEN** identity blocks and state controls are vertically centered and use equal block sizes
- **AND** only the separate `Link` control exposes link semantics and pointer affordance
- **AND** the outer provider item and neutral identity block are non-interactive

### Requirement: Provider and account settings reflow responsively

Account Settings SHALL preserve one logical document order while using all inline space supplied by its containing application shell for provider items and independent account cards. It MUST NOT impose a page-local maximum width. Where the provider container permits, each provider item SHALL remain at least 13 rem and at most 20 rem wide. Through the existing 34 rem mobile breakpoint, every provider item SHALL start a separate row while retaining the 20 rem maximum. Above that breakpoint, provider items sharing a row SHALL distribute remaining inline space without exceeding that maximum, and the next provider SHALL wrap only when another 13 rem item plus the row gap no longer fits. All wrapped rows SHALL use the same equal-width column tracks so a partial final row aligns with the corresponding columns in the preceding row. A provider item MAY contract below 13 rem only when its container itself is narrower, preventing horizontal overflow. The page SHALL render as a single readable column on supported narrow mobile viewports and SHALL reflow into compact multi-column layouts on wider viewports without clipped content or reduced keyboard operability. Independent account cards that share a grid row SHALL stretch to the same block size without fixed card heights, while cards in the single-column mobile layout SHALL retain content-driven row sizes.

#### Scenario: Narrow mobile settings

- **WHEN** Account Settings is rendered at a supported narrow mobile viewport
- **THEN** provider items and account cards remain in one readable column
- **AND** every provider item starts its own row and does not exceed 20 rem
- **AND** provider actions and form controls remain visible, keyboard operable, and free of horizontal overflow

#### Scenario: Wide desktop settings

- **WHEN** Account Settings is rendered at a wide desktop viewport
- **THEN** the page fills the inline space supplied by the application shell and available providers and independent account cards use multiple columns to reduce unnecessary page height
- **AND** independent account cards that share a row have equal block sizes
- **AND** headings, provider identity, state, and form labels remain unambiguous

#### Scenario: Additional provider reaches the minimum row width

- **WHEN** another available provider would make any provider item narrower than 13 rem after accounting for row gaps
- **THEN** the additional provider starts the next row
- **AND** every provider item shares available row space without growing beyond 20 rem

#### Scenario: Final provider wraps by itself

- **WHEN** the last available provider starts a new row below multiple provider items
- **THEN** it uses the same width and inline alignment as the first provider column above it
- **AND** it does not independently grow to the 20 rem maximum

### Requirement: Provider rows and settings controls use one compact height

Account Settings SHALL use one compact block size for provider identity blocks, provider state controls, text inputs, and form submit buttons. This shared size SHALL remain keyboard operable and SHALL NOT reduce visible focus indication or accessible naming.

#### Scenario: Settings controls are visually consistent

- **WHEN** Account Settings renders provider link actions and editable account forms
- **THEN** provider identity blocks, provider state controls, text inputs, and submit buttons have the same compact block size
- **AND** each control retains its existing accessible name, focus indication, and behavior
