# mix-dependency-security Specification

## Purpose

Define how D20 keeps its committed Mix dependency graph free of known Hex security advisories while preserving declared package and application boundaries.

## Requirements

### Requirement: Resolved Mix dependencies pass the Hex security audit

The project SHALL commit a Mix lockfile whose resolved Hex packages have no active security advisories or retirements reported by the configured Hex client at validation time.

#### Scenario: Audit the refreshed dependency graph

- **WHEN** the project's dependencies are resolved from the committed `mix.lock`
- **THEN** `mix hex.audit` exits successfully
- **AND** the audit reports no retired or security-advisory packages

### Requirement: Security updates preserve declared dependency boundaries

The project SHALL resolve security updates within the existing direct dependency requirements unless no advisory-free compatible graph exists.

#### Scenario: Refresh all compatible Mix dependencies

- **WHEN** the dependency graph is refreshed to remove current audit findings
- **THEN** all Mix dependencies are updated to compatible versions permitted by `mix.exs`
- **AND** the frontend Bun dependency graph remains unchanged

### Requirement: Updated dependencies remain compatible with the repository

The project MUST validate application and tooling compatibility after refreshing the Mix dependency graph.

#### Scenario: Validate the updated graph

- **WHEN** the refreshed lockfile passes the Hex security audit
- **THEN** dependency-managed usage rules are synchronized from the locked packages
- **AND** the repository-wide `just check` workflow passes
