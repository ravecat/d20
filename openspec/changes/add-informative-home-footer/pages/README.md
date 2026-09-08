# Public Page Preparation

These files prepare page layout and copy for #268. They are repository planning documents, not application routes or published policies. The capability specifications remain the acceptance contract. Copy under `Draft copy` can be used after the stated review; editorial notes and unresolved inputs must never be rendered into the public site.

Implementation update, 2026-09-07: About and the footer are implemented locally. Contact and For publishers and rightholders are now implemented and verified locally with the user-supplied addresses while mailbox provisioning continues. Help, Privacy, and Terms retain independent deletion/operator/legal inputs. See [local verification](../verification.md) for tests and publication blockers; no public release is accepted.

## Page inventory

| Page | URL | Preparation | Publication prerequisite |
| --- | --- | --- | --- |
| [About D20](about.md) | `/about` | Fan-project introduction and collaboration invitations | User-requested copy refinement, 2026-09-08; see verification |
| [Help and FAQ](help.md) | `/help`, `/help#faq` | Guide and FAQ draft, deletion content contract | #247 supplies verified deletion steps/outcomes |
| [Contact / support](contact.md) | `/contact` | Approved support/feedback and rights addresses; implementation authorized | Verify receipt/monitoring after provisioning |
| [For publishers and rightholders](rights-holders.md) | `/rights-holders` | Approved rights address and game/rights inquiry guidance | Verify receipt/monitoring after provisioning |
| [Privacy Policy](privacy.md) | `/privacy` (deferred) | Internal brief; omitted from current footer | #248, blocked by #247/#270 and operator/operational inputs |
| [Terms of Service](terms.md) | `/terms` | Section structure and core service-use draft | #248 approves service terms and legal decisions |
| Games | `/games` | Reuse existing catalog outside the footer | Preserve existing behavior |
| For developers | `/developers` | Reuse existing integration reference list | Preserve existing behavior |

The footer's `Help` is a column title. `How to play` opens the beginning of `/help`; `FAQ` opens its `faq` section. Deletion is the answer at `/help#delete-account`. Contact is a separate page. There is no new FAQ page or deletion page.

## Shared page layout

- Use existing site header behavior, one main article with one h1, and the same shared footer as Home, aligned to the narrow shell.
- Center a border-box container capped at 46.25rem, with 1rem inline padding. Body text stays within roughly 65 characters per line and never exceeds available width.
- Use existing font and theme tokens. Body copy uses 1rem text, 1.65 line height, 1rem paragraph spacing, and 2rem between major sections. Start with the existing Developers page heading scale, approximately 1.75rem on mobile to 2.5rem on desktop.
- On desktop and tablet landscape the article remains one reading column. On mobile it fills the available content width. Section contents follow the same DOM order in all viewports; do not add a fixed sidebar or horizontally scrolling tabs.
- Longer Help/Privacy/Terms pages have a plain wrapping `On this page` list before the article sections. All answers/sections are expanded; mobile footer disclosures are a separate interaction.
- Anchor targets sit below the existing fixed header. Navigation to Help FAQ/deletion works on a fresh load and through internal links. Give each page a distinct document title and h1.
- About, Contact, and For publishers and rightholders follow existing Inertia rendering. Help, Privacy, and Terms require useful initial HTML for anonymous GETs; Help includes deletion text and its id. Use ordinary cross-boundary links as required by the rendering choice.
- No forms, analytics, imagery, newsletters, social widgets, or extra content services are needed by these page drafts.

Desktop/tablet article:

```text
| Existing D20 header                                    |
|                                                       |
|        Page title                                     |
|        Short introduction                             |
|        Revision date (policy/deletion content)         |
|        On this page: Section A / Section B             |
|                                                       |
|        Section A                                      |
|        Readable prose and ordinary links              |
|                                                       |
|        Section B                                      |
|        Readable prose and ordinary links              |
|                                                       |
|        Explore                 Help                   |
|        About                   How to play / FAQ      |
|        For publishers and      Contact / support      |
|        rightholders                                   |
|        For developers          Contact / support      |
|        (c) YEAR D20                 Terms              |
```

Mobile article:

```text
| Existing D20 header          |
|                             |
| Page title                  |
| Introduction wraps here.    |
| On this page                |
| Section A                   |
| Section B                   |
|                             |
| Section A                   |
| Prose in one reading column |
|                             |
| Section B                   |
| Prose in one reading column |
|                             |
| Explore                  >  |
| Help                     >  |
| (c) YEAR D20                 |
| Terms                       |
```

Wrapping is content-dependent; the drawings do not prescribe manual line breaks.

