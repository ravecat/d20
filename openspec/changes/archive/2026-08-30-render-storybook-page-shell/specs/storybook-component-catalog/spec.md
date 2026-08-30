## MODIFIED Requirements

### Requirement: Authentication workflows are inspectable in isolation

The Storybook catalog SHALL organize production authentication surfaces under complete Home stories and route-labelled `Sign In` and `Sign Up` pages. It SHALL expose the production AuthDialog, Account Settings, Registration Completion, and Auth Confirmation components through typed deterministic stories. The stories SHALL render without Phoenix or a live Inertia submission boundary and MUST prevent form interaction from contacting an application server.

#### Scenario: Inspect authentication dialog states

- **WHEN** a contributor browses the Home, `Sign In`, and `Sign Up` story groups
- **THEN** Home Sign In and Home Sign Up cover the initial AuthDialog states through the production Header
- **AND** Home Sign In Sent Magic Link covers the Magic Link request completion state in the complete page context
- **AND** Home Confirmation With Magic Link covers email-backed sudo reauthentication through the production Header prompt
- **AND** Home Sign Up With Email covers sign-up email request completion through the production Header
- **AND** no standalone Sign In or Sign Up authentication-dialog group remains
- **AND** each state uses deterministic page and authentication-store state without a live backend

#### Scenario: Inspect Account Settings states

- **WHEN** a contributor opens the Account Settings stories
- **THEN** the production page can be inspected with its required established username
- **AND** provider linked, unlinked, available, and unavailable states are represented by deterministic props

#### Scenario: Inspect registration completion states

- **WHEN** a contributor opens the Registration Completion stories
- **THEN** the production page can be inspected for the distinct Magic Link and Auth Provider completion states
- **AND** the Auth Provider state exposes the production action for choosing another registration method
- **AND** the Auth Provider state represents every provider-backed completion that has the same user-visible behavior
- **AND** no provider credential, callback payload, or live form submission is required

#### Scenario: Inspect Magic Link login confirmation states

- **WHEN** a contributor opens the Magic Link Login Confirmation stories under `Sign In`
- **THEN** the production page can be inspected for signed-out login and sudo reauthentication
- **AND** the remember-me choice follows the production page state

#### Scenario: Interact with a catalog form

- **WHEN** a contributor submits a form from any authentication page story
- **THEN** Storybook prevents a live Inertia request
- **AND** the rendered production page remains available for inspection

#### Scenario: Inspect an authentication story with addon tooling

- **WHEN** a contributor opens an authentication page story in the supported desktop layout
- **THEN** the addon panel is visible to the right of the story canvas
- **AND** installed Controls, Actions, Interactions, and other addon panels remain available without per-story layout configuration
- **AND** narrow viewports retain Storybook's responsive manager layout
