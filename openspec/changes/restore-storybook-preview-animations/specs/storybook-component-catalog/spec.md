## REMOVED Requirements

### Requirement: Storybook preview suppresses production motion

**Reason**: Global preview suppression prevents contributors from inspecting production CSS motion in component and page stories.

**Migration**: Use production motion in interactive previews and the standard Storybook, Vitest, and Playwright pipeline for automated screenshots. The former guarantee of avoiding Storybook's animation completion fallback is withdrawn.

## ADDED Requirements

### Requirement: Storybook preserves interactive motion and stabilizes automated screenshots

The Storybook catalog SHALL preserve production CSS animations, transitions, and scrolling behavior during interactive browsing, subject to the application's reduced-motion rules. Shared preview configuration and story interactions MUST NOT disable or cancel document-wide motion solely to stabilize screenshots. Automated visual tests SHALL use the existing Storybook, Vitest, and Playwright animation handling to capture stable story-defined states, retaining font readiness and the existing theme and viewport matrix.

#### Scenario: Browse component and page stories

- **WHEN** a contributor opens and interacts with a component or page story
- **THEN** its production CSS motion remains available
- **AND** completing a Workspace story's interactions does not cancel document-wide animations

#### Scenario: Switch the preview theme

- **WHEN** a contributor changes the light or dark theme through the Storybook toolbar
- **THEN** the selected theme is applied through the existing theme decorator
- **AND** production motion remains enabled subject to application reduced-motion behavior
- **AND** contributor guidance records any installed Storybook animation-completion waiting limitation without promising immediate completion

#### Scenario: Run Storybook visual tests

- **WHEN** the existing visual projects capture a story after its state setup and interactions
- **THEN** the standard Storybook and screenshot-provider animation handling stabilizes the capture
- **AND** fonts are ready before the existing screenshot assertion runs
- **AND** both themes and desktop, tablet, and mobile viewports retain visual coverage
- **AND** any changed reference images are reviewed before acceptance

#### Scenario: Render the production application

- **WHEN** the regular application asset entry renders outside Storybook
- **THEN** production motion and reduced-motion behavior remain governed by unchanged application CSS and existing dedicated browser tests
