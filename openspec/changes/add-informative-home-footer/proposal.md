## Why

D20's footer currently exposes only a developer link, leaving visitors without a clear route to product information, help, or policies. An informative home footer should make these destinations discoverable and connect the public legal and deletion pages already required by the Facebook Login publication work.

## What Changes

- Add the requested guest account row `Sign up · Have an account? Sign in` beneath `d20 © <current year>`. Use text-link styling on native buttons opening the existing shared registration/login dialog; hide the row for authenticated visitors.
- Apply the 2026-09-08 Zed reference directly in local master: use one always-visible markup tree without details/summary, chevrons or ul/li wrappers. Place the service block left of Explore/Help above 48rem and above them at smaller widths. Preserve links, navigation actions, shell geometry, themes and safe-area spacing. Retain one Default footer story; replace obsolete disclosure tests with visibility, keyboard and resize-focus coverage. This supersedes earlier disclosure and bottom-strip decisions.

- Defer Privacy publication at the operator's request on 2026-09-08 and remove its current shared-footer anchor. Retain the unpublished draft and future `/privacy` contract under #248, blocked by explicit deletion #247, automatic deletion/retention #270 and the remaining operator/operational inputs. Integrate this reviewed increment and the existing styling work into local master without claiming public-launch readiness.

- Record the clarified initial launch: individual EU operator without a company, intended worldwide access, some publicly available source code, no launched paid-access offer and possible later paid access after demand validation. Keep member state/operator identity, minors' policy and any voluntary-support destination unresolved; prepare truthful current-stage wording without adding billing or promising perpetual free access.

- Adapt the prepared Help, Privacy and Terms content using current Board Game Arena pages as the primary reference and comparable public services as a coverage check. Record source dates and D20 implementation evidence, write original wording, and retain explicit operator/jurisdiction, age, commercial-model, licensing, retention and deletion decisions under #248/#247. Reference research does not establish legal protection or authorize publication of unsupported claims.

- Use sentence case throughout footer links and the corresponding public-page titles, headings, prose and cross-links, preserving proper names and acronyms.

- Continue the shell visual review by reducing the complete D20 brand and Log in button to 75 percent of their previous dimensions in all responsive/scroll states; reduce expanded header height and its matching document reserve proportionally, with 15 percent larger compact vertical insets while preserving catalog/footer block spacing. The existing `refine-borderless-app-shell` delta owns the explicit size contract.

- Apply the 2026-09-08 spacing review: use equal 0.6667rem Home block padding matching the existing catalog interval and replace the stacked gap before the footer with that same interval, preserve that interval on short pages, and use uniform CSS list gaps and symmetric divider insets.

- Define public About, How to play/FAQ, and Contact/support pages at `/about`, `/help`, and `/contact`; reuse `/developers`. Implement `/contact` using `support@d20.ravecat.io` for support and feedback and `/rights-holders` using `rights@d20.ravecat.io` for game proposals and rights concerns. Replace the footer Games entry with `For publishers and rightholders`. The user approved preparing these pages and links while the mailboxes are being provisioned; receipt/monitoring verification remains a publication gate.
- Keep Terms in the current service block; restore Privacy only with #248's verified publication. Put account/data deletion inside FAQ at `/help#delete-account`, linked directly from Privacy and supplied to Meta as the instructions URL; no separate deletion page or footer item is needed. Content and deletion behavior remain owned by #248 and #247.
- Use the same footer content on every existing App-layout page. Remove the unrequested compact/informative switch and page-level footer selection; retain only the shell's existing width alignment.
- Specify desktop/mobile ASCII wireframes, truthful content, ownership, production URL verification, and the Meta publication handoff.
- Provide a concrete layout reference covering the shared footer at narrow/wide shell widths, light/dark, existing Storybook presets, supplementary viewport boundaries, and resize/focus states.
- Refine About as a fan-project invitation for players, publishers, developers, and designers, with light, persuasive copy and implemented collaboration destinations instead of a Games page link.
- Prepare individual About, Help/FAQ, Contact, Privacy, and Terms page briefs with block order, copy or content contracts, public anchors, and explicit publication inputs.
- Require all mandatory destinations to work before accepting footer delivery. The explicitly requested Privacy deferral removes its current link but does not pass the pending policy/publication acceptance gate. Do not substitute placeholders for unfinished content.

## Capabilities

### New Capabilities

- `informative-home-footer`: Shared footer composition and navigation, link contracts, accessibility, and integration acceptance.
- `public-product-information`: About, help, and contact content, plus the public-document interface required from the existing legal/deletion work.

### Modified Capabilities

None. Existing App ownership, shell spacing, game discovery, and authentication contracts remain in force. This change adds requirements without rewriting those capabilities.

## Impact

- Tracking: [#268](https://github.com/ravecat/d20/issues/268). Implementation was requested on 2026-09-06 and continues directly in local master at the user's explicit request. See [verification.md](verification.md) for delivered local behavior and unresolved publication gates.
- Existing owners: [#247](https://github.com/ravecat/d20/issues/247) owns deletion and its instructions; [#248](https://github.com/ravecat/d20/issues/248) owns Privacy/Terms. [#249](https://github.com/ravecat/d20/issues/249), [#251](https://github.com/ravecat/d20/issues/251), and [#252](https://github.com/ravecat/d20/issues/252) own Meta settings, review, and publication. Their acceptance criteria are preserved.
- Expected frontend scope: `assets/js/app/ui/footer.svelte`, `assets/js/app/layout.svelte`, removal of Home's footer layout selection, new product-information pages, and focused tests and stories.
- Expected backend scope: public product-information routes in `lib/d20_web/router.ex`, page controller/rendering, and route tests. Legal/deletion endpoints are coordinated with their existing owners.
- No new package, database migration, channel/AsyncAPI change, game engine change, OAuth change, or iframe contract change is required by this footer specification.
- The carousel in #264 has an independent acceptance boundary. This specification uses the committed `master` baseline and requires none of that worktree's uncommitted changes.
- Rollback can restore the previous footer composition while retaining working policy/deletion URLs required by a published Meta app.

## Artifact Guide

- [Design](design.md): decisions, ownership, responsive state transitions, and Meta handoff.
- [Layout and viewport reference](layout.md): geometry, variants, viewport matrix, wireframes, and review states.
- [Prepared page briefs](pages/README.md): page index, shared article layout, individual drafts, and missing publication inputs.
- [Footer capability](specs/informative-home-footer/spec.md) and [public-information capability](specs/public-product-information/spec.md): normative acceptance scenarios.
- [Implementation tasks](tasks.md): work remains pending until separately implemented and verified.
