## ADDED Requirements

### Requirement: Home page is inspectable in isolation
The Storybook catalog SHALL expose the production home page through a typed deterministic story whose title is the route-like division slash `∕`. The story MUST render without Phoenix or remote asset availability and SHALL represent the released, in-development, and planned catalog stages.

#### Scenario: Inspect the home-page catalog
- **WHEN** a contributor opens the `∕` story group
- **THEN** the production `HomePage` renders with deterministic game catalog entries
- **AND** released, in-development, and planned entries are visible
- **AND** the story does not require a live backend or remote image response
