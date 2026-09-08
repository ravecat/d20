## ADDED Requirements

### Requirement: Deferred Privacy stays out of current navigation

The shared footer SHALL omit Privacy for anonymous and authenticated visitors at every shell width while publication under #248 is deferred. The policy draft SHALL remain an internal versioned artifact. Terms and the Explore/Help groups SHALL retain their existing destinations and navigation behavior. Removing Privacy SHALL NOT mark the policy, its deletion dependencies or the public-launch/Meta gates complete.

#### Scenario: Visitor reaches the footer while Privacy is deferred

- **WHEN** any App-layout page renders during the deferral
- **THEN** the footer contains no Privacy link, including hidden or disabled representations
- **AND** Terms remains available without opening a disclosure
- **AND** keyboard navigation follows guest account actions, when present, then Terms, Explore and Help

#### Scenario: Privacy becomes ready for publication

- **WHEN** #248 has verified accurate public content and its #247/#270 and operator/operational prerequisites
- **THEN** Privacy is restored at `/privacy` as part of that verified publication
- **AND** the current deferral is not treated as a completed policy

### Requirement: Home provides informative grouped navigation

The Home page and every existing App-layout page SHALL render the same App-owned footer once after main content for anonymous and authenticated visitors. The footer SHALL NOT include a repeated D20 brand/tagline introduction. It SHALL match Home's full-width page surface (white in light mode, the existing page color in dark mode), with a centered bounded inner container, a compact Explore/Help directory using the spacing in `layout.md`, and a separate service block with fine separators. Explore SHALL link About to `/about`, For publishers and rightholders to `/rights-holders`, and For developers to `/developers`. Help SHALL link How to play to `/help`, FAQ to `/help#faq`, and Contact / support to `/contact`. The current service block SHALL display lowercase d20 followed by © and the current year and Terms at `/terms`. During the operator-approved Privacy deferral, it MUST NOT render a `/privacy` anchor or placeholder. Privacy SHALL return only with #248's verified policy publication. Account/data deletion SHALL be an answer within FAQ at `/help#delete-account`, not a separate footer item or page.

#### Scenario: Guest reaches the end of Home

- **WHEN** an anonymous visitor reaches the footer on `/`
- **THEN** the two navigation group headings and service block are visible
- **AND** every visible required link has the specified accessible name and destination, without opening a group
- **AND** navigating to a public information page does not open a sign-in gate

#### Scenario: Authenticated or empty Home

- **WHEN** Home renders for a signed-in user or with no visible game sections
- **THEN** the same required footer content remains reachable
- **AND** it does not depend on catalog membership or change the delivered game data

### Requirement: Footer presentation preserves the application shell

The footer SHALL have one content composition with no compact/informative mode or page-level footer selection. The existing narrow/wide Layout setting SHALL affect shell alignment only. The footer SHALL remain owned by App UI and SHALL preserve existing header, main, Workspace, width, and safe-area contracts.

Directory markup, styling, and responsive state SHALL remain together in the shared footer component, without a separate single-use group component. Viewport media queries SHALL select desktop/mobile presentation without a JavaScript mobile-mode class or duplicate breakpoint expression. Consolidation SHALL preserve the always-visible keyboard navigation below.

#### Scenario: Navigation from Home to a game detail page

- **WHEN** a visitor leaves Home for a page using the wide App layout
- **THEN** that page shows the same Explore/Help groups and service block within its existing wide insets
- **AND** no page setting changes the footer's content

### Requirement: Responsive footer remains accessible

The footer SHALL use semantic landmarks, labelled navigation groups, meaningful anchors, visible keyboard focus, and a logical reading order. Normal text/link contrast SHALL meet 4.5:1 in supported themes. Link targets SHALL meet 24 CSS-pixel minimum sizing or equivalent spacing, with no disclosure triggers. All content SHALL reflow at 320 CSS pixels and 200 percent zoom without horizontal page overflow, clipping, or overlap with Workspace controls. The service block SHALL remain visible alongside the navigation groups.

#### Scenario: Small-screen keyboard navigation