## Content ownership and readiness

Privacy publication and its footer link are deferred at the operator's request on 2026-09-08. Keep [the explicit blockers](privacy.md#publication-blockers---2026-09-08) under #248; #247 owns explicit deletion and #270 automatic inactive-account/expired-data deletion. This navigation change does not resolve applicable transparency duties. Current footer wireframes show Terms only; restore Privacy with verified policy publication.

The user selected Board Game Arena as the primary Help/Privacy/Terms content reference on 2026-09-08, supplemented by comparable public services. [Reference research](reference-research.md) records the source selection, freshness and adaptation boundaries. The Help brief now includes additional D20-specific FAQ copy; Privacy includes a source-linked implementation inventory and candidate paragraphs; Terms includes original candidate clauses and decisions that depend on the operator. None is a final legal document or a newly implemented route.

### Operator and launch inputs - 2026-09-08

The user supplied the following facts after the initial reference research. They replace the earlier unanswered-input status; they do not approve the final policy text. #248 owns legal decisions and #247 the usable deletion process.

| Input | Confirmed direction | Remaining decision or limit |
| --- | --- | --- |
| Operator | Personal project operated by its creator; no company has been formed. Some source code is publicly available | Exact legal identity/contact and EU member state remain to be supplied. Do not infer a registered business or charity from personal residence/registration |
| Establishment | The operator lives and is registered in the EU | The member state was requested explicitly. Hosting provider availability does not identify the operator's country or processing locations |
| Audience | Worldwide availability is intended, without operator-imposed country restrictions | This is not a guarantee of access or legal eligibility in every country; assess applicable rules and actual provider restrictions separately |
| Ages | The user wants an audience comparable to BGA and has not chosen an age policy or implemented age restrictions | Do not turn the lack of a decision into an approved all-ages policy. Review minors' access and any parental process after the country is confirmed |
| Launch access | Initial preparation covers the current stage without a launched paid-access offer | Do not promise that all games or future features will remain free forever |
| Future revenue | Paid access is planned after building a useful catalog and assessing demand | Roughly 15-20 games is an internal exploration target, not a promised launch threshold, date, price or paid entitlement |
| Advertising and purchases | No advertising or purchase model has been decided | Do not introduce these features or make permanent no-advertising/no-payment promises |
| Voluntary support | The user is open to considering support contributions | No provider, recipient link, payment flow or benefits have been selected. No donation link can be published from this input alone |

The word transcribed as `Fofa` was queried as a possible `for fun` description. Keep the established D20 name; no rename or legal operator name is inferred while that clarification is pending. Public-source availability does not establish a particular software license or permission for every game's protected materials.

Product descriptions are grounded in the checked-in README, game launch page, header/account entry, workspace, and developer page. Do not turn implementation details into public copy or promise cross-device recovery, global multiplayer discovery, paid features, game licensing, or a fixed browser-version guarantee that this task has not established.

Required inputs are explicit editorial work, not public placeholders:

| Input | Owner | Affected copy |
| --- | --- | --- |
| Operator identity | Operator / #248 | Privacy and Terms |
| Mailbox receipt and monitoring for approved `support@d20.ravecat.io` and `rights@d20.ravecat.io` | Operator / #268 / ravecat/infra#2 | Contact, rights inquiries, and support references |
| Exact deletion action label, verification steps, outcomes and retention timing | #247 | Help deletion answer and Privacy |
| Data recipients, actual retention, applicable rights/jurisdiction and approved dates | #248 with #247 | Privacy and Terms |

Do not publish a legal document with missing facts or show an unfinished deletion answer to satisfy a link check. These inputs block dependent publication, not preparation of the page specifications or implementation of unrelated layout.

## Page validation

Review all six pages at the existing desktop 1280x720, tablet 1024x640, and mobile 320x900 presets in light and dark themes. Add targeted 390x844 and 200-percent zoom reviews for long headings, contact addresses, Help anchors, and policy paragraphs. Check one h1, meaningful title, heading hierarchy, link targets, keyboard focus, no overflow, and shared footer alignment.

For Help, Privacy, and Terms, inspect anonymous initial HTML independently of screenshots. Verify `/help#faq` and `/help#delete-account` land on the intended visible headings. The native test/build commands and implementation gates are recorded in [../tasks.md](../tasks.md).


## Copy style

Use sentence case for page titles, headings, prose and links. Capitalize the first word of a standalone label or sentence, proper names and acronyms such as D20 and FAQ. Ordinary nouns such as publishers, rightholders and support stay lowercase inside a phrase. Write the intended casing in the source copy rather than relying on CSS text transforms.
