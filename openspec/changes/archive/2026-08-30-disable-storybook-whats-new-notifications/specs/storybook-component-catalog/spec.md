## ADDED Requirements

### Requirement: Catalog release notifications remain disabled

The interactive Storybook catalog SHALL disable Storybook's built-in What's New notifications through the maintained project configuration. This suppression MUST NOT depend on browser-local dismissal state and MUST NOT change application, story, or addon notifications.

#### Scenario: Reload the development catalog

- **WHEN** a contributor starts or reloads the interactive Storybook catalog
- **THEN** Storybook does not present its built-in What's New notification
- **AND** existing stories, addons, and manager layout remain available
