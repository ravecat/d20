## ADDED Requirements

### Requirement: Prepared information pages share a responsive reading layout

About, Help, Contact, For Publishers and Rightholders, Privacy, and Terms SHALL follow the page briefs in [the page index](../../pages/README.md) and use one main article, one h1, a descriptive title, and the shared footer aligned to the narrow shell. The article SHALL remain a single reading column at the documented desktop/tablet/mobile viewports and use a centered maximum 46.25rem border-box container with 1rem inline padding. Contents lists, headings, answers, contact addresses, and paragraphs SHALL wrap in document order at 320px and 200 percent zoom without horizontal scrolling or clipping. Long-page sections SHALL remain expanded and anchor headings SHALL be visible below the fixed site header.

#### Scenario: Help on desktop and mobile

- **WHEN** a visitor reads Help at 1280x720, 1024x640, or 320x900
- **THEN** How to play and FAQ retain the same section order and readable content
- **AND** the deletion answer remains an expanded FAQ section
- **AND** the page has the same footer content as Home

#### Scenario: Contact address and policy text reflow

- **WHEN** a confirmed long contact address or policy paragraph renders at 320px or 200 percent zoom
- **THEN** it wraps without truncation or horizontal page scrolling
- **AND** its meaningful text and links remain usable in both themes

### Requirement: Publication distinguishes draft copy from confirmed content

Public pages SHALL render only approved page copy and confirmed operational facts. Editorial notes, preparation statuses, unresolved inputs, source-code references, and placeholders in the page briefs MUST NOT appear in the product. Missing operator/contact facts, legal approval, or actual deletion instructions SHALL block publication of the dependent content. A page brief SHALL NOT be treated as proof that its route or service exists.

#### Scenario: A prepared legal or contact brief has unresolved inputs

- **WHEN** implementation encounters an unconfirmed operator, contact address, retention decision, or deletion step
- **THEN** it does not publish a fabricated value or the editorial instruction
- **AND** the affected publication criterion remains incomplete until its owner supplies the fact

### Requirement: Public product pages explain existing capabilities

D20 SHALL expose About at `/about` and Help at `/help` without authentication. About SHALL introduce D20 as a fan project creating digital versions of well-known board games in a warm, inviting voice. It SHALL invite players, publishers, developers, and designers to collaborate and link to `/contact`, `/rights-holders`, and `/developers`. It SHALL NOT advertise or link to a separate Games page. Help SHALL explain the supported discovery, game-detail, play/session, rules, and return-to-active-game paths. Its stable `faq` section SHALL cover accounts, sign-in, playable/catalog distinctions, game-specific rules, browser support, common failures, support, and deletion. Content MUST describe delivered capabilities and MUST NOT invent game modes, availability promises, or recovery actions.

#### Scenario: Visitor opens a product-information deep link

- **WHEN** a visitor directly opens `/about`, `/help`, or `/help#faq` without an existing login
- **THEN** the requested useful content is available without signing in
- **AND** the FAQ link targets its stable section
- **AND** a page heading and document title identify the destination

#### Scenario: Visitor wants to contribute to D20

- **WHEN** a visitor reads About
- **THEN** they can find an invitation relevant to players, publishers, developers, or designers
- **AND** its links lead to the implemented contact, rights-holder, and developer pages
- **AND** About contains no `/games` link or promise of a separate catalog page

### Requirement: Public contact supports private account inquiries

D20 SHALL expose `/contact` with `support@d20.ravecat.io` for technical support, feedback, and account/privacy inquiries, plus `rights@d20.ravecat.io` and a `/rights-holders` link for publisher/rights inquiries. Both addresses SHALL be selectable text and exact ordinary mailto links using the ASCII domain. Local implementation is authorized while mailbox provisioning continues; it MUST NOT claim verified delivery, monitoring, or a response-time commitment. A contact form SHALL NOT be required when a copyable contact address and mail link provide the intended path. A public issue tracker MUST NOT be the only account/privacy contact method. The page MUST NOT request passwords, provider tokens, or unnecessary private documents.

#### Scenario: A user cannot sign in

- **WHEN** a user without an active D20 session opens `/contact`
- **THEN** they can read a private support contact path and the information needed to start an inquiry
- **AND** they are not required to publish account information in a public issue

#### Scenario: Approved addresses are still being provisioned

- **WHEN** the user supplies the support and rights addresses before mailbox provisioning completes
- **THEN** the public routes, selectable addresses, mailto links, and footer navigation are implemented and tested locally
- **AND** real receipt/monitoring verification remains incomplete until the mail infrastructure is ready

### Requirement: Publishers and rights holders have a dedicated contact page

