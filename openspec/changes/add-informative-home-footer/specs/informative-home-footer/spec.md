## ADDED Requirements

### Requirement: Home provides informative grouped navigation

The Home page SHALL render one App-owned footer after its main content for anonymous and authenticated visitors. It SHALL use a full-width neutral surface, a centered bounded inner container, a short introductory line with a D20 brand link to `/`, an Explore/Help directory, and a separate legal strip with fine separators. Explore SHALL link About D20 to `/about`, Games to `/games`, and For developers to `/developers`. Help SHALL link How to play to `/help`, FAQ to `/help#faq`, and Contact / Support to `/contact`. The legal strip SHALL display the current year with D20 attribution, Privacy at `/privacy`, and Terms at `/terms`. Account/data deletion SHALL be an answer within FAQ at `/help#delete-account`, not a separate footer item or page.

#### Scenario: Guest reaches the end of Home

- **WHEN** an anonymous visitor reaches the footer on `/`
- **THEN** the introduction, two navigation group headings, and legal strip are visible
- **AND** every visible required link has the specified accessible name and destination, including those revealed through mobile group controls
- **AND** navigating to a public information page does not open a sign-in gate

#### Scenario: Authenticated or empty Home

- **WHEN** Home renders for a signed-in user or with no visible game sections
- **THEN** the same required footer content remains reachable
- **AND** it does not depend on catalog membership or change the delivered game data

### Requirement: Footer presentation preserves the application shell

The informative presentation SHALL be selected explicitly by Home independently of narrow/wide width. Other existing App-layout pages SHALL use a compact footer containing For developers, Privacy, and Terms as always-visible links that can wrap. The footer SHALL remain owned by App UI and SHALL preserve existing header, main, Workspace, width, and safe-area contracts.

#### Scenario: Navigation from Home to a game detail page

- **WHEN** a visitor leaves Home for a page using the wide App layout
- **THEN** that page shows compact footer navigation within its existing wide insets
- **AND** it does not inherit Home's expanded link groups merely because of its width

### Requirement: Responsive footer remains accessible

The footer SHALL use semantic landmarks, labelled navigation groups, meaningful anchors, visible keyboard focus, and a logical reading order. Normal text/link contrast SHALL meet 4.5:1 in supported themes. Link targets SHALL meet 24 CSS-pixel minimum sizing or equivalent spacing, and mobile disclosure triggers SHALL have at least 44px row height. All content SHALL reflow at 320 CSS pixels and 200 percent zoom without horizontal page overflow, clipping, or overlap with Workspace controls. The legal strip SHALL remain visible outside the disclosure groups.

#### Scenario: Small-screen keyboard navigation

- **WHEN** a visitor tabs through Home at a 320 CSS-pixel viewport
- **THEN** group controls and visible links are reachable in group order
- **AND** Enter or Space on a mobile group control reveals its links
- **AND** Privacy and Terms remain individually labelled and available without expanding a group
- **AND** footer content neither clips nor creates horizontal page scrolling

#### Scenario: Theme and text scaling

- **WHEN** the visitor uses a supported light or dark theme at 200 percent zoom
- **THEN** text, focus indicators, group labels, and link targets remain readable and usable
- **AND** the footer retains its shell alignment and safe-area protection

### Requirement: Directory columns become mobile disclosure rows

At viewport widths greater than 48rem, the informative footer SHALL show Explore and Help as equal columns with all links visible and static headings. At widths of 48rem or less, the headings SHALL become stacked full-width disclosure controls with separators and expansion indicators. After enhancement, a mobile initial render SHALL start closed unless doing so would hide a focused link. Groups SHALL open independently. Controls SHALL report accurate `aria-expanded` and `aria-controls`. Collapsed links MUST NOT remain in the tab order or accessibility tree. Before enhancement or if it fails, all links SHALL remain readable and usable. The same link nodes SHALL serve both layouts.

#### Scenario: User opens both mobile groups

