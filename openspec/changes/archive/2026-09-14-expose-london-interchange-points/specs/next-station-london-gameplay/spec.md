## ADDED Requirements

### Requirement: Score projections include interchange category points
The system SHALL include `interchange_points` in every public player score, mapping categories 2, 3, and 4 to their authoritative point subtotals. Every category SHALL be present, including zero values. The existing `interchange_score` SHALL equal the sum of these subtotals. Player and spectator projections SHALL expose the same score facts without requiring client rule calculations.

#### Scenario: Mixed interchange categories are scored
- **WHEN** a player's network contains interchange stations connecting two, three, or four distinct colored lines
- **THEN** each category point subtotal equals its count multiplied by the existing ruleset value of 2, 5, or 9 respectively
- **AND** aggregate interchange points and the final total retain their existing meaning

#### Scenario: Empty categories remain explicit
- **WHEN** a player has no interchange stations in a category
- **THEN** that category is present with zero points in both the player and spectator public score

#### Scenario: Existing finished session is projected again
- **WHEN** a caller joins an existing finished session
- **THEN** its score projection contains all three interchange category point subtotals derived from existing state without migration
