## ADDED Requirements

### Requirement: Game pages use one global document scroller
The Inertia game application SHALL render one fixed header, one main content region, and one footer in a document-scrolling shell with a viewport-height minimum and an expanded-header reserve. The document root SHALL be the only page-level vertical scrolling element; the main region MUST NOT create a nested page scrollport or register as an Inertia scroll region.

#### Scenario: Content exceeds the available viewport
- **WHEN** an Inertia game page is taller than the viewport
- **THEN** the document root scrolls through the header, main region, and footer
- **AND** the main region does not scroll independently
- **AND** the fixed header remains at the top of the viewport

#### Scenario: Content is shorter than the available viewport
- **WHEN** an Inertia game page is shorter than the viewport
- **THEN** the shell still fills the viewport
- **AND** the footer rests at the viewport end after the main region

### Requirement: The fixed brand compacts with global document scrolling
The shell SHALL keep the fixed header at the top of the viewport, SHALL reserve its expanded responsive height before main content, and SHALL give the document matching block-start scroll padding. In browsers with complete scroll-driven animation support, the shell SHALL use the root document scroll timeline to compact both the D20 mark and its visible label over the first 24 pixels without JavaScript scroll state. The reserve MUST prevent content jumps and initial interactive-content overlap and MUST scroll away without leaving a permanent gap after compaction. The scroll padding MUST keep root-aligned fragment, focus, and programmatic scroll targets below the fixed header, including when the expanded fallback is active. In browsers without complete support and for users who prefer reduced motion, the shell SHALL retain the expanded header as a functional fallback.

#### Scenario: Supporting browser scrolls down through game content
- **WHEN** the document scroll position progresses from zero to 24 pixels in a browser with complete scroll-driven animation support
- **THEN** the fixed header remains at the top of the viewport
- **AND** the header presentation progresses from its default dimensions to its compact dimensions
- **AND** no JavaScript scroll state or handler is required

#### Scenario: User returns to the top
- **WHEN** the document scroll position returns to zero
- **THEN** the D20 mark and visible label return to their default dimensions

#### Scenario: Browser aligns content to the root scrollport
- **WHEN** fragment navigation, focus scrolling, or a programmatic scroll aligns a main-content target to block start
- **THEN** responsive document scroll padding keeps the target below the fixed header

#### Scenario: Browser lacks complete scroll timeline support
- **WHEN** the application runs in a browser without complete support for root scroll timelines and animation ranges
- **THEN** the header remains expanded
- **AND** navigation and document scrolling remain usable

#### Scenario: User prefers reduced motion
- **WHEN** the user requests reduced motion
- **THEN** the header remains expanded instead of resizing continuously with scrolling

### Requirement: Shell chrome is borderless
The header and footer SHALL render without visible surrounding borders, divider lines, or edge shadows in both default and compact states.

#### Scenario: Shell renders at the top of a page
- **WHEN** the document scroll position is zero
- **THEN** the computed header and footer edge border widths are zero
- **AND** neither surface draws an edge shadow

#### Scenario: Header enters compact state
- **WHEN** the document scroll position exceeds 24 pixels
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
