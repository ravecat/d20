## MODIFIED Requirements

### Requirement: Account Settings uses a route-like catalog label

The Storybook catalog SHALL display the Account Settings component group as `/settings` under the existing `Pages` hierarchy while preserving the established Account Settings story IDs and scenarios.

#### Scenario: Browse Account Settings by its route-like label

- **WHEN** a contributor expands `Pages` in the Storybook sidebar
- **THEN** the Account Settings component group is labelled `/settings` with an ASCII slash
- **AND** Established Account, Provider Only Account, and No Available Providers remain its child stories
- **AND** their story IDs retain the `pages-settings` component prefix

### Requirement: Home page is inspectable in isolation

The Storybook catalog SHALL expose the production home page through a typed deterministic story displayed as `/` under the existing `Pages` hierarchy. The story MUST render without Phoenix or remote asset availability and SHALL represent the released, in-development, and planned catalog stages.

#### Scenario: Inspect the home-page catalog

- **WHEN** a contributor expands `Pages` and opens the `/` story group
- **THEN** the group label uses the ASCII slash
- **AND** the production `HomePage` renders with deterministic game catalog entries
- **AND** released, in-development, and planned entries are visible
- **AND** the story retains the `home--catalog` ID
- **AND** the story does not require a live backend or remote image response
