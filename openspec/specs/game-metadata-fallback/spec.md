# game-metadata-fallback Specification

## Purpose
TBD - created by archiving change make-bgg-metadata-optional. Update Purpose after archive.
## Requirements
### Requirement: BGG metadata is optional enrichment
The system SHALL use successfully resolved BGG metadata as a registered game's display metadata. Failure to resolve BGG metadata MUST NOT change whether the registered game exists or whether its configured session launch is available.

#### Scenario: BGG metadata is available
- **WHEN** BGG returns valid metadata for a registered game
- **THEN** the system returns the BGG display fields for that game
- **AND** the registered game's slug, availability, engine, and session behavior remain locally defined

#### Scenario: BGG metadata request fails
- **WHEN** BGG returns an HTTP error, times out, or cannot be reached
- **THEN** the system returns the registered game with empty fallback metadata
- **AND** its optional display name and other provider-dependent fields remain empty

#### Scenario: BGG metadata cannot be parsed
- **WHEN** BGG returns a response that cannot be parsed as game metadata
- **THEN** the system returns the registered game with empty fallback metadata
- **AND** the provider failure does not become a game-not-found result

#### Scenario: BGG omits one game from a batch
- **WHEN** a batch metadata response contains valid metadata for some registered games but omits another registered game
- **THEN** the system preserves the resolved metadata for games present in the response
- **AND** returns empty fallback metadata for each omitted registered game

### Requirement: Missing BGG credentials are supported outside production
The application SHALL start and serve registered games outside production when `BGG_API_KEY` is absent or empty. Production startup MUST fail when usable BGG credentials are absent. The BGG source adapter SHALL return an explicit configuration error without sending an external request when usable credentials are absent at runtime.

#### Scenario: Development application starts without a BGG key
- **WHEN** the application starts outside production without `BGG_API_KEY`
- **THEN** startup succeeds
- **AND** BGG-backed enrichment operates in degraded mode

#### Scenario: Production application starts without a BGG key
- **WHEN** the application starts in production without a non-empty `BGG_API_KEY`
- **THEN** startup fails with a configuration error

#### Scenario: Metadata is requested without a BGG key outside production
- **WHEN** metadata enrichment is requested outside production while `BGG_API_KEY` is absent or empty
- **THEN** no request is sent to BGG
- **AND** registered games are resolved with empty fallback metadata

### Requirement: Catalog remains complete during metadata degradation
The home catalog SHALL include every valid configured registry entry in its existing availability order when BGG enrichment is wholly or partially unavailable. Each entry SHALL preserve the existing Inertia prop shape and SHALL use existing empty-field preview behavior for provider-dependent fields.

#### Scenario: Catalog loads without BGG credentials
- **WHEN** a user requests the home page without configured BGG credentials
- **THEN** the response is successful
- **AND** every configured game appears with its slug and availability
- **AND** each fallback `GameMetadata` object has an empty display name and empty provider-dependent fields

#### Scenario: Catalog loads during a BGG outage
- **WHEN** the catalog metadata request fails upstream
- **THEN** the response is successful
- **AND** the catalog is not replaced with an empty list

#### Scenario: Fallback catalog card has no provider metadata
- **WHEN** a catalog entry has only empty fallback metadata
- **THEN** its card remains linked and keyboard accessible through the generic accessible label
- **AND** the existing non-image preview state is rendered
- **AND** no display name is required

### Requirement: Registered detail pages remain available during metadata degradation
The system SHALL render the detail page for every locally registered slug even when BGG enrichment is unavailable. Session creation and existing-session connection SHALL continue to depend on the registry and session runtime, not on external display metadata.

#### Scenario: Active game detail loads without BGG credentials
- **WHEN** a user requests `/games/koala-rescue-club` without configured BGG credentials
- **THEN** the response renders the Koala Rescue Club detail page successfully
- **AND** the page retains its configured session launch controls

#### Scenario: Registered detail loads during an upstream failure
- **WHEN** a user requests a registered game detail page and BGG enrichment fails
- **THEN** the page renders the existing optional-field fallback states without requiring a display name
- **AND** the response is not `404 Not Found`

#### Scenario: Existing session reconnects without BGG metadata
- **WHEN** a user requests a registered game detail page with a valid session while BGG enrichment is unavailable
- **THEN** the page receives the existing session and module connection data
- **AND** the session remains usable

#### Scenario: Unknown slug is requested
- **WHEN** a user requests `/games/:slug` for a slug absent from the local registry
- **THEN** the system returns `404 Not Found`

### Requirement: Metadata degradation is observable without exposing credentials
The system SHALL record metadata enrichment failures with enough provider and reason context for diagnosis. Logs and client props MUST NOT contain the BGG API key or authorization header.

#### Scenario: BGG enrichment fails
- **WHEN** a registered game falls back because BGG enrichment failed
- **THEN** the server records the provider failure reason
- **AND** neither logs nor rendered props expose BGG credentials
