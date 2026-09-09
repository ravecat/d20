## RENAMED Requirements

- FROM: `### Requirement: Wide game detail composition preserves independent description overflow`
- TO: `### Requirement: Game descriptions size to content in every layout`

## MODIFIED Requirements

### Requirement: Game descriptions size to content in every layout
The game detail page SHALL size the description panel to its rendered content at every supported viewport width, without a fixed or viewport-derived height limit, independent vertical scrolling, or reserved panel scrollbar gutter. The page SHALL retain the existing split placement above `48rem` and stacked placement at and below `48rem`.

#### Scenario: Wide page retains split placement
- **WHEN** a player opens a game detail page above the existing `48rem` breakpoint
- **THEN** the activation and description render in the existing two-column layout
- **AND** a long description expands the document vertically
- **AND** the activation panel retains its natural content height

#### Scenario: Long description scrolls with the document at every width
- **WHEN** a description extends beyond the viewport at a wide or stacked layout width
- **THEN** scrolling over the description moves the document
- **AND** the description panel does not scroll independently or clip its text
- **AND** the full description and following page footer can be reached through document scrolling

#### Scenario: Short description stays compact
- **WHEN** the game metadata contains a short description
- **THEN** the description panel ends after its rendered content
- **AND** it adds no artificial vertical filler or panel scrollbar gutter

#### Scenario: Missing description preserves its fallback
- **WHEN** the game metadata has no description
- **THEN** the existing `Description not listed.` fallback remains visible
- **AND** the description panel sizes to that fallback without an artificial height or independent scroll area
