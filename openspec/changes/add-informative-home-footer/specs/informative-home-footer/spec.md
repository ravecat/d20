## ADDED Requirements

### Requirement: Home provides informative grouped navigation

The Home page and every existing App-layout page SHALL render the same App-owned footer once after main content for anonymous and authenticated visitors. The footer SHALL NOT include a repeated D20 brand/tagline introduction. It SHALL match Home's full-width page surface (white in light mode, the existing page color in dark mode), with a centered bounded inner container, a compact Explore/Help directory using the spacing in `layout.md`, and a separate legal strip with fine separators. Explore SHALL link About to `/about`, For Publishers and Rightholders to `/rights-holders`, and For developers to `/developers`. Help SHALL link How to play to `/help`, FAQ to `/help#faq`, and Contact / Support to `/contact`. The legal strip SHALL display the current year with D20 attribution, Privacy at `/privacy`, and Terms at `/terms`. Account/data deletion SHALL be an answer within FAQ at `/help#delete-account`, not a separate footer item or page.

#### Scenario: Guest reaches the end of Home

- **WHEN** an anonymous visitor reaches the footer on `/`
- **THEN** the two navigation group headings and legal strip are visible
- **AND** every visible required link has the specified accessible name and destination, including those revealed through mobile group controls
- **AND** navigating to a public information page does not open a sign-in gate

#### Scenario: Authenticated or empty Home

- **WHEN** Home renders for a signed-in user or with no visible game sections
- **THEN** the same required footer content remains reachable
- **AND** it does not depend on catalog membership or change the delivered game data

### Requirement: Footer presentation preserves the application shell

The footer SHALL have one content composition with no compact/informative mode or page-level footer selection. The existing narrow/wide Layout setting SHALL affect shell alignment only. The footer SHALL remain owned by App UI and SHALL preserve existing header, main, Workspace, width, and safe-area contracts.

Directory markup, styling, and responsive state SHALL remain together in the shared footer component, without a separate single-use group component. Viewport media queries SHALL select desktop/mobile presentation without a JavaScript mobile-mode class or duplicate breakpoint expression. Consolidation SHALL preserve the native keyboard disclosure and CSS visibility behavior below.

#### Scenario: Navigation from Home to a game detail page

- **WHEN** a visitor leaves Home for a page using the wide App layout
- **THEN** that page shows the same Explore/Help groups and legal strip within its existing wide insets
- **AND** no page setting changes the footer's content

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

### Requirement: Footer has concrete viewport acceptance

The implementation SHALL use the shared content and geometry matrix in [the layout reference](../../layout.md). Home and other applicable pages SHALL render the same footer within their existing narrow or wide shell. Both themes SHALL preserve the same content and structure. Review SHALL cover the existing 1280x720 desktop, 1024x640 tablet, and 320x900 mobile Storybook presets, plus targeted 390x844, 767/768/769px boundary, 768x1024 portrait, 1440x900 large-screen, and 844x390 short-landscape checks. Content SHALL wrap without fixed-height clipping. Privacy and Terms SHALL remain visible outside disclosures.

#### Scenario: Tablet uses width rather than device label

- **WHEN** the informative footer renders at the existing 1024x640 tablet preset
- **THEN** its two directory columns are visible
- **AND** at 768x1024 it uses the mobile disclosure presentation
- **AND** the narrow inner box remains bounded rather than stretching to fill the viewport

#### Scenario: Shared footer and theme coverage

- **WHEN** the footer is reviewed at narrow and wide shell widths in light and dark themes
- **THEN** Explore, Help, copyright, Privacy, and Terms retain the same content and order
- **AND** mobile groups can be opened without page-level overflow
- **AND** wide versus narrow changes geometry without changing link content

#### Scenario: Short landscape viewport

- **WHEN** the footer renders at 844x390 CSS pixels
- **THEN** the desktop directory remains accessible by normal page scrolling
- **AND** neither footer nor surrounding content is clipped to viewport height

#### Scenario: Footer review in Storybook

