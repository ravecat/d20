## ADDED Requirements

### Requirement: Complete page stories reuse the application shell
The Storybook catalog SHALL render each story that represents a complete routed application page inside the production application layout rather than duplicating or omitting its shared chrome.

#### Scenario: Home index renders as a complete page
- **WHEN** a contributor opens the `home--index` story
- **THEN** Storybook shows the production header, Home catalog content, and production footer in one page canvas

#### Scenario: Another routed page renders in the same shell
- **WHEN** a contributor opens any full-page story marked for application layout
- **THEN** Storybook composes that page through the same production layout component used by Inertia

#### Scenario: Home authentication entry renders through the shell
- **WHEN** a contributor opens a Home story for sign-in or sign-up
- **THEN** the story opens the authentication dialog through the production Header inside the complete Home page canvas

#### Scenario: Authentication states covered by Home are not duplicated
- **WHEN** the complete Home stories cover initial sign-in, initial sign-up, Magic Link Sent, email-backed reauthentication, and registration email completion
- **THEN** the catalog does not expose detached Login Methods, Registration Methods, Magic Link Sent, Reauthentication, Provider Only Reauthentication, or Confirmation Email Sent stories
- **AND** no standalone authentication-dialog group remains

#### Scenario: Home shows the Magic Link Sent outcome
- **WHEN** a contributor opens `home--sign-in-sent-magic-link`
- **THEN** the story opens the sign-in dialog through the production Header
- **AND** applies the deterministic magic-link success transition without submitting to a live backend
- **AND** shows the sent confirmation inside the complete Home page canvas

#### Scenario: Home shows email-backed reauthentication
- **WHEN** a contributor opens `home--confirmation-with-magic-link`
- **THEN** the complete Home page receives authenticated context with the production reauthentication prompt
- **AND** the Header opens the `Confirm it is you` dialog with its locked email and Magic Link option
- **AND** the story does not require a live backend

#### Scenario: Home shows registration email completion
- **WHEN** a contributor opens `home--sign-up-with-email`
- **THEN** the story opens registration through the production Header
- **AND** applies the deterministic registration success transition without submitting to a live backend
- **AND** shows the confirmation email outcome inside the complete Home page canvas

### Requirement: Complete page stories use production route labels
The Storybook catalog SHALL display each complete routed page story group under `Pages` using its production route path while preserving stable Storybook IDs.

#### Scenario: Registration Completion uses its route label
- **WHEN** a contributor expands `Pages` in the Storybook sidebar
- **THEN** Registration Completion is displayed as `/users/register/complete` with ASCII route separators
- **AND** its story IDs retain the `pages-sign-up-registration-completion` component prefix

### Requirement: Tall authentication dialogs use the modal layer as their scroll boundary
The authentication dialog SHALL grow with its content without making an inner panel independently scrollable.

#### Scenario: Authentication content exceeds the available viewport height
- **WHEN** a sign-in or sign-up dialog is taller than the viewport
- **THEN** the shaded modal layer scrolls the complete dialog surface while the title, controls, and remaining content move together and remain reachable

#### Scenario: Authentication dialog is open over a complete page
- **WHEN** the modal layer scrolls an authentication dialog opened from Home
- **THEN** the underlying page remains visually stationary and interaction-inert while the complete dialog surface moves vertically

### Requirement: Page-story shell has deterministic shared context
The Storybook page shell SHALL provide the deterministic Inertia page context required by the production layout without replacing each story's page-specific component arguments.

#### Scenario: Anonymous shell context is available
- **WHEN** Storybook renders a page story without a live Phoenix request
- **THEN** the shared header, footer, authentication, and workspace boundaries receive stable anonymous page context and render without a context error

#### Scenario: Magic-link route states receive matching context
- **WHEN** a contributor opens Confirmation or Reauthentication under the `/users/log-in/:token` page story
- **THEN** the layout receives the concrete tokenized URL and the authentication state matching the selected route scenario

### Requirement: Non-page stories remain isolated
The Storybook catalog SHALL apply the application layout only to complete routed page stories.

#### Scenario: Shared component remains unwrapped
- **WHEN** a contributor opens a shared component or widget story
- **THEN** Storybook renders that example with its existing presentation and without the application header or footer
