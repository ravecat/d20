## MODIFIED Requirements

### Requirement: Playable runtime and public contract are integrated together
The system SHALL expose the existing `next-station-london` registry entry as an in-progress preview only when engine, projection, permissions, contract, and integration coverage are present.

#### Scenario: Registry entry is a development preview
- **WHEN** the implementation is complete
- **THEN** slug `next-station-london` retains engine `D20.NextStationLondon.Game` and BGG id `353545` without a per-entry iframe sandbox value
- **AND** its module descriptor retains the existing effective iframe sandbox values from shared `D20Web.Module` configuration
- **AND** its status is `in_progress` and the catalog presents it as `Soon`
- **AND** session launch is available outside production and unavailable in production through the shared in-progress launch gate

#### Scenario: Public contract is requested
- **WHEN** a developer requests the Next Station: London contract
- **THEN** `priv/specs/next-station-london.yaml` is served and indexed
- **AND** it documents creation attrs, commands, replies, stable errors, permissions, projections, automatic reveals, and hidden future cards
