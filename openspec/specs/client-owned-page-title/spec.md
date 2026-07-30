# client-owned-page-title Specification

## Purpose
TBD - created by archiving change set-page-title-in-svelte. Update Purpose after archive.
## Requirements
### Requirement: Developers page owns its browser title
The developers Svelte page SHALL declare `For developers` as its browser title, and the Phoenix developers action SHALL render the page without assigning duplicate page-title metadata.

#### Scenario: Client renders the developers page
- **WHEN** the developers Svelte page is rendered
- **THEN** the browser document title is `For developers`

#### Scenario: Server renders the developers Inertia entry point
- **WHEN** a client requests `/developers`
- **THEN** the Phoenix action renders the `developers` Inertia component without assigning a page-specific title