- **WHEN** a visitor tabs through Home at a 320 CSS-pixel viewport
- **THEN** Terms and all Explore/Help links are reachable in reading order
- **AND** the Terms link remains individually labelled and available without expanding a group
- **AND** footer content neither clips nor creates horizontal page scrolling

#### Scenario: Theme and text scaling

- **WHEN** the visitor uses a supported light or dark theme at 200 percent zoom
- **THEN** text, focus indicators, group labels, and link targets remain readable and usable
- **AND** the footer retains its shell alignment and safe-area protection

### Requirement: Footer has concrete viewport acceptance

The implementation SHALL use the shared content and geometry matrix in [the layout reference](../../layout.md). Home and other applicable pages SHALL render the same footer within their existing narrow or wide shell. Both themes SHALL preserve the same content and structure. Review SHALL cover the existing 1280x720 desktop, 1024x640 tablet, and 320x900 mobile Storybook presets, plus targeted 390x844, 767/768/769px boundary, 768x1024 portrait, 1440x900 large-screen, and 844x390 short-landscape checks. Content SHALL wrap without fixed-height clipping. Terms SHALL remain visible without interaction.

#### Scenario: Tablet uses width rather than device label

- **WHEN** the informative footer renders at the existing 1024x640 tablet preset
- **THEN** its two directory columns are visible
- **AND** at 768x1024 the service block sits above the two navigation columns
- **AND** the narrow inner box remains bounded rather than stretching to fill the viewport

#### Scenario: Shared footer and theme coverage

- **WHEN** the footer is reviewed at narrow and wide shell widths in light and dark themes
- **THEN** copyright, guest account actions when applicable, Terms, Explore and Help retain their reading order
- **AND** all mobile links remain visible without page-level overflow
- **AND** wide versus narrow changes geometry without changing link content

#### Scenario: Short landscape viewport

- **WHEN** the footer renders at 844x390 CSS pixels
- **THEN** the desktop directory remains accessible by normal page scrolling
- **AND** neither footer nor surrounding content is clipped to viewport height

#### Scenario: Footer review in Storybook

- **WHEN** a reviewer opens the component catalog
- **THEN** only the Default footer story appears under `Widgets/Footer`; existing toolbar controls select themes and viewports
- **AND** public and authenticated Home previews include exactly one shared footer through the real App layout without a separate footer-focused Home story

### Requirement: Footer columns remain permanently visible

Above 48rem the footer SHALL place the service block to the left of Explore and Help. At 48rem and below the service block SHALL span the top row with Explore and Help in two equal columns below. Each labelled navigation group SHALL contain one explicit heading and its direct anchors. The footer SHALL NOT contain details/summary, ul/li wrappers, chevrons or duplicated mobile/desktop links. Existing hrefs and Inertia/plain-anchor behavior SHALL be preserved.

#### Scenario: Visitor reads the footer at 320 CSS pixels

- **WHEN** the footer renders at 320 CSS pixels
- **THEN** copyright and Terms appear above Explore and Help
- **AND** all seven links are visible and uniquely accessible without toggling a group
- **AND** long labels wrap without horizontal page overflow

#### Scenario: Footer markup is available without client JavaScript

- **WHEN** the browser renders footer markup without executing client code
- **THEN** all seven navigation destinations are readable and follow ordinary hrefs
- **AND** no disclosure handler or enhancement is needed

### Requirement: Responsive presentation needs no scripted synchronization

CSS SHALL handle reflow without observing sizes, reading computed layout, running JavaScript media queries or transferring focus. The same anchors SHALL remain mounted and visible across breakpoint/orientation changes. The footer SHALL have no disclosure state, animation or persistence.

#### Scenario: Focused link crosses a responsive boundary

- **WHEN** a user focuses FAQ and resizes through 768/769 CSS pixels and back
- **THEN** FAQ retains focus on the same visible anchor
- **AND** all destinations remain available exactly once
- **AND** the footer performs no navigation or request

### Requirement: Footer links are truthful and passive

