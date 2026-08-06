## ADDED Requirements

### Requirement: App owns global shell UI

The App layer SHALL own UI components used exclusively to compose the global Inertia application layout, and the Shared layer MUST NOT expose those application-shell-specific components as reusable infrastructure.

#### Scenario: Global layout composes shell UI

- **WHEN** the application layout renders its persistent header and footer
- **THEN** it imports both components from the App UI boundary

#### Scenario: Shared component API is inspected

- **WHEN** the Shared component segment public API is evaluated
- **THEN** it does not export the global application header or footer

#### Scenario: Shell UI ownership changes

- **WHEN** the global header and footer move from transitional Shared ownership to the App layer
- **THEN** their props, markup, styles, accessible names, authentication behavior, navigation, and rendered behavior remain unchanged
