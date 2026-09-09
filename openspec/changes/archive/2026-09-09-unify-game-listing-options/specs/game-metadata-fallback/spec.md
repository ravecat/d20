## MODIFIED Requirements

### Requirement: Catalog remains complete during metadata degradation
Local listings SHALL retain every selected valid row within their database result limit when BGG enrichment is wholly or partially unavailable, preserving BGG identity, local fields, order, and launch policy. Provider Hot or detail-operation failures SHALL propagate to the controller, which SHALL log the failure and render empty Games while preserving Playable. Successful detail operations with missing items or invalid individual metadata SHALL retain selected identities and order with empty metadata where needed. The provider SHALL NOT replace a failed detail operation with an ok result or emit a separate detail-fallback warning. Local listing fallback retains its existing scope warning. Successful metadata SHALL remain available when the operation succeeds but omits or invalidates individual items. No fallback SHALL expose credentials, invent local records, or alter the canonical-link rule within each owning section.

#### Scenario: Home loads without BGG credentials
- **WHEN** home loads outside production without usable BGG credentials
- **THEN** home succeeds with locally selected Playable entries and empty fallback metadata
- **AND** Games is empty because no provider selection can be discovered

#### Scenario: Hot discovery fails
- **WHEN** Hot returns an HTTP, transport, configuration, or parse error
- **THEN** provider listing returns that error and home renders empty Games with a discovery warning
- **AND** local Playable membership is preserved

#### Scenario: Hot succeeds but detail batch fails
- **WHEN** Hot selects valid IDs and any detail batch fails
- **THEN** provider listing propagates the detail-operation error
- **AND** the controller logs the failure and renders empty Games while local Playable membership is preserved

#### Scenario: Successful details omit a selected identity
- **WHEN** detail loading succeeds but omits one selected ID
- **THEN** present metadata is retained and only the missing identity receives empty fallback metadata
- **AND** membership and selected order remain unchanged

#### Scenario: Metadata attrs are invalid
- **WHEN** one selected attrs map fails Metadata validation
- **THEN** that entry retains its BGG ID and optional local fields with empty metadata

#### Scenario: Fallback playable card renders
- **WHEN** a playable entry has empty metadata
- **THEN** it retains its local detail link, generic accessible name, and launchable membership

#### Scenario: Fallback provider card renders
- **WHEN** a Games entry has empty metadata
- **THEN** it retains the internal detail link built from its context-supplied route slug, including when that slug is the decimal BGG ID
- **AND** it remains keyboard accessible with fallback preview without a required display name

#### Scenario: A fallback entry is repeated visually
- **WHEN** a card has loop or decorative copies
- **THEN** exactly one canonical link is accessible in its owning section
- **AND** the same game may independently have one canonical link in the other section


### Requirement: Provider-only details require a successful provider record
The context SHALL distinguish local metadata enrichment from provider-only detail existence. A persisted local detail SHALL retain existing Metadata.empty fallback and visibility/Session rules when provider enrichment fails. A provider-only detail SHALL require fetch_game to return one parsed provider game with a positive identity and Metadata construction to succeed; operation errors or missing identities SHALL remain errors with the existing controller 404 mapping. Successfully omitted optional display fields SHALL use normal detail presentation fallbacks without a required name. No failure SHALL create a persisted or synthetic Game.

#### Scenario: Local metadata request fails
- **WHEN** a visible persisted local detail cannot load BGG metadata
- **THEN** its existing detail still renders with empty Metadata and unchanged launch policy

#### Scenario: Numeric provider game is absent
- **WHEN** a provider-only numeric lookup returns game_not_found
- **THEN** the detail response is 404 without a synthesized successful page

#### Scenario: Numeric provider operation fails
- **WHEN** credentials, HTTP, transport, parsing, or Metadata validation prevents provider-only detail resolution
- **THEN** the context preserves the error and the controller maps it to 404
- **AND** no credential is exposed and no local record is written

#### Scenario: Successful provider metadata is sparse
- **WHEN** the requested provider identity exists but optional display values are absent
- **THEN** the detail renders with existing optional-field presentation fallbacks
- **AND** the route slug remains the decimal BGG identity
