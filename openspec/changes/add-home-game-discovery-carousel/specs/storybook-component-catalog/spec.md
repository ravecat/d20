## MODIFIED Requirements

### Requirement: Home page is inspectable in isolation

The Storybook catalog SHALL expose the production home page through a typed deterministic story displayed as `/` under the existing `Pages` hierarchy. The story MUST render without Phoenix or remote asset availability and SHALL represent the released and in-development catalog stages.

#### Scenario: Inspect the home-page catalog

- **WHEN** a contributor expands `Pages` and opens the `/` story group
- **THEN** the group label uses the ASCII slash
- **AND** the production `HomePage` renders with deterministic game catalog entries
- **AND** released and in-development entries are visible
- **AND** the story retains the `home--index` ID
- **AND** the story does not require a live backend or remote image response