Every required destination SHALL provide useful content before footer delivery is accepted. The footer MUST NOT ship placeholder hrefs, invented support addresses, unavailable product features, or omissions presented as proof that missing dependencies are complete. The explicit Privacy deferral SHALL remain recorded under #248 and SHALL NOT satisfy its publication gate. It MUST NOT introduce tracking, remote data fetching, or third-party social scripts. Cookie preferences and social destinations SHALL be omitted unless the corresponding real mechanism or verified destination exists in approved scope.

#### Scenario: A mandatory page is not ready

- **WHEN** `/privacy`, `/terms`, or the deletion answer at `/help#delete-account` is missing, gated, or contains unfinished content
- **THEN** footer delivery acceptance remains incomplete
- **AND** neither a placeholder nor the explicitly deferred Privacy link satisfies policy/publication acceptance

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

### Requirement: Service information leads the footer

Copyright and Terms SHALL inherit the same font family, size, weight and line height. Their block SHALL lead the footer in DOM and visual order, sitting left of the directory above 48rem and above it on smaller screens. Text SHALL wrap naturally without clipping or hiding links. There SHALL be no separate bottom legal strip.

#### Scenario: Keyboard user enters the footer

- **WHEN** the user tabs into the footer at any width
- **THEN** guest account actions, when present, precede Terms in keyboard order
- **AND** the Explore links and then Help links follow in reading order

### Requirement: Guests can enter account workflows from the footer

Unauthenticated visitors SHALL see `Sign up · Have an account? Sign in` between the copyright and Terms. Sign up and Sign in SHALL be keyboard-accessible native buttons styled as text links, opening the existing shared registration and login dialog respectively without navigation. The separator dot SHALL be decorative. Authenticated visitors SHALL not see this row. The seven ordinary footer destinations SHALL remain unchanged.

#### Scenario: Guest chooses an account action

- **WHEN** a guest activates Sign up or Sign in in the footer
- **THEN** the existing dialog opens directly in registration or login mode respectively
- **AND** the current page URL remains unchanged
- **AND** Escape dismisses the dialog and returns focus to the initiating footer action

#### Scenario: Signed-in player reads the footer

- **WHEN** an authenticated page renders the footer
- **THEN** the guest account row is absent
- **AND** copyright, Terms, Explore and Help remain available

### Requirement: Publisher destination is ready before replacement

The `For publishers and rightholders` destination SHALL explain both proposing a game for adaptation or placement and raising concerns about rights in existing content. Its useful content and destination address MUST be supplied before replacing the runtime Games link. The approved `rights@d20.ravecat.io` address SHALL be prepared in the page while mailbox provisioning continues; verified receipt and monitoring remain a publication gate, not a prerequisite to this authorized local implementation. No separate game catalog SHALL be introduced by this change.

#### Scenario: Contact and page are not ready

- **WHEN** the rights-holder page has useful content and the user-approved address, but mailbox provisioning is incomplete
- **THEN** the page and footer link can be prepared and tested locally
- **AND** mail delivery is not reported as verified or the broader publication gate as complete


### Requirement: Footer spacing is continuous and uniform

Home SHALL retain equal 0.6667rem top and bottom padding matching existing catalog intervals. The footer SHALL follow main content without additional outer top padding. On short pages main SHALL consume spare height and the footer SHALL retain its natural height at the viewport bottom as specified by app-footer-placement (#271). Directory content SHALL have equal 1rem block insets inside its top divider; headings and links SHALL use equal 0.375rem gaps and at least 1.5rem targets. Preserve the outer 0.5rem bottom padding plus safe-area inset. Mobile service information SHALL have a 1rem inset before its lower divider and a 1rem gap before the navigation columns.

#### Scenario: Desktop directory includes a wrapped publisher link

- **WHEN** the publisher label wraps on desktop
- **THEN** the gap after its heading and between link boxes remains equal
- **AND** the catalog-to-footer divider interval retains the existing Home bottom inset

#### Scenario: Short Home and mobile navigation

- **WHEN** Home is shorter than the viewport or the footer is read at mobile width
- **THEN** short pages retain bottom footer placement and overflowing content retains normal document flow
- **AND** every navigation target stays visible with natural wrapping and no horizontal overflow
