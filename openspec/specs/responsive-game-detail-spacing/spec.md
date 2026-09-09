# Responsive Game Detail Spacing Specification

## Purpose

Define compact, content-driven game detail geometry across supported viewport sizes while preserving activation behavior and natural description flow through document scrolling.

## Requirements

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

### Requirement: Game detail page insets remain compact and symmetric
The game detail page SHALL use one equal physical inline inset across its app header, main content, and app footer: `1rem` at and below the existing `48rem` breakpoint and `1.5rem` above that breakpoint. It SHALL retain block-end edge protection without reserving additional scrollbar space on only one physical edge.

#### Scenario: Game detail renders on a narrow viewport
- **WHEN** a player opens a game detail page at or below the existing `48rem` breakpoint
- **THEN** the app header, game detail shell, and app footer align to a `1rem` inset on each physical inline edge
- **AND** the preview, activation content, action, and description remain inside those insets
- **AND** the D20 brand, account action, and footer link remain inside those insets

#### Scenario: Game detail renders on a wide viewport
- **WHEN** a player opens a game detail page above the existing `48rem` breakpoint
- **THEN** the app header, game detail shell, and app footer align to a `1.5rem` inset on each physical inline edge
- **AND** the split layout remains inside those insets

#### Scenario: Main content scrolls on a wide viewport
- **WHEN** game detail content overflows the main scroll container vertically
- **THEN** the scroll container does not reserve a stable gutter on only its inline end
- **AND** the app header, game detail shell, and app footer keep equal physical inline insets
- **AND** the shell retains its block-end padding

#### Scenario: Narrow-layout page uses the standard shell
- **WHEN** a page uses the default narrow app-shell variant
- **THEN** its existing `1rem` header and footer insets remain unchanged

### Requirement: Game detail panel gap responds to layout mode
The game detail parent layout SHALL use a larger gap for its wide split composition while preserving the compact gap for its stacked composition.

#### Scenario: Wide panels use increased separation
- **WHEN** the activation and description panels render above the existing `48rem` breakpoint
- **THEN** their horizontal gap is `1.25rem`
- **AND** the gap is 25% larger than the `1rem` stacked gap

#### Scenario: Stacked panels retain compact separation
- **WHEN** the activation and description panels stack at or below the existing `48rem` breakpoint
- **THEN** their vertical gap remains `1rem`

### Requirement: Responsive spacing does not change activation behavior
The responsive spacing change SHALL preserve the existing game detail DOM order, semantic regions, setup fields, and session creation behavior.

#### Scenario: Player creates a session on a narrow viewport
- **WHEN** a player selects supported setup values and activates `Play`
- **THEN** the form submits the same fields to the same game session creation route
- **AND** the activation region and description remain exposed with their existing accessible names
