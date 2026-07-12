## ADDED Requirements

### Requirement: Game pages use a bounded application shell
The Inertia game application SHALL render one header, one main content region, and one footer in a viewport-bounded shell, and SHALL keep only the main region vertically scrollable.

#### Scenario: Content exceeds the available viewport
- **WHEN** an Inertia game page is taller than the space between the header and footer
- **THEN** the main region scrolls while the header and footer remain visible
- **AND** document scrolling remains at the viewport origin
- **AND** the main region is registered as an Inertia scroll region

### Requirement: The sticky brand compacts with content scrolling
The shell SHALL keep the header at the top of the viewport and SHALL compact both the D20 mark and its visible label after the main content scroll position exceeds 24 pixels.

#### Scenario: User scrolls down through game content
- **WHEN** the main content scroll position becomes greater than 24 pixels
- **THEN** the header remains at the top of the viewport
- **AND** the D20 mark and visible label use their compact dimensions

#### Scenario: User returns to the top
- **WHEN** the main content scroll position returns to zero
- **THEN** the D20 mark and visible label return to their default dimensions

### Requirement: Shell chrome is borderless
The header and footer SHALL render without visible surrounding borders, divider lines, or edge shadows in both default and compact states.

#### Scenario: Shell renders at the top of a page
- **WHEN** the main content scroll position is zero
- **THEN** the computed header and footer edge border widths are zero
- **AND** neither surface draws an edge shadow

#### Scenario: Header enters compact state
- **WHEN** the main content scroll position exceeds 24 pixels
- **THEN** the header remains free of divider lines and edge shadows
- **AND** the footer remains free of divider lines and edge shadows

### Requirement: Brand focus has no surrounding boundary
The home brand link SHALL NOT draw a surrounding border or outline in pointer or keyboard states, and SHALL preserve a visible non-color keyboard-focus indicator on its text label.

#### Scenario: Keyboard focus reaches the brand
- **WHEN** the brand link matches `:focus-visible`
- **THEN** no outline or surrounding border is drawn around the D20 mark or complete brand link
- **AND** the visible `D20` label is underlined as the focus indicator

### Requirement: D20 size states are explicit
The D20 component SHALL define literal dimensions for each supported size state without using CSS custom properties for width or height. Color custom properties MAY remain.

#### Scenario: Default desktop brand renders
- **WHEN** the D20 mark is not compact and the viewport is wider than 34rem
- **THEN** the mark has an inline size of 2.612rem and a block size of 3rem

#### Scenario: Default narrow brand renders
- **WHEN** the D20 mark is not compact and the viewport is at most 34rem wide
- **THEN** the mark has an inline size of 2.177rem and a block size of 2.5rem

#### Scenario: Compact brand renders
- **WHEN** the D20 mark is compact at any supported viewport width
- **THEN** the mark has an inline size of 1.742rem and a block size of 2rem
