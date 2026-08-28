## ADDED Requirements

### Requirement: Root scrollbar colors follow the active application theme

The global stylesheet SHALL derive the root scrollbar colors from the active daisyUI theme tokens so the scrollbar thumb and track match the selected light or dark theme in every rendering context.

#### Scenario: Dark theme renders inside an embedding surface

- **WHEN** the dark theme is active through automatic `prefers-color-scheme` selection or an explicit `data-theme` override
- **AND** the page renders inside an embedding surface with a light background such as the Storybook preview iframe
- **THEN** the root scrollbar track uses the active theme `--color-base-100` background instead of a transparent track
- **AND** no embedding-surface color is visible through the scrollbar track
- **AND** the scrollbar thumb keeps a contrasting theme-derived color

#### Scenario: Light theme renders inside an embedding surface

- **WHEN** the light theme is active through automatic `prefers-color-scheme` selection or an explicit `data-theme` override
- **AND** the page renders inside an embedding surface with a dark background
- **THEN** the root scrollbar track uses the active theme `--color-base-100` background
- **AND** the scrollbar thumb keeps a contrasting theme-derived color

#### Scenario: Theme selection switches automatically

- **WHEN** the system color scheme changes between light and dark while the automatic daisyUI selection applies
- **THEN** the root scrollbar colors follow the active theme tokens without page reload or JavaScript

### Requirement: Scrollbar theming introduces no context detection

The scrollbar theming SHALL NOT depend on user-agent inspection, browser detection, JavaScript, or environment-specific branching.

#### Scenario: Implementation is inspected

- **WHEN** the scrollbar theming declarations are inspected
- **THEN** they are pure CSS theme-token declarations on the root element
- **AND** no user-agent string, browser identifier, matchMedia query, or script participates in scrollbar coloring

#### Scenario: Forced-colors accessibility mode applies

- **WHEN** the browser applies `forced-colors` accessibility mode
- **THEN** the browser may override author scrollbar colors
- **AND** the global stylesheet introduces no rules that defeat that override
