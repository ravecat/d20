## ADDED Requirements

### Requirement: Game pages use a bounded application shell
The Inertia game application SHALL render one header, one main content region, and one footer in a viewport-bounded shell, and SHALL keep only the main region vertically scrollable.

#### Scenario: Content exceeds the available viewport
- **WHEN** an Inertia game page is taller than the space between the header and footer
- **THEN** the main region scrolls while the header and footer remain visible
- **AND** document scrolling remains at the viewport origin
- **AND** the main region is registered as an Inertia scroll region

### Requirement: The sticky brand compacts with content scrolling
The shell SHALL keep the header at the top of the viewport. In browsers with complete named scroll-driven animation support, the shell SHALL use the main content scroll timeline to compact both the D20 mark and its visible label over the first 24 pixels without JavaScript scroll state. In browsers without complete support and for users who prefer reduced motion, the shell SHALL retain the expanded header as a functional fallback.

#### Scenario: Supporting browser scrolls down through game content
- **WHEN** the main content scroll position progresses from zero to 24 pixels in a browser with complete named scroll-driven animation support
- **THEN** the header remains at the top of the viewport
- **AND** the header presentation progresses from its default dimensions to its compact dimensions
- **AND** no JavaScript scroll state or handler is required

#### Scenario: User returns to the top
- **WHEN** the main content scroll position returns to zero
- **THEN** the D20 mark and visible label return to their default dimensions

#### Scenario: Browser lacks complete scroll timeline support
- **WHEN** the application runs in a browser without complete support for named scroll timelines and animation ranges
- **THEN** the header remains expanded
- **AND** navigation and main content scrolling remain usable

#### Scenario: User prefers reduced motion
- **WHEN** the user requests reduced motion
- **THEN** the header remains expanded instead of resizing continuously with scrolling

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
