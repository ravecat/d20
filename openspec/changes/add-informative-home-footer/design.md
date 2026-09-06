## Context

Prepared on 2026-09-05 and revised on 2026-09-06 for [#268](https://github.com/ravecat/d20/issues/268). This is a specification, not an implemented or deployed footer. The revision adopts Apple's block layout and responsive directory behavior and places deletion inside FAQ, following the user's clarifications.

`assets/js/app/ui/footer.svelte` currently contains one `/developers` link. `assets/js/app/layout.svelte` renders that footer after `main` inside the existing Workspace boundary. The shell uses narrow and wide widths, responsive inline insets, themes, and bottom safe-area padding. `/games` and `/developers` exist; `/about`, `/help`, `/contact`, `/privacy`, `/terms`, and `/data-deletion` do not exist in the inspected router.

Facebook Login already has server routes and an active change under #187. Its adapter retains an app-scoped identity and an optional email candidate. There is no account-deletion action in the inspected router. Legal pages (#248), account deletion (#247), Meta metadata (#249), review (#251), and publication (#252) already have separate delivery owners.

The active uncommitted home-carousel work belongs to #264. This change is independent: it does not need that diff, change its acceptance criteria, or copy its state. The specification worktree is `/home/max/apps/d20/.worktrees/informative-home-footer`, branch `worktree/informative-home-footer`, based on committed `master` at `e12178085eff62d636d519ea4c4a7c869bbc3390`. Baseline strict OpenSpec validation passed all 79 items without environment initialization.

### Reference inspection

The public [Board Game Arena home page](https://en.boardgamearena.com/) was read on 2026-09-05. Its main content introduces browser play, pace and skill options, games, and a final entry action. Its footer then provides Help, Contribute, Navigate, and Follow us groups, followed by legal/privacy/cookie links. This is an information-architecture reference, not a pixel or content template.

| Observed BGA group | D20 decision | Purpose |
| --- | --- | --- |
| Help | About, How to play, FAQ, Contact / Support | Explain the service and provide recovery/help paths |
| Contribute | Existing For developers; publisher/rights inquiries through Contact | Support actual contribution paths |
| Navigate | Existing Games; D20 brand links to Home | Reuse useful public destinations |
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

- Implementing product code during this specification task.
- Reimplementing account deletion, OAuth, or Meta app-review workflows.
- Launching Facebook Instant Games, buying advertising, publishing a Facebook page, adding social widgets, analytics, or a newsletter.
- Producing final legal text from unknown operator, jurisdiction, retention, or contact facts.

## Decisions

Use [layout.md](layout.md) for exact geometry, presentation variants, the viewport/state matrix, and visual-review references. Use [pages/README.md](pages/README.md) for the shared public-page layout and individual content drafts. The sections below explain the decisions and contracts those references implement; page briefs distinguish usable draft copy from inputs that block publication.

### 1. Information architecture and wireframes

Use an introductory line above two equal directory columns, then a separate legal row below a fine rule. The background spans the viewport; the content stays centered and aligned to the existing Home shell. Avoid a large promotional brand column, cards, shadows, or decorative panels. English labels match the current application; translation infrastructure is outside this change.

Desktop, aligned with the current narrow Home container:

```text
+---------------------------------------------------------------------+
| Existing Home content                                               |
+---------------------------------------------------------------------+
| D20 - Board games in your browser.                                   |
|---------------------------------------------------------------------|
| Explore                           Help                              |
| About D20                         How to play                       |
| Games                             FAQ                               |
| For developers                    Contact / Support                 |
|                                                                     |
|---------------------------------------------------------------------|
| (c) <current year> D20             Privacy | Terms                   |
+---------------------------------------------------------------------+
```

Mobile, including 320 CSS pixels, with Help expanded after activation:

```text
+--------------------------------+
| D20 - Board games in           |
| your browser.                  |
|--------------------------------|
| Explore                      > |
|--------------------------------|
| Help                         v |
|   How to play                  |
|   FAQ                          |
|   Contact / Support            |
|--------------------------------|
| (c) <current year> D20          |
| Privacy | Terms                |
+--------------------------------+
```

The year marker means the rendered current year, not literal placeholder text. The brand links to `/`. Legal content follows copyright, Privacy, Terms in DOM and visual order and wraps without becoming an accordion. Explore and Help are footer group titles, not additional page links. How to play opens `/help`; FAQ opens the `faq` section of that same page; Contact opens `/contact`. The deletion answer lives inside FAQ with its own `delete-account` anchor and is not another footer item.

### 2. Required routes and content ownership

Prepared page briefs: [About](pages/about.md), [Help and FAQ](pages/help.md), [Contact](pages/contact.md), [Privacy](pages/privacy.md), and [Terms](pages/terms.md). The existing Games and For developers pages are reused. New information pages use a narrow one-column article and compact footer at every viewport; their contents and anchors do not disappear into mobile footer-style disclosures.

| Label | URL | Minimum useful content | Owner |
| --- | --- | --- | --- |
| About D20 | `/about` | Browser board-game service, supported ways to start, what an account enables, link to Games and help; no unsupported claims | #268 |
| Games | `/games` | Existing catalog | Existing catalog |
| For developers | `/developers` | Existing integration guidance | Existing developer page |
| How to play | `/help` | Find a game, open its details, follow available play/session actions, find game-specific rules, return to active games | #268 |
| FAQ | `/help#faq` | Accounts and sign-in methods, catalog versus playable entries, game rules, supported browsers, common loading/auth failures, support and deletion links | #268 |
| Contact / Support | `/contact` | Confirmed operator contact, bug-report instructions, account/privacy requests, publisher/rights inquiries, and a private support channel | #268, operator supplies facts |
| Privacy | `/privacy` | Policy content specified below | #248 |
| Terms | `/terms` | Service terms specified below | #248 |
| How do I delete my account and data? (within FAQ) | `/help#delete-account` | Real deletion instructions and recovery/contact path; direct Privacy and Meta target | #247 supplies content; #268 hosts the Help section |

FAQ is a section of Help, and deletion is one question within FAQ. Keep that answer readable and expanded in the page, including on direct fragment navigation; footer disclosure behavior does not apply to FAQ answers. The canonical deletion URL is `/help#delete-account`. No `/data-deletion` route or compatibility redirect is required because that route has not been delivered. No contact form is required: a published, monitored address with a copyable value and a mail link is sufficient. A public issue tracker can supplement technical bug reporting but cannot be the only path for account or privacy requests. Do not invent an email address or publish sensitive information in a GitHub issue.

Privacy and Terms must identify their effective/revision date and actual service operator. Privacy must describe D20's real account and optional-email handling, linked identity providers, browser state, game/session data, logging, purposes, recipients/processors, retention, rights and a contact/deletion path. Distinguish data processed transiently from persisted data. Terms must cover actual service/account rules, player conduct, game and publisher rights, service availability, suspension/termination, and support. Operator/jurisdiction decisions and legal wording remain with #248.

Deletion instructions must match #247's actual Account Settings action, confirmation/reauthentication, outcome, retained-data exceptions and timings. They must support provider-only accounts without email and explain how to request assistance if the user cannot sign in. Disconnecting Facebook access must not be described as proof that D20 has erased stored data. No self-service action is advertised before it exists.

### 3. Scope and rendering boundary

Keep `Footer` in App UI. Add an explicit informational-versus-compact presentation choice independent of the existing `narrow`/`wide` width variant; Home selects the informative presentation and other existing layout consumers default to compact. Do not infer informative content from width or duplicate the footer inside Home. The compact presentation keeps For developers, Privacy, and Terms, always visible and wrapping as needed.

Use the existing Svelte/Inertia page path for About and Contact and the normal Phoenix route/controller boundary. Help now carries the deletion document, so `/help` must include the FAQ answer and its `delete-account` id in readable initial HTML, just as `/privacy` and `/terms` must include their documents. Use existing Phoenix server-rendering facilities where needed; this does not require introducing SSR for the entire Inertia application. Fragment identifiers are browser-side: the server receives `/help`, not `#delete-account`. Verify both raw Help HTML and direct fragment navigation. Cross-boundary links use ordinary anchors when the target is a server-rendered document. Keep content versioned locally without a CMS or remote content dependency.

Required destinations are static content, so the footer has no fetch, loading skeleton, carousel state, or independent error state. Only local mobile disclosure state and breakpoint/focus handling are needed; add no library, storage persistence, or user-agent detection. Missing mandatory content is an acceptance failure. Optional social links are omitted unless a separately approved real destination is supplied. Links alone must not load a Meta SDK or other third-party script.

### 4. Responsive behavior and breakpoint transitions

Use CSS viewport width, not device identity. At `width > 48rem`, the two equal columns show all links with static headings and no disclosure controls in the tab order. At `width <= 48rem`, each heading becomes a full-width disclosure control above its links, separated by a fine rule. A mobile initial render starts with both groups closed after enhancement; several groups can be opened independently. The introduction and legal row are always visible. Tablet, split-screen, orientation changes, and browser zoom follow the same threshold.

| Transition | Required D20 result |
| --- | --- |
| Desktop to mobile | Groups start closed, except any group containing the focused link stays open |
| Mobile to desktop | All links become visible; mobile open/closed state resets; a focused link retains focus |
| Mobile heading focused during switch to desktop | Move focus to the corresponding visible group heading, not the document body |
| Desktop group heading focused during switch to mobile | Move focus to that group's visible disclosure trigger |
| Desktop back to mobile | Start closed again, except the focused-link group; no saved state from the previous mobile visit |
| Resize or rotate while staying on one side of 48rem | Preserve that mode's state and current focus |
| Disclosure closes | Its links leave keyboard navigation and the accessibility tree; focus stays on its trigger |

Use the same link nodes across layouts. Do not remount Home or duplicate desktop/mobile navigation. Never hide the focused link during a breakpoint change. Do not reload, navigate, force-scroll to the top, or persist disclosure state across visits. These focus guarantees are D20 requirements, not claims that Apple's implementation handles every edge case identically.

Mobile controls expose `aria-expanded` and `aria-controls`, work with Enter/Space and pointer activation, and have at least 44px row height. Standard Tab/Shift+Tab traverses visible controls and links. Before enhancement or if disclosure script fails, show all groups as readable stacked lists; never produce hidden links controlled by a dead button. A short reveal/chevron transition of up to 200ms is allowed; reduced motion makes it immediate. No height or position animation should run just because the breakpoint changes.

### 4.1 Visual and accessibility constraints

- Render one page-level `footer` after `main`, with distinctly labelled navigation groups and real anchors.
- Retain the existing 46.25rem narrow and 64rem wide maximum widths, 1rem narrow insets, wide 1rem/1.5rem breakpoint behavior, and bottom safe-area protection.
- Use a neutral full-width footer surface, a centered inner container, fine section separators, compact regular-weight link lists, and stronger group headings. Use existing fonts and theme tokens. Normal text and links need at least 4.5:1 contrast in light and dark themes; do not copy Apple's small font size at the expense of readability.
- Preserve a visible focus indicator and logical link order. Provide at least 24 by 24 CSS-pixel link targets or equivalent spacing; target a comfortable 44px row height on mobile.
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
- Mobile collapses obscure a focused link or stale `aria-expanded` state -> use one responsive threshold and verify the breakpoint transition matrix, including focus exceptions and reduced motion.
- A generic expanded footer grows unrelated pages -> only Home opts into expansion; other shell pages keep the compact variant and existing geometry.
- Meta settings or review requirements change -> #249 rechecks the current dashboard when configuring it and records any additional app-specific gate.

## Migration Plan

1. Obtain the confirmed public contact and content facts. Coordinate `/privacy`, `/terms`, and `/help#delete-account` with #248/#247 without moving deletion behavior into this feature.
2. Implement product-information pages and the footer variants after a separate implementation request. Coordinate shared files with #264 if that work is still active; preserve its home props and carousel behavior.
3. Verify public routes, semantic links, themes, mobile disclosure interaction, breakpoint transitions, focus, and stories. Deploy mandatory documents and the FAQ deletion answer before or with the informative footer.
4. Record anonymous HTTPS GET checks and a real deletion-path verification supplied by #247. Hand URLs to #249; leave App Review and publication acceptance with #251/#252.
5. After all implementation and footer acceptance tasks pass, reconcile artifacts and archive this change through OpenSpec. Do not archive it merely because the specification has been written.

Rollback restores the compact footer without deleting public policy/deletion documents. If a published app must lose a required document or process, coordinate restoration or provider disablement with #252, including recovery for Facebook-only accounts.

## Open Questions

No unresolved choice blocks this footer design. The following are explicit content/publication inputs, not facts assumed by this specification: confirmed operator identity and support address (#268/#248), approved legal content and retention boundaries (#248/#247), and evidence of a working deletion journey (#247). Dependent content must not be published until those inputs are verified.