- **WHEN** the user opens Explore and then Help at 390 CSS pixels
- **THEN** both groups remain open with accurate accessible states
- **AND** closing either group leaves the other unchanged
- **AND** the closed group's links leave keyboard and screen-reader navigation

#### Scenario: Footer enhancement is unavailable

- **WHEN** the footer markup renders without a working disclosure script
- **THEN** all groups are visible as usable lists
- **AND** no required link depends on a nonfunctional disclosure control

### Requirement: Breakpoint changes preserve usable navigation

Crossing above 48rem SHALL show every link and reset mobile disclosure state. Crossing back to 48rem or below SHALL start with groups closed except the group containing the focused link, which SHALL stay open. Resizing or changing orientation within the same mode SHALL preserve state and focus. A focused link SHALL retain focus across modes; when a focused mobile trigger disappears on desktop, focus SHALL move to its visible group heading. Resizing MUST NOT remount Home, duplicate links, navigate, reload, or force-scroll to the top. Disclosure reveal/indicator animation SHALL last at most 200ms and SHALL be disabled under reduced motion; breakpoint changes SHALL NOT animate layout geometry.

#### Scenario: Mobile to desktop and back without footer focus

- **WHEN** a user opens Help on mobile, focuses outside the footer, widens above 48rem, and then narrows to 48rem or less
- **THEN** all links are visible on desktop
- **AND** both groups are closed on returning to mobile
- **AND** no disclosure state is stored for a later visit

#### Scenario: Focused desktop link survives narrowing

- **WHEN** FAQ is focused on desktop and the viewport narrows to mobile
- **THEN** Help remains open and FAQ retains visible focus
- **AND** Explore can start closed without hiding the focused element

#### Scenario: Focused mobile trigger survives widening

- **WHEN** the Help disclosure trigger is focused and the viewport widens to desktop
- **THEN** focus moves to the visible Help heading
- **AND** all links remain keyboard reachable with no invisible focused control
- **AND** if the viewport narrows again while that heading is focused, focus moves to the visible Help trigger

#### Scenario: Orientation stays within mobile or motion is reduced

- **WHEN** an open mobile group is resized without crossing 48rem
- **THEN** its open state and current focus are preserved
- **AND** toggling it with reduced motion active changes state immediately

### Requirement: Footer links are truthful and passive

Every required destination SHALL provide useful content before footer delivery is accepted. The footer MUST NOT ship placeholder hrefs, invented support addresses, unavailable product features, or mandatory-link omissions used to conceal missing dependencies. It MUST NOT introduce tracking, remote data fetching, or third-party social scripts. Cookie preferences and social destinations SHALL be omitted unless the corresponding real mechanism or verified destination exists in approved scope.

#### Scenario: A mandatory page is not ready

- **WHEN** `/privacy`, `/terms`, or the deletion answer at `/help#delete-account` is missing, gated, or contains unfinished content
- **THEN** footer delivery acceptance remains incomplete
- **AND** a placeholder or hidden mandatory link does not satisfy the requirement

#### Scenario: Footer renders without social integration

- **WHEN** Home and its footer render
- **THEN** the footer starts no external request or social SDK
- **AND** no Facebook social link is required solely because Facebook Login exists

### Requirement: Meta publication uses verified document URLs

Footer acceptance SHALL require recorded anonymous production HTTPS checks for `/privacy`, `/terms`, and `/help#delete-account` and evidence from #247 that deletion instructions describe a working process. The Help response SHALL contain the deletion answer and its id in initial HTML, and direct fragment navigation SHALL reveal that answer. Privacy SHALL link directly to it. The Meta handoff SHALL distinguish an instructions URL from a callback URL and retain configuration, review, and publication ownership under #249, #251, and #252. Footer completion MUST NOT be presented as Meta approval or publication.

#### Scenario: Handoff to Meta metadata configuration

- **WHEN** all required public documents and the footer are accepted
- **THEN** their exact `https://d20.ravecat.io` URLs and dated verification evidence are supplied to #249
- **AND** `https://d20.ravecat.io/help#delete-account` is identified as the instructions URL
- **AND** the statuses of Meta review and publication remain governed by their own evidence
