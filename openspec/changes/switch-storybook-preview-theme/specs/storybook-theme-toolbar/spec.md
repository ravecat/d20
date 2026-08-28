## ADDED Requirements

### Requirement: The Storybook toolbar switches the preview theme

The Storybook configuration SHALL expose the application's supported daisyUI themes through the Storybook toolbar so contributors can switch the preview between themes without changing the browser's appearance setting.

#### Scenario: Contributor switches the preview theme

- **WHEN** a contributor selects the `dark` theme from the Storybook toolbar while the browser reports `prefers-color-scheme: dark` or `light`
- **THEN** the preview root carries `data-theme="dark"`
- **AND** the resolved theme CSS variables, `color-scheme`, root background, and root scrollbar colors follow the dark theme
- **AND** the browser's own `prefers-color-scheme` media state is unchanged

#### Scenario: Contributor switches back to the light theme

- **WHEN** a contributor selects the `light` theme from the Storybook toolbar
- **THEN** the preview root carries `data-theme="light"`
- **AND** the resolved theme CSS variables, `color-scheme`, root background, and root scrollbar colors follow the light theme
- **AND** the browser's own `prefers-color-scheme` media state is unchanged

### Requirement: The preview theme is deterministic by default

The Storybook preview SHALL select the light theme by default instead of deriving the theme from the browser's `prefers-color-scheme`.

#### Scenario: Storybook opens under a forced-dark browser

- **WHEN** Storybook opens in a browser whose appearance setting forces `prefers-color-scheme: dark`
- **AND** the contributor has not selected a theme in the toolbar
- **THEN** the preview renders the light theme
- **AND** a story can still pin a specific theme through the `theme` global

#### Scenario: Existing Storybook configuration is preserved

- **WHEN** the theme toolbar integration is active
- **THEN** the existing viewport options, viewport initial globals, control matchers, story discovery, and registered addons behave as before
