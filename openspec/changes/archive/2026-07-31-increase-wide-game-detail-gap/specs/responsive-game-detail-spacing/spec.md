## ADDED Requirements

### Requirement: Game detail panel gap responds to layout mode
The game detail parent layout SHALL use a larger gap for its wide split composition while preserving the compact gap for its stacked composition.

#### Scenario: Wide panels use increased separation
- **WHEN** the activation and description panels render above the existing `48rem` breakpoint
- **THEN** their horizontal gap is `1.25rem`
- **AND** the gap is 25% larger than the `1rem` stacked gap

#### Scenario: Stacked panels retain compact separation
- **WHEN** the activation and description panels stack at or below the existing `48rem` breakpoint
- **THEN** their vertical gap remains `1rem`
