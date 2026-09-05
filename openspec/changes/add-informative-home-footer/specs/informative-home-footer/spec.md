## ADDED Requirements

### Requirement: Home provides informative grouped navigation

The Home page SHALL render one App-owned footer after its main content for anonymous and authenticated visitors. It SHALL include a D20 brand link to `/`, a short factual product description, Explore and Help groups, and a separate legal strip. Explore SHALL link About D20 to `/about`, Games to `/games`, and For developers to `/developers`. Help SHALL link How to play to `/help`, FAQ to `/help#faq`, and Contact / Support to `/contact`. The legal strip SHALL link Privacy to `/privacy`, Terms to `/terms`, and Data deletion to `/data-deletion`, and display the current year with D20 attribution.

#### Scenario: Guest reaches the end of Home

- **WHEN** an anonymous visitor reaches the footer on `/`
- **THEN** the description, two navigation groups, and legal strip are visible
- **AND** every required link has the specified accessible name and destination
- **AND** navigating to a public information page does not open a sign-in gate

#### Scenario: Authenticated or empty Home

- **WHEN** Home renders for a signed-in user or with no visible game sections
- **THEN** the same required footer content remains reachable
- **AND** it does not depend on catalog membership or change the delivered game data

### Requirement: Footer presentation preserves the application shell

The informative presentation SHALL be selected explicitly by Home independently of narrow/wide width. Other existing App-layout pages SHALL use a compact footer containing For developers, Privacy, Terms, and Data deletion. The footer SHALL remain owned by App UI and SHALL preserve existing header, main, Workspace, width, and safe-area contracts.

#### Scenario: Navigation from Home to a game detail page

- **WHEN** a visitor leaves Home for a page using the wide App layout
- **THEN** that page shows compact footer navigation within its existing wide insets
- **AND** it does not inherit Home's expanded link groups merely because of its width

### Requirement: Responsive footer remains accessible

The footer SHALL use semantic landmarks, labelled navigation groups, meaningful anchors, visible keyboard focus, and a logical reading order. Groups SHALL stack on small screens without hiding required links in accordions. Normal text/link contrast SHALL meet 4.5:1 in supported themes. Targets SHALL meet 24 CSS-pixel minimum sizing or equivalent spacing. All content SHALL reflow at 320 CSS pixels and 200 percent zoom without horizontal page overflow, clipping, or overlap with Workspace controls. Any inherited transition SHALL respect reduced motion.

#### Scenario: Small-screen keyboard navigation

- **WHEN** a visitor tabs through Home at a 320 CSS-pixel viewport
- **THEN** every footer link is visible when focused and reachable in group order
- **AND** Privacy, Terms, and Data deletion remain individually labelled and available
- **AND** footer content neither clips nor creates horizontal page scrolling

#### Scenario: Theme and text scaling

- **WHEN** the visitor uses a supported light or dark theme at 200 percent zoom
- **THEN** text, focus indicators, group labels, and link targets remain readable and usable
- **AND** the footer retains its shell alignment and safe-area protection

### Requirement: Footer links are truthful and passive

Every required destination SHALL provide useful content before footer delivery is accepted. The footer MUST NOT ship placeholder hrefs, invented support addresses, unavailable product features, or mandatory-link omissions used to conceal missing dependencies. It MUST NOT introduce tracking, remote data fetching, or third-party social scripts. Cookie preferences and social destinations SHALL be omitted unless the corresponding real mechanism or verified destination exists in approved scope.

#### Scenario: A mandatory page is not ready

- **WHEN** `/privacy`, `/terms`, or `/data-deletion` is missing, gated, or contains unfinished content
- **THEN** footer delivery acceptance remains incomplete
- **AND** a placeholder or hidden mandatory link does not satisfy the requirement

#### Scenario: Footer renders without social integration

- **WHEN** Home and its footer render
- **THEN** the footer starts no external request or social SDK
- **AND** no Facebook social link is required solely because Facebook Login exists

### Requirement: Meta publication uses verified document URLs

Footer acceptance SHALL require recorded anonymous production HTTPS checks for `/privacy`, `/terms`, and `/data-deletion` and evidence from #247 that deletion instructions describe a working process. The Meta handoff SHALL distinguish an instructions URL from a callback URL and retain configuration, review, and publication ownership under #249, #251, and #252. Footer completion MUST NOT be presented as Meta approval or publication.

#### Scenario: Handoff to Meta metadata configuration

- **WHEN** all required public documents and the footer are accepted
- **THEN** their exact `https://d20.ravecat.io` URLs and dated verification evidence are supplied to #249
- **AND** `/data-deletion` is identified as the instructions URL
- **AND** the statuses of Meta review and publication remain governed by their own evidence