D20 SHALL expose `/rights-holders` without authentication, titled `For Publishers and Rightholders`. It SHALL explain how to propose a game for adaptation or placement and raise a concern about existing game content. It SHALL provide `rights@d20.ravecat.io` as selectable text and an ordinary `mailto:rights@d20.ravecat.io` link, ask for the game/page, the sender's role and a concise request, and link technical/account support to `/contact`. It MUST NOT promise acceptance, licensing status, response times, or automatic removal. Page layout and responsive screenshots SHALL use the same article conventions as About and Contact.

#### Scenario: A rights holder opens the footer destination

- **WHEN** an anonymous visitor follows `For Publishers and Rightholders` in the footer
- **THEN** `/rights-holders` renders useful proposal and rights-concern guidance
- **AND** the address and mailto target are exactly `rights@d20.ravecat.io`
- **AND** account or technical inquiries can navigate to `/contact`

### Requirement: Policy destinations are public and versioned

The footer's policy dependencies SHALL provide `/privacy` and `/terms` on the production D20 domain. Both SHALL return HTTP 200 with readable initial HTML over HTTPS on an anonymous direct GET, without login, a consent wall, an iframe dependency, or executing JavaScript to obtain the document text. They SHALL identify D20's actual operator, a working contact path, an effective/revision date, and a descriptive document title. Content SHALL be versioned with a responsible owner and MUST NOT contain placeholder identities, contacts, or legal claims.

#### Scenario: Anonymous policy inspection

- **WHEN** a visitor or reviewer fetches either production policy URL without cookies or JavaScript
- **THEN** the initial response contains the actual document and revision date
- **AND** the request is not redirected to an authentication page

### Requirement: Policy content matches D20 data and service behavior

Privacy content supplied by #248 SHALL cover actual account data, optional email, linked providers, browser state, session/game data, operational logs, purposes, recipients, retention, user rights, contact, and deletion. It SHALL distinguish transient processing from storage and support provider-only accounts. Terms supplied by #248 SHALL describe actual account/service use, conduct, publisher and game rights, availability, termination, and support. This requirement defines the footer's document acceptance interface and SHALL NOT replace the legal content ownership or acceptance criteria of #248.

#### Scenario: A provider-only player reads Privacy

- **WHEN** a player whose D20 account has no email reads the policy
- **THEN** the description does not claim every account has an email
- **AND** it accurately describes provider identity handling and links to usable deletion guidance

### Requirement: Deletion instructions correspond to a usable process

The deletion dependency supplied by #247 SHALL appear as the answer to "How do I delete my account and data?" inside the Help FAQ, with the stable URL `/help#delete-account`. `/help` SHALL return HTTP 200 with readable initial HTML containing the answer, its `delete-account` id, and a revision date for anonymous HTTPS GETs without JavaScript. The answer SHALL remain expanded in the page; it MUST NOT be placed behind a FAQ accordion. Privacy SHALL link directly to the answer, and direct fragment navigation SHALL bring its heading into view without hiding it behind the fixed header. No separate deletion page or footer item SHALL be required. The answer SHALL describe the actual Account Settings action, confirmation/recent authentication, expected completion behavior, retained-data exceptions and timing, and private assistance when sign-in is unavailable. Instructions SHALL cover provider-only accounts without mandatory email ownership. They MUST NOT equate unlinking Facebook or signing out with D20 data deletion, advertise an unimplemented action, or treat a document URL as an automatic callback. Deletion implementation and its security/retention decisions SHALL remain owned by #247; #268 SHALL host its public answer in Help.

#### Scenario: User requests deletion after losing sign-in access

- **WHEN** a user opens `/help#delete-account` without an authenticated session
- **THEN** they can read the supported deletion and private assistance paths
- **AND** the public text itself does not require authentication
- **AND** performing destructive deletion still follows #247's identity-verification boundary

#### Scenario: Anonymous reviewer opens the deletion fragment

- **WHEN** a reviewer follows the Meta instructions URL without cookies or JavaScript
- **THEN** the `/help` response includes the full answer and its stable id
- **AND** the browser fragment targets the readable deletion heading within FAQ
- **AND** no separate document or collapsed answer is needed to read the instructions

#### Scenario: Instructions exist before self-service deletion works

- **WHEN** the page describes an Account Settings deletion action that is not usable
- **THEN** the deletion dependency and footer delivery acceptance remain unsatisfied

### Requirement: Public information is maintained without expanding runtime scope

Product pages SHALL use existing Phoenix web boundaries and the established frontend/server document rendering facilities. Content SHALL be versioned locally without a new CMS, remote content dependency, or public channel contract. Existing game-session behavior, OAuth routes, provider claims, and persisted account data SHALL remain unchanged by the footer implementation.

#### Scenario: Public pages are added

- **WHEN** product-information routes and footer links are delivered
- **THEN** existing `/games`, `/developers`, authentication and game-session routes retain their behavior
- **AND** no database migration or AsyncAPI change is required solely for the footer
