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

### Requirement: Modal authentication suspends background document scrolling
While the native modal authentication dialog is open, the shell SHALL preserve the document's current scroll position but MUST suspend user scrolling and hide the document scrollbar. The full-viewport dialog SHALL remain the only active visible vertical scroll container when its content exceeds the viewport. Closing the dialog SHALL restore the document scrolling element's prior inline overflow state without changing the document scroll position.

#### Scenario: Login opens over an overflowing page
- **WHEN** a user opens the authentication dialog while the document is taller than the viewport
- **THEN** the document scrollbar is no longer visible or user-scrollable
- **AND** the authentication dialog remains vertically scrollable
- **AND** the dialog is the only active visible vertical scroll container

#### Scenario: Login closes over an overflowing page
- **WHEN** the user closes the authentication dialog after opening it over an overflowing page
- **THEN** the document scrolling element restores its prior inline overflow state
- **AND** the document remains at its pre-dialog scroll position

#### Scenario: Login opens over a short page
- **WHEN** a user opens and closes the authentication dialog while the document does not overflow
- **THEN** the same modal scroll-lock lifecycle runs without introducing page overflow or a layout regression

### Requirement: The fixed brand compacts with global document scrolling
The shell SHALL keep the fixed header at the top of the viewport, SHALL reserve its expanded responsive height before main content, and SHALL give the document matching block-start scroll padding. In browsers with complete scroll-driven animation support, the shell SHALL use the root document scroll timeline to compact both the D20 mark and its visible label over the first 24 pixels. A reactive at-top guard SHALL disable compaction when the root scroll offset is zero, including after the timeline becomes inactive; CSS SHALL own interpolation while scrolling. The reserve MUST prevent content jumps and initial interactive-content overlap and MUST scroll away without leaving a permanent gap after compaction. The scroll padding MUST keep root-aligned fragment, focus, and programmatic scroll targets below the fixed header, including when the expanded fallback is active. In browsers without complete support and for users who prefer reduced motion, the shell SHALL retain the expanded header as a functional fallback.

#### Scenario: Supporting browser scrolls down through game content
- **WHEN** the document scroll position progresses from zero to 24 pixels in a browser with complete scroll-driven animation support
- **THEN** the fixed header remains at the top of the viewport
- **AND** the header presentation progresses from its default dimensions to its compact dimensions
- **AND** CSS owns interpolation; the reactive at-top guard only resets the inactive timeline

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
- **THEN** the mark has an inline size of 1.959rem and a block size of 2.25rem

#### Scenario: Default narrow brand renders
- **WHEN** the D20 mark is not compact and the viewport is at most 34rem wide
- **THEN** the mark has an inline size of 1.63275rem and a block size of 1.875rem

#### Scenario: Compact brand renders
- **WHEN** the D20 mark is compact at any supported viewport width
- **THEN** the mark has an inline size of 1.3065rem and a block size of 1.5rem


### Requirement: Header brand and login proportions are reduced consistently
The complete brand and Log in button SHALL render at 75 percent of their previous dimensions, typography and internal spacing in expanded, narrow and compact states using native CSS sizing. The header SHALL use minimum heights of 3.75rem desktop, 3.375rem narrow and 2.3625rem compact, centering its contents without additional block padding. The layout reserve and document block-start scroll padding SHALL match the expanded responsive heights. Authenticated account controls SHALL remain usable within the smaller header. Visible focus indicators, native navigation, authentication behavior and reduced-motion fallback SHALL remain usable.

#### Scenario: Expanded header renders
- **WHEN** the header renders at the top of a desktop or narrow page
- **THEN** the mark and visible label, and the Log in button, have 75 percent of their previous width and height
- **AND** the header height and following content reserve are reduced proportionally, while shared edge alignment and catalog/footer intervals remain stable

#### Scenario: Header compacts while scrolling
- **WHEN** the supporting browser reaches the compact state
- **THEN** the brand and Log in button retain the same 75 percent reduction from the previous compact dimensions
- **AND** the button has a minimum block size of 1.5rem, remains keyboard-operable, and opens the existing authentication dialog


#### Scenario: Compact header has balanced vertical breathing room
- **WHEN** the header reaches its compact state
- **THEN** the unchanged 1.5rem mark and Log in button have equal 0.43125rem top/bottom visual insets, 15 percent larger than the prior 0.375rem insets
- **AND** expanded header reserves and root-aligned content remain unchanged


#### Scenario: Removing overflow restores the expanded header
- **WHEN** closing mobile footer groups or resizing makes the document fit and returns its scroll offset to zero
- **THEN** the header restores its expanded responsive dimensions, matching the unchanged document reserve
- **AND** a previously compact scroll timeline cannot leave a stale smaller header above that reserve
