# For publishers and rightholders page

Route: `/rights-holders`. Title and h1: `For publishers and rightholders`. Owner: #268. Layout: [shared article](README.md#shared-page-layout).

The user approved `rights@d20.ravecat.io` on 2026-09-07 and authorized local implementation while mailbox provisioning continues. Receipt/monitoring remains a publication gate under [ravecat/infra#2](https://github.com/ravecat/infra/issues/2).

## Content and links

1. Introduce game proposals and concerns about existing game content, with selectable `rights@d20.ravecat.io` and ordinary `mailto:rights@d20.ravecat.io`.
2. Propose a game: ask for the game title, official product/rules link, the sender's role, and the proposed adaptation or placement discussion. Request only materials the sender is authorized to share.
3. Raise a rights concern: ask for the game and D20 page, the affected content or attribution, the request, the sender's relationship to the rights, and a reply contact.
4. Technical problems, account access, and general feedback: link to `/contact` through Inertia.
5. Existing shared footer, where this page replaces Games. The existing `/games` route remains available from About and other catalog entry points.

Do not promise acceptance, licensing outcomes, response times, or automatic content removal. Keep the static page, literal addresses, and native links self-contained. Do not add a form, file-upload mechanism, CMS, or address-state configuration.

## Verification

Verify direct anonymous access and signed-in Inertia navigation. Storybook covers exact mailto/cross-link targets, long-heading wrapping, and light/dark rendering at desktop/tablet/mobile sizes. Footer browser tests verify the exact label/route on desktop and inside mobile disclosures.
