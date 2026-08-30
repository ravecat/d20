## ADDED Requirements

### Requirement: Authentication-grouped pages retain matching application-shell context

Every public or authenticated complete page metadata group SHALL continue to render through the production application layout with deterministic Inertia context matching its catalog access boundary. Public groups MUST provide anonymous authentication context, and authenticated groups MUST provide authenticated context. Splitting a production route across both access groups SHALL reuse the same production page component and concrete route URL without copying page markup.

#### Scenario: Render a public page group

- **WHEN** Storybook renders any group under `Pages/Public`
- **THEN** the production application shell receives `auth.authenticated` as `false`
- **AND** the page renders at its deterministic production-shaped route URL

#### Scenario: Render an authenticated page group

- **WHEN** Storybook renders any group under `Pages/Authenticated`
- **THEN** the production application shell receives `auth.authenticated` as `true`
- **AND** the page renders at its deterministic production-shaped route URL

#### Scenario: Render a route represented in both groups

- **WHEN** Home or `/users/log-in/:token` is represented under both access groups
- **THEN** each group imports the same production page component for that route
- **AND** each group uses a distinct explicit Storybook metadata ID
- **AND** no live Phoenix or Inertia boundary is required
