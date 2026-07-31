## MODIFIED Requirements

### Requirement: Game details use compact vertical flow
The game detail page SHALL remove page-only vertical filler and redundant nested panel insets at supported viewport sizes. The preview SHALL begin at the main content boundary, the activation panel SHALL size to its rendered metadata, setup controls, action, and feedback, and the parent layout SHALL own spacing between activation and description.

#### Scenario: Page begins with the preview
- **WHEN** a player opens a game detail page at any supported viewport width
- **THEN** the game detail shell adds no block-start padding before the preview
- **AND** the preview begins at the main content boundary below the standard shell header

#### Scenario: Narrow activation sizes to content
- **WHEN** the activation and description panels stack in one column
- **THEN** the activation panel does not retain the wide-layout minimum block size
- **AND** its block end follows its final rendered child without additional panel padding
- **AND** the description follows after the existing parent layout gap

#### Scenario: Activation content becomes taller
- **WHEN** additional setup controls, joined players, processing feedback, or errors increase the activation content height
- **THEN** the activation panel expands with that content
- **AND** controls and feedback remain visible without overlap or clipping
- **AND** their spacing remains owned by the existing internal flex and grid gaps

#### Scenario: Wide activation sizes to content
- **WHEN** the activation and description panels use the split layout
- **THEN** the activation does not retain a viewport-derived minimum block size
- **AND** its block end follows its final rendered child without additional panel padding

#### Scenario: Panel content uses parent-owned spacing
- **WHEN** activation and description content renders at a narrow or wide viewport
- **THEN** neither panel adds an internal content inset
- **AND** the parent layout gap remains the spacing between the panels
- **AND** the shell remains the owner of responsive page-edge insets
