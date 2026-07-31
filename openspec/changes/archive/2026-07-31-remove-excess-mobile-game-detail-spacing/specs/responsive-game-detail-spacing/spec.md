## ADDED Requirements

### Requirement: Game details use compact vertical flow
The game detail page SHALL remove page-only vertical filler at supported viewport sizes. The preview SHALL begin at the main content boundary, and the activation panel SHALL size to its rendered metadata, setup controls, action, and feedback.

#### Scenario: Page begins with the preview
- **WHEN** a player opens a game detail page at any supported viewport width
- **THEN** the game detail shell adds no block-start padding before the preview
- **AND** the preview begins at the main content boundary below the standard shell header

#### Scenario: Narrow activation sizes to content
- **WHEN** the activation and description panels stack in one column
- **THEN** the activation panel does not retain the wide-layout minimum block size
- **AND** its block end follows its final rendered child with only the panel padding
- **AND** the description follows after the existing layout gap

#### Scenario: Activation content becomes taller
- **WHEN** additional setup controls, joined players, processing feedback, or errors increase the activation content height
- **THEN** the activation panel expands with that content
- **AND** controls and feedback remain visible without overlap or clipping

#### Scenario: Wide activation sizes to content
- **WHEN** the activation and description panels use the split layout
- **THEN** the activation does not retain a viewport-derived minimum block size
- **AND** its block end follows its final rendered child with only the panel padding

### Requirement: Wide game detail composition preserves independent description overflow
The game detail page MUST preserve its split-panel placement and internally scrollable description on viewports above the stacked-layout breakpoint.

#### Scenario: Wide page retains split placement
- **WHEN** a player opens a game detail page above the existing `48rem` breakpoint
- **THEN** the activation and description render in the existing two-column layout
- **AND** a long description remains internally scrollable

### Requirement: Game detail page insets remain compact and symmetric
The game detail page SHALL retain responsive inline padding and block-end edge protection without reserving additional scrollbar space on only one physical edge.

#### Scenario: Main content scrolls on a wide viewport
- **WHEN** game detail content overflows the main scroll container vertically
- **THEN** the scroll container does not reserve a stable gutter on only its inline end
- **AND** the game detail shell uses equal physical inline insets
- **AND** the shell retains its block-end padding

### Requirement: Responsive spacing does not change activation behavior
The responsive spacing change SHALL preserve the existing game detail DOM order, semantic regions, setup fields, and session creation behavior.

#### Scenario: Player creates a session on a narrow viewport
- **WHEN** a player selects supported setup values and activates `Play`
- **THEN** the form submits the same fields to the same game session creation route
- **AND** the activation region and description remain exposed with their existing accessible names
