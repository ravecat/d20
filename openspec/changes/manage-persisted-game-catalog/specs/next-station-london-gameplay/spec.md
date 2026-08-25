## MODIFIED Requirements

### Requirement: Playable runtime and public contract are integrated together
The system SHALL expose persisted Next Station: London under its generated `game` TypeID as an in-development preview only when engine, projection, permissions, contract, and integration coverage are present.

#### Scenario: Persisted game is a development preview
- **WHEN** the implementation is complete
- **THEN** the persisted row retains its generated `game` TypeID, BGG id `353545`, and engine `D20.NextStationLondon.Game` loaded from permanent engine integer `3`
- **AND** no stored slug or per-game iframe sandbox value exists
- **AND** its module descriptor retains the shared `D20Web.Module` sandbox values
- **AND** stage is `in_development` and the catalog presents `In development`
- **AND** enabled is true
- **AND** Session launch is available outside production and unavailable in production through the shared in-development gate

#### Scenario: Public contract is requested
- **WHEN** a developer requests the Next Station: London contract by its static specification identifier
- **THEN** `priv/specs/next-station-london.yaml` is served and indexed
- **AND** the document identifier is not used as operational game identity
- **AND** it documents creation attrs, commands, replies, stable errors, permissions, projections, automatic reveals, and hidden future cards
