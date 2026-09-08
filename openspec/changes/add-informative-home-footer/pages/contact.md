# Contact / support page

Route: `/contact`. Title and h1: `Contact / support`. Owner: #268. Layout: [shared article](README.md#shared-page-layout).

The user approved `support@d20.ravecat.io` for support/feedback and `rights@d20.ravecat.io` for game proposals and rights inquiries on 2026-09-07. Local implementation is authorized while the addresses are being provisioned. Actual receipt/monitoring remains a publication check under [ravecat/infra#2](https://github.com/ravecat/infra/issues/2).

## Content and links

1. Introduce support and feedback with visible, selectable `support@d20.ravecat.io` and ordinary `mailto:support@d20.ravecat.io`.
2. Technical problems and feedback: request the game/page, expected and actual behavior, and browser name/version. Ask users to remove personal information and sign-in details from screenshots.
3. Accounts and privacy: allow an inquiry without signing in; do not request passwords, one-time sign-in links, provider tokens, or private documents.
4. Publishers and rights holders: visible, selectable `rights@d20.ravecat.io`, ordinary `mailto:rights@d20.ravecat.io`, and an Inertia link to `/rights-holders`.
5. Existing shared footer.

Keep all content in the page component with native links and matching article styles. Do not add a form, clipboard button, address configuration, response-time promise, or a claim that receipt has been verified. Use ASCII `d20.ravecat.io` consistently. Do not add new page-body links to the pending Help/privacy/deletion documents before those destinations are delivered; their separate footer/publication obligations remain open.

## Verification

Verify direct anonymous access and signed-in Inertia navigation through the Phoenix route. Storybook covers exact mailto/cross-link targets and desktop/tablet/mobile rendering in light/dark. Mail sending is not part of automated UI verification; receipt/monitoring is verified after provisioning.
