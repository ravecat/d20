## Context

Prepared on 2026-09-05 and revised on 2026-09-06 for [#268](https://github.com/ravecat/d20/issues/268). Implementation was separately requested on 2026-09-06. The revision adopts Apple's block layout and responsive directory behavior and places deletion inside FAQ, following the user's clarifications. [verification.md](verification.md) records partial local implementation; this change is not deployed or accepted.

`assets/js/app/ui/footer.svelte` currently contains one `/developers` link. `assets/js/app/layout.svelte` renders that footer after `main` inside the existing Workspace boundary. The shell uses narrow and wide widths, responsive inline insets, themes, and bottom safe-area padding. `/games` and `/developers` exist; `/about`, `/help`, `/contact`, `/privacy`, `/terms`, and `/data-deletion` do not exist in the inspected router.

Facebook Login already has server routes and an active change under #187. Its adapter retains an app-scoped identity and an optional email candidate. There is no account-deletion action in the inspected router. Legal pages (#248), account deletion (#247), Meta metadata (#249), review (#251), and publication (#252) already have separate delivery owners.

The active uncommitted home-carousel work belongs to #264. This change is independent: it does not need that diff, change its acceptance criteria, or copy its state. The specification worktree is `/home/max/apps/d20/.worktrees/informative-home-footer`, branch `worktree/informative-home-footer`, based on committed `master` at `e12178085eff62d636d519ea4c4a7c869bbc3390`. Baseline strict OpenSpec validation passed all 79 items without environment initialization.

### Reference inspection

The public [Board Game Arena home page](https://en.boardgamearena.com/) was read on 2026-09-05. Its main content introduces browser play, pace and skill options, games, and a final entry action. Its footer then provides Help, Contribute, Navigate, and Follow us groups, followed by legal/privacy/cookie links. This is an information-architecture reference, not a pixel or content template.

| Observed BGA group | D20 decision | Purpose |
| --- | --- | --- |
| Help | About, How to play, FAQ, Contact / support | Explain the service and provide recovery/help paths |
| Contribute | Existing For developers; publisher/rights inquiries through Contact | Support actual contribution paths |
| Navigate | Existing Games; existing header brand links to Home | Reuse useful public destinations |
| Follow us | Omit initially | No verified D20 social destination is established |
| Legal strip | Privacy and Terms; Privacy links to the deletion answer in FAQ | Make policies and deletion guidance easy to find |

Premium, forums, community listings, newsletters, release numbers, and a cookie-settings button are not carried over. D20 does not need new product capabilities to fill the footer.

The [Apple home page](https://www.apple.com/), its [footer stylesheet](https://www.apple.com/ac/globalfooter/8/en_US/styles/ac-globalfooter.built.css), and [footer script](https://www.apple.com/ac/globalfooter/8/en_US/scripts/ac-globalfooter.built.js) were inspected on 2026-09-06. The source defines a full-width neutral background, a centered bounded directory, desktop columns, mobile disclosure rows at 833px and below, fine separators, and a separate wrapping legal row. Its script clears disclosure state when leaving mobile; its CSS exposes links when script enhancement is absent. This is source inspection, not a browser interaction recording. No matching Apple tab was available in the attached browser, and no unrelated tab was changed.

D20 adopts that organization with two useful link groups, its own fonts/tokens, existing shell widths, and the existing 48rem breakpoint. Apple's exact column count, 980px container, 12px type, 833px breakpoint, marketing footnotes, and country selector are not D20 requirements.

## Goals / Non-Goals

Goals:

- Give visitors a useful end-of-page information and help surface.
- Define exact link targets and useful page contents, including production policy/deletion dependencies.
- Preserve accessibility and the existing shell on desktop and mobile.
- Supply clear URL and content acceptance criteria for the existing Facebook publication work.

Non-goals:

- Deploying the footer before its mandatory documents and contact/deletion process are ready.
- Reimplementing account deletion, OAuth, or Meta app-review workflows.
- Launching Facebook Instant Games, buying advertising, publishing a Facebook page, adding social widgets, analytics, or a newsletter.
- Producing final legal text from unknown operator, jurisdiction, retention, or contact facts.

## Decisions

Use [layout.md](layout.md) for exact geometry, shell width alignment, the viewport/state matrix, and visual-review references. Use [pages/README.md](pages/README.md) for the shared public-page layout and individual content drafts. The sections below explain the decisions and contracts those references implement; page briefs distinguish usable draft copy from inputs that block publication.

### 1. Information architecture and wireframes

Use two equal, compact directory columns followed by a separate legal row below a fine rule. Do not repeat the D20 brand or tagline above the directory. Following user review, match Home's `--color-base-100` surface: white in light mode and the existing page surface in dark mode, without a contrasting gray band. Bound each desktop column to 12rem with a 1rem gap instead of distributing the groups across the entire container. Tighten vertical spacing as recorded in `layout.md`. The full inner container and separators stay centered and aligned to Home. Avoid a large promotional brand column, cards, shadows, or decorative panels. English labels match the current application; translation infrastructure is outside this change.

Desktop, aligned with the current narrow Home container:

```text
+---------------------------------------------------------------------+
| Existing Home content                                               |
+---------------------------------------------------------------------+
| Explore                Help                                         |
| About                  How to play                                  |
| Games                  FAQ                                          |
| For developers         Contact / support                            |
|                                                                     |
|---------------------------------------------------------------------|
| (c) <current year> D20             Privacy | Terms                   |
+---------------------------------------------------------------------+
```

Mobile, including 320 CSS pixels, with Help expanded after activation:

```text
+--------------------------------+
| Explore                      > |
|--------------------------------|
| Help                         v |
|   How to play                  |
|   FAQ                          |
|   Contact / support            |
|--------------------------------|
| (c) <current year> D20          |
| Privacy | Terms                |
+--------------------------------+
```

The year marker means the rendered current year, not literal placeholder text. The existing header brand links to `/`; the footer has no duplicate brand link. Legal content follows copyright, Privacy, Terms in DOM and visual order and wraps without becoming an accordion. Copyright and legal links inherit the same 0.8125rem font size, family, weight, and line height. Keep their baseline-aligned flex row at every viewport, including 446px; wrap only when content cannot fit, never because the directory crosses 48rem. The mobile wireframe below is a wrapped-content example, not a forced column. Explore and Help are footer group titles, not additional page links. How to play opens `/help`; FAQ opens the `faq` section of that same page; Contact opens `/contact`. The deletion answer lives inside FAQ with its own `delete-account` anchor and is not another footer item.

### 2. Required routes and content ownership

Prepared page briefs: [About](pages/about.md), [Help and FAQ](pages/help.md), [Contact](pages/contact.md), [Privacy](pages/privacy.md), and [Terms](pages/terms.md). The For developers page is reused. Games discovery remains on Home; `/games` currently redirects there and is not a planned separate catalog. New information pages use a narrow one-column article and the same shared footer at every viewport; their contents and anchors do not disappear into mobile footer-style disclosures.

| Label | URL | Minimum useful content | Owner |
| --- | --- | --- | --- |
| About | `/about` | Fan project creating digital versions of well-known board games; invite players, publishers, developers, and designers, with Contact, rights-holder, and developer links; no separate Games-page link or unsupported claims | #268 |
| For publishers and rightholders | `/rights-holders` | Game proposals and rights concerns, with a confirmed monitored contact | #268; blocked pending approved content/contact |
| For developers | `/developers` | Existing integration guidance | Existing developer page |
| How to play | `/help` | Find a game, open its details, follow available play/session actions, find game-specific rules, return to active games | #268 |
| FAQ | `/help#faq` | Accounts and sign-in methods, catalog versus playable entries, game rules, supported browsers, common loading/auth failures, support and deletion links | #268 |
| Contact / support | `/contact` | Confirmed operator contact, bug-report instructions, account/privacy requests, publisher/rights inquiries, and a private support channel | #268, operator supplies facts |
| Privacy | `/privacy` | Policy content specified below | #248 |
| Terms | `/terms` | Service terms specified below | #248 |
| How do I delete my account and data? (within FAQ) | `/help#delete-account` | Real deletion instructions and recovery/contact path; direct Privacy and Meta target | #247 supplies content; #268 hosts the Help section |

FAQ is a section of Help, and deletion is one question within FAQ. Keep that answer readable and expanded in the page, including on direct fragment navigation; footer disclosure behavior does not apply to FAQ answers. The canonical deletion URL is `/help#delete-account`. No `/data-deletion` route or compatibility redirect is required because that route has not been delivered. No contact form is required: a selectable approved address with a mail link is sufficient for implementation; actual receipt and monitoring are verified before publication. A public issue tracker can supplement technical bug reporting but cannot be the only path for account or privacy requests. Do not invent an email address or publish sensitive information in a GitHub issue.

Privacy and Terms must identify their effective/revision date and actual service operator. Privacy must describe D20's real account and optional-email handling, linked identity providers, browser state, game/session data, logging, purposes, recipients/processors, retention, rights and a contact/deletion path. Distinguish data processed transiently from persisted data. Terms must cover actual service/account rules, player conduct, game and publisher rights, service availability, suspension/termination, and support. Operator/jurisdiction decisions and legal wording remain with #248.

Deletion instructions must match #247's actual Account Settings action, confirmation/reauthentication, outcome, retained-data exceptions and timings. They must support provider-only accounts without email and explain how to request assistance if the user cannot sign in. Disconnecting Facebook access must not be described as proof that D20 has erased stored data. No self-service action is advertised before it exists.

### 3. Scope and rendering boundary

Keep one `Footer` in App UI, rendered by the existing Layout after main. Every Layout consumer receives the same Explore/Help directory, copyright, Privacy, and Terms. Remove `presentation`, the Layout `footer` prop, Home's footer layout export, and decorator forwarding. The existing `narrow`/`wide` shell width changes geometry only; there is no page-specific footer content mode and no duplicate footer inside Home.

Place isolated preview stories at `assets/stories/widgets/footer.stories.ts` with the sidebar title `Widgets/Footer`. This review-category change does not move runtime shell ownership into a new widget slice. Keep only Default and Mobile expanded footer stories. The latter uses the existing mobile viewport and opens both groups. Theme and viewport variants use existing toolbar controls instead of duplicated stories; browser tests own keyboard/focus and width checks. Existing public and authenticated Home stories assert one shared footer; remove the additional footer-focused Home story. Use existing Storybook screenshot comparisons for shell presentation rather than separate unit assertions about page layout exports. Remove the redundant Layout unit suite; footer browser tests own link targets, and the existing layout browser test retains document-scroll and main-content focus behavior.

Use the existing Svelte/Inertia page path for About and Contact and the normal Phoenix route/controller boundary. Help now carries the deletion document, so `/help` must include the FAQ answer and its `delete-account` id in readable initial HTML, just as `/privacy` and `/terms` must include their documents. Use existing Phoenix server-rendering facilities where needed; this does not require introducing SSR for the entire Inertia application. Fragment identifiers are browser-side: the server receives `/help`, not `#delete-account`. Verify both raw Help HTML and direct fragment navigation. Cross-boundary links use ordinary anchors when the target is a server-rendered document. Keep content versioned locally without a CMS or remote content dependency.

Required destinations are static content, so the footer has no fetch, loading skeleton, carousel state, or independent error state. The browser owns mobile disclosure state; add no custom state synchronization, library, storage persistence, or user-agent detection. Missing mandatory content is an acceptance failure. Optional social links are omitted unless a separately approved real destination is supplied. Links alone must not load a Meta SDK or other third-party script.

Keep directory markup and styles together in `footer.svelte`. Use ordinary desktop lists and native mobile `details`/`summary` elements, selected only by the existing CSS media query. Write Explore and Help as two explicit navigation blocks with literal headings and anchors. Apply `use:inertia` directly to About, For publishers and rightholders, For developers, and Contact / support anchors, reading their existing href; keep Help/FAQ and legal links ordinary. Omit the group array, link loops, and navigation flags; only one representation is visible and accessible at a time. This avoids forcing content inside closed details visible on desktop and works within the existing browser policy. There is no reactive disclosure state, observer, media-query API, computed-style read, mount callback, or custom focus handling. Keep the local `footer` class prefix and scoped root selector.

### 4. Responsive behavior and breakpoint transitions

At widths above 48rem, show equal columns with static headings and every link. At 48rem and below, show native independent disclosures, initially closed. Browser-managed `open` state and Enter/Space activation work without client JavaScript when markup is present. The legal row is always visible.

The user explicitly prioritized native simplicity over automatic focus handling on 2026-09-07. CSS switches between the two representations; mobile disclosure state survives desktop/mobile transitions while the component stays mounted. Do not add focus transfer, focused-link exceptions, automatic state reset, persisted state across visits, or disclosure event handlers. A focused element may lose focus when its representation becomes hidden. This replaces the earlier custom transition guarantees.

Use native expanded semantics instead of manually assigning `aria-expanded`. Collapsed or CSS-hidden links leave keyboard and accessibility navigation. Keep at least 2rem summary rows with 0.375rem block padding and visible keyboard outlines. Changes are immediate with no disclosure animation, including under reduced motion. No resize-triggered navigation, remount, scroll, or layout measurement is needed.

### 4.1 Visual and accessibility constraints

- Render one page-level `footer` after `main`, with distinctly labelled navigation groups and real anchors.
- Retain the existing 46.25rem narrow and 64rem wide maximum widths, 1rem narrow insets, wide 1rem/1.5rem breakpoint behavior, and bottom safe-area protection.
- Match Home's full-width page surface, with a centered inner container, fine section separators, compact regular-weight link lists, and stronger group headings. Use existing fonts and theme tokens. Normal text and links need at least 4.5:1 contrast in light and dark themes; do not copy Apple's small font size at the expense of readability.
- Preserve a visible focus indicator and logical link order. Provide at least 24 by 24 CSS-pixel link targets or equivalent spacing; target a comfortable 2rem row height on mobile.
- Permit text and legal links to wrap at 320 CSS pixels and 200 percent zoom. Do not truncate required labels, clip focus, or create page-level horizontal scrolling.
- Keep the footer in document flow. It must stay reachable with empty or short Home content and avoid overlapping the existing Workspace controls. Reduced motion must disable disclosure and inherited nonessential transitions.

### 5. Meta/Facebook requirements and evidence

Publication scope is the existing D20 Facebook Login app (#187), supported by issues #249-#252 and current OAuth routes. Instant Games remains outside this change. Apple supplies the footer layout reference; Board Game Arena supplied the initial destination inventory.

Official sources retrieved on 2026-09-05:

- [Meta Basic Settings](https://developers.facebook.com/documentation/development/create-an-app/app-dashboard/basic-settings): identifies Privacy Policy, Terms of Service and User Data Deletion URL fields; describes Terms, display name, contact email, icon, category and purpose as Live-mode fields. Business verification and DPO applicability require app-specific assessment.
- [Meta Data Deletion Request Callback](https://developers.facebook.com/documentation/development/create-an-app/app-dashboard/data-deletion-callback): requires a deletion request path and privacy-policy instructions. Its FAQ accepts an instructions URL or callback URL. A selected callback has a separate HTTPS request/status-response contract.

The web reader could not retrieve these pages. Direct HTTPS GETs followed Meta's `/docs/` redirects to `/documentation/` and returned official Markdown successfully. No third-party guide is used as authority. Documentation was checked; D20's private Meta dashboard was not inspected in this task.

| Site deliverable | Production URL / field | Publication action owner |
| --- | --- | --- |
| Privacy Policy | `https://d20.ravecat.io/privacy` -> Privacy Policy URL | #248 supplies; #249 configures |
| Terms of Service | `https://d20.ravecat.io/terms` -> Terms of Service URL | #248 supplies; #249 configures |
| Deletion answer inside Help FAQ | `https://d20.ravecat.io/help#delete-account` -> User Data Deletion instructions URL | #247 supplies; #268 hosts; #249 configures |
| Operator/support contact | `/contact`; confirmed dashboard contact email | #268 supplies public page; #249 configures |

D20's existing #247 decision selects instructions, not an automatic callback. A human-readable document must not be entered as a callback endpoint. A future callback would require a separate authenticated signed-request implementation and status response; it is not a footer link task.

Meta requires usable policies/deletion information, not a particular footer design, social icon, or a public page named Facebook. The footer provides discoverability. #249 owns app metadata; #250 owns the existing business-verification work; #251 owns permission review/testing evidence; #252 owns actual publication and a non-role-account check. These are independent external gates, so a completed footer cannot establish Meta approval.

Do not add a cookie-settings control until there is a real consent/preferences mechanism to open. Disclose actual browser state in Privacy. If nonessential tracking is introduced later, evaluate its disclosure and consent requirements in that owning change. Do not assert that this footer specification alone establishes legal compliance.

## Risks / Trade-offs

- Missing policy/deletion implementation -> #268 can be developed independently, but mandatory-link delivery acceptance waits for #247/#248 production evidence.
- Unknown operator identity, contact, retention, or jurisdiction -> collect and approve those facts before publishing affected content; no invented placeholders or fixed deletion deadline.
- A provider-only user loses login access -> deletion guidance must include a private recovery path without making email ownership a universal prerequisite.
- Policy or FAQ content exists only in client-rendered state -> require readable initial HTML for `/privacy`, `/terms`, and `/help`, with the deletion answer present under its stable anchor.
- Native disclosure and desktop representations duplicate rendered anchors -> keep matching explicit links in both representations, expose only one representation through CSS, and verify matching targets and unique accessible destinations at each width. Focus transfer across modes is intentionally omitted.
- Page-specific footer modes create unnecessary configuration -> one shared composition is used throughout Layout; existing shell width alignment and mobile disclosures keep it usable.
- Meta settings or review requirements change -> #249 rechecks the current dashboard when configuring it and records any additional app-specific gate.

## Migration Plan

1. Obtain the confirmed public contact and content facts. Coordinate `/privacy`, `/terms`, and `/help#delete-account` with #248/#247 without moving deletion behavior into this feature.
2. Implement product-information pages and the shared footer after a separate implementation request. Coordinate shared files with #264 if that work is still active; preserve its home props and carousel behavior.
3. Verify public routes, semantic links, themes, mobile disclosure interaction, breakpoint transitions, focus, and stories. Deploy mandatory documents and the FAQ deletion answer before or with the informative footer.
4. Record anonymous HTTPS GET checks and a real deletion-path verification supplied by #247. Hand URLs to #249; leave App Review and publication acceptance with #251/#252.
5. After all implementation and footer acceptance tasks pass, reconcile artifacts and archive this change through OpenSpec. Do not archive it merely because the specification has been written.

Rollback restores the previous shared footer without deleting public policy/deletion documents. If a published app must lose a required document or process, coordinate restoration or provider disablement with #252, including recovery for Facebook-only accounts.

## Open Questions

No unresolved choice blocks this footer design. The following are explicit content/publication inputs, not facts assumed by this specification: confirmed operator identity (#248) and operational mailbox verification (#268 / ravecat/infra#2), approved legal content and retention boundaries (#248/#247), and evidence of a working deletion journey (#247). Dependent content must not be published until those inputs are verified.

## Latest review scope

The final requested Explore label is `For publishers and rightholders`, replacing Games. Reserve `/rights-holders` for game-adaptation/placement proposals and concerns about rights in existing game content. On 2026-09-07 the user supplied `support@d20.ravecat.io` for support/feedback and `rights@d20.ravecat.io` for game proposals/rights inquiries and authorized preparing pages and footer links while mailbox provisioning is in progress. Use the existing ASCII production domain; the visually similar Cyrillic character in the message is not part of the configured domain. Implement public Inertia pages with literal mailto links, selectable addresses, concise inquiry guidance, and cross-links. Apply Inertia only to site-page navigation, never mailto links. Do not promise response times, verified receipt, or licensing outcomes. Do not add new Help/privacy/deletion cross-links inside these pages until those independent destinations are delivered; their existing shared-footer obligations remain open. Keep mailbox delivery/monitoring verification separate from implementation completion under ravecat/infra#2. This block supersedes the earlier Games inventory and wireframes.


## Spacing review - 2026-09-08

The current Home shell adds 1.5rem above content and 2.5rem below it; the footer adds another 1rem above its directory. Links use individual 0.25rem block padding, leaving half as much space after the heading as between links. Following the user's correction, set Home padding to `0.6667rem 1rem`, matching the existing catalog section/heading gaps, and remove the footer's additional top padding, and let the main grid row use its intrinsic height so short pages do not stretch a blank region before the footer. The remaining viewport space belongs below the footer contents. Use a 0.5rem CSS gap for desktop heading/list and list entries, with no per-link desktop block padding. Keep 0.5rem directory block padding and symmetric 0.5rem legal-strip padding plus bottom safe-area protection. Mobile retains native 2rem disclosure controls with 0.375rem block padding, contiguous link rows with 0.375rem block padding and a 1.5rem minimum target, and no list block padding.

Owning files: `assets/js/pages/home/ui/home.svelte`, `assets/js/app/layout.svelte`, and `assets/js/app/ui/footer.svelte`. Verify measured desktop/mobile geometry on the prepared Home page, existing footer/layout browser behavior, affected Storybook screenshots, scoped lint/formatting and type checks. Rollback reverts these styles and visual references without changing routes or data. The styling increment does not complete unrelated content or publication tasks.


### Footer separation correction - 2026-09-08

The user clarified that continuity requires equal spacing between blocks, not a zero gap. Home owns a single 0.6667rem bottom inset, exactly matching its existing section separation and heading-to-cards margin. Use the same 0.6667rem top inset through one logical block-padding declaration; preserve the footer's desktop geometry. This supersedes the initial zero-gap interpretation and changes only Home CSS plus its affected references. Validate the final catalog-to-divider interval against the existing catalog block intervals at desktop and mobile widths, and retain normal flow on short pages.


## Header proportions - 2026-09-08

The user requested a 25 percent reduction of the complete D20 brand and Log in button as the next refinement of this visual review. #268 tracks the increment in the same worktree; update the existing explicit size contract in `refine-borderless-app-shell` instead of introducing a parallel capability. Change native dimensions, typography and internal spacing in `assets/js/app/ui/header.svelte`. Following the vertical-spacing correction, use 3.75rem desktop, 3.375rem narrow and 2.3625rem compact minimum header heights. Center the contents without additional block padding, giving the mark 0.75rem expanded and 0.43125rem compact visual insets. Match the layout reserve and document scroll padding to the smaller expanded heights while preserving catalog/footer intervals. Retain native navigation, focus indicators, login interaction and reduced-motion fallback. Validate all size states in the prepared browser page, existing header/layout behavior, affected page screenshots and scoped frontend checks. Rollback restores the previous header declarations and associated visual references only.


## Sentence-case copy review - 2026-09-08

Write public-page copy and links in sentence case: capitalize the start of a sentence or standalone label, proper names and acronyms, rather than ordinary nouns within a phrase. Use `For publishers and rightholders` consistently for the footer destination, rights-page title/h1 and Contact cross-link. Use `Contact / support` for that destination and lowercase `support` in prose. Existing headings beginning with Publishers remain correctly capitalized as the first word. Change the source strings, not CSS text transforms, so visible text, accessible names and document titles agree. Update existing assertions and affected references. Rollback restores these strings and their matching assertions/references only.


## Final shell styling review - 2026-09-08

Use equal Home block padding and increase only the compact header visual insets by 15 percent, from 6px to 6.9px at the default root size. The unchanged 24px controls therefore need a 37.8px minimum row. The Apple global-footer stylesheet uses contiguous compact items and 6px link block padding. Apply that relationship to D20's existing 13px type/1.5 line height: 31.5px link rows without the previous extra 8px gap, with no additional list padding. Keep 2rem disclosure triggers with 0.375rem block padding and existing focus/keyboard/native-open behavior. Validate expanded groups at 320px and the prepared compact viewport, Home symmetry, compact header geometry and affected references. Consolidate the four unpublished styling commits and these corrections into one `style(shell)` commit as requested; preserve independent policy research. Rollback restores the matching shell styles and references together.


The final intermediate-width review also covers stale header compaction when closing footer groups removes root overflow. The linked shell change owns the reset at scroll offset zero. Keep the expanded header reserve stable; do not hide the mismatch by changing Home padding or adding a viewport-specific spacer.
