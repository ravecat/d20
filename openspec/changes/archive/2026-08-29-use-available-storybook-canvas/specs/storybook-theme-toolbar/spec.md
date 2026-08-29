## MODIFIED Requirements

### Requirement: The preview theme is deterministic by default

The Storybook preview SHALL select the light theme by default instead of deriving the theme from the browser's `prefers-color-scheme`.

#### Scenario: Storybook opens under a forced-dark browser

- **WHEN** Storybook opens in a browser whose appearance setting forces `prefers-color-scheme: dark`
- **AND** the contributor has not selected a theme in the toolbar
- **THEN** the preview renders the light theme
- **AND** a story can still pin a specific theme through the `theme` global

#### Scenario: Existing Storybook configuration is preserved

- **WHEN** the theme toolbar integration is active
- **THEN** the existing viewport options, explicit visual-test viewport globals, control matchers, story discovery, and registered addons behave as before
- **AND** the interactive catalog retains the available-canvas viewport default independently of the theme selection
