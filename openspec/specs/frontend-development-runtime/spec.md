# frontend-development-runtime Specification

## Purpose

Define predictable Vite dependency discovery for the shipped frontend while keeping package-owned Svelte implementation paths behind their supported entry points.

## Requirements

### Requirement: Automatic frontend dependency discovery

The frontend development server SHALL automatically discover dependencies imported by the shipped application entry point and SHALL complete a cold dependency scan without unresolved shipped imports. Application code SHALL consume exported package entry points that keep published Svelte component implementation paths behind the package boundary when such entries are available.

#### Scenario: Cold scan reaches the SJSF radio widget

- **WHEN** the frontend development server performs a forced cold dependency scan for the application entry point
- **THEN** it completes dependency discovery without reporting a package-subpath resolution error for the SJSF radio widget

#### Scenario: Launch form selects the registered radio widget

- **WHEN** a game launch field has a direct enum schema
- **THEN** the shared form resolver obtains the registered radio widget through the SJSF basic theme without importing its `.svelte` implementation subpath directly

#### Scenario: Linked frontend dependencies are discovered

- **WHEN** the application entry point imports its linked Phoenix frontend dependencies
- **THEN** Vite discovers and resolves them without an application-maintained dependency include list

#### Scenario: Production bundling remains independent

- **WHEN** the frontend production bundle is built
- **THEN** the development dependency discovery configuration does not change SJSF launch-form rendering or production module resolution
