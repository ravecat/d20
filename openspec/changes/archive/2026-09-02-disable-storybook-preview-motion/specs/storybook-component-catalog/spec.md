## ADDED Requirements

### Requirement: Storybook preview suppresses production motion
The Storybook preview SHALL disable CSS animations and transitions and SHALL use immediate scrolling for all rendered story elements and pseudo-elements. This no-motion policy MUST remain outside the production application stylesheet and MUST NOT replace dedicated browser coverage of production animation behavior.

#### Scenario: Switch the preview theme
- **WHEN** a contributor changes the light or dark theme through the Storybook toolbar
- **THEN** the preview applies the selected theme without waiting for a production animation timeline or Storybook's five-second animation fallback
- **AND** the story completes with animations and transitions disabled

#### Scenario: Run Storybook visual tests
- **WHEN** the Storybook visual projects render and capture a story
- **THEN** animations, transitions, and smooth scrolling do not introduce timing-dependent intermediate states into the snapshot

#### Scenario: Render the production application
- **WHEN** the regular application asset entry renders outside Storybook
- **THEN** the Storybook no-motion stylesheet is absent
- **AND** production motion and reduced-motion behavior remain governed by application CSS and dedicated browser tests