- **WHEN** a reviewer opens the component catalog
- **THEN** only Default and Mobile expanded footer stories appear under `Widgets/Footer`; existing toolbar controls select themes and viewports
- **AND** public and authenticated Home previews include exactly one shared footer through the real App layout without a separate footer-focused Home story

### Requirement: Directory columns become native mobile disclosure rows

Above 48rem the footer SHALL show equal desktop columns with static headings and all links. At 48rem and below it SHALL show independent native `details`/`summary` disclosures, initially closed, with expansion indicators and 44px controls. Native keyboard activation and expanded semantics SHALL work without client JavaScript when markup is present. Explore and Help SHALL be written as explicit inline navigation blocks, with matching links in desktop and mobile representations and Inertia actions applied directly to the applicable anchors without a group array or navigation flag; only one representation SHALL be visible and accessible at each width. Collapsed and CSS-hidden links MUST NOT remain in keyboard or accessibility navigation. Privacy and Terms SHALL remain visible.

#### Scenario: User opens both mobile groups

- **WHEN** the user activates Explore and then Help at 390 CSS pixels
- **THEN** both native disclosures remain open
- **AND** closing either group leaves the other unchanged
- **AND** the closed group's links leave keyboard and screen-reader navigation

#### Scenario: Footer markup is available without client JavaScript

- **WHEN** the browser renders the footer markup without executing its client code
- **THEN** desktop lists are readable and mobile groups can be opened with native controls
- **AND** no disclosure action requires a script handler

### Requirement: Responsive presentation needs no scripted synchronization

CSS SHALL select desktop/mobile presentation. The footer SHALL NOT observe sizes, read computed layout, run JavaScript media queries, synchronize reactive disclosure state, or transfer focus on resize. Mobile `open` state SHALL survive width changes while the component remains mounted, with no persistence across visits. Automatic focus transfer and focused-link preservation across hidden representations are intentionally outside this simplified behavior. Disclosure and breakpoint changes SHALL be immediate without animation.

#### Scenario: Mobile to desktop and back

- **WHEN** the user opens Help on mobile, widens above 48rem, and returns to mobile
- **THEN** desktop exposes every destination exactly once in accessible navigation
- **AND** Help remains open on returning to mobile while Explore retains its own state
- **AND** the footer does not programmatically move focus

#### Scenario: Orientation stays within mobile

- **WHEN** an open mobile group is resized without crossing 48rem
- **THEN** its native open state and current focus are preserved
- **AND** keyboard toggling continues to work

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

### Requirement: Legal row responds to available space

Copyright, Privacy, and Terms SHALL share inherited font family, size, weight, and line height. The legal strip SHALL retain a baseline-aligned wrapping row at every viewport; the 48rem directory breakpoint MUST NOT force it into a column. At 446 CSS pixels with default text size, copyright and legal links SHALL fit on one line. At insufficient widths or increased text size, the same content SHALL wrap without clipping or hiding links.

#### Scenario: Mobile width has space for the legal row

- **WHEN** the footer renders at 446 CSS pixels with default text size
- **THEN** copyright and Privacy/Terms share one row with matching typography
- **AND** Explore and Help retain independent mobile disclosure behavior

#### Scenario: Content needs additional lines

- **WHEN** available inline space cannot fit the copyright and legal links
- **THEN** they wrap in document order and remain visible without horizontal overflow

### Requirement: Publisher destination is ready before replacement

The `For Publishers and Rightholders` destination SHALL explain both proposing a game for adaptation or placement and raising concerns about rights in existing content. Its useful content and destination address MUST be supplied before replacing the runtime Games link. The approved `rights@d20.ravecat.io` address SHALL be prepared in the page while mailbox provisioning continues; verified receipt and monitoring remain a publication gate, not a prerequisite to this authorized local implementation. No separate game catalog SHALL be introduced by this change.

#### Scenario: Contact and page are not ready

- **WHEN** the rights-holder page has useful content and the user-approved address, but mailbox provisioning is incomplete
- **THEN** the page and footer link can be prepared and tested locally
- **AND** mail delivery is not reported as verified or the broader publication gate as complete
