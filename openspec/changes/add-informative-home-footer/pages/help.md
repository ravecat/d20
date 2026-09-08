# Help and FAQ Page

Route: `/help`. Document title and h1: `Help`. Owner: #268; deletion content owner: #247. Layout: [shared article](README.md#shared-page-layout). Status: guide/FAQ copy prepared; the deletion answer requires verified #247 inputs before publication.

## Block order and anchors

1. `Help` title and introduction.
2. `On this page`: How to play (`#how-to-play`), FAQ (`#faq`), Delete account and data (`#delete-account`), Contact support (`/contact`). This page-local contents list is not an additional footer link.
3. `How to play` section, id `how-to-play`.
4. `Frequently asked questions` section, id `faq`, with the questions below as h3 headings.
5. Final support link and shared footer.

## Draft introduction and guide

Intro: `Find a game, get started, and find answers about your D20 account.`

### How to play

1. Open Games and choose a game to view its details.
2. Check the available game information and play options. If a game has no play action, it is not currently available to start from that page.
3. When play is available, review the displayed options and choose Play. Follow the lobby or game instructions that appear next.
4. Use the D20 workspace to return to your open game sessions while browsing.

Link: `Browse games` -> `/games`.

## Draft FAQ answers

### Why can I see a game but not play it?

The catalog includes games at different stages of availability. A game's page can provide information even when starting a session is not available. Use the play options actually shown on that page.

### How do I sign in?

Open the account action in the site header and choose one of the available sign-in methods. Follow its prompts. If a method is unavailable, choose another method already associated with your account or contact support.

Do not put an exhaustive provider list in this answer: availability is configured by the product.

### Where can I change my account settings?

After signing in, choose Settings in the site header. D20 may ask you to authenticate again before changing sensitive account information.

### Where are the game rules?

Rules and instructions depend on the game. Check the game's own information and in-game guidance. Contact support if you cannot find the instructions you need.

Do not imply that every current game page has a downloadable Rules button.

### How do I return to an open game?

Use the D20 workspace to select your open game session. This page does not promise that a session survives every server restart, browser-storage reset, or device change.

Editorial action: publish only the first sentence of this answer; the second sentence records its product boundary.

### A game or sign-in did not load. What should I do?

Check your connection and follow any error or retry guidance shown on the page. Use a current browser version. If the problem continues, contact support with the game or page involved, your browser, and what happened. Do not include passwords, sign-in links, or access tokens.

Do not prescribe clearing browser data or reloading an active game as a universally safe recovery step.

### Which browsers can I use?

Use a current browser version. If something does not work as expected, include your browser name and version when contacting support.

Do not embed a browser-version matrix into page copy; the project's existing browser-support policy governs implementation and testing.

### How do I delete my account and data?

Heading id: `delete-account`. Keep this answer expanded in the document and include a visible revision date approved with its final content.

This is a content contract, not publishable final instructions. #247 must supply these facts as one practical answer:

1. Where to find the real deletion action in Settings, using its exact delivered label.
2. The required recent authentication and explicit confirmation; account for linked-provider accounts without email.
3. What successful deletion does to account access, linked identities, and active sign-in sessions.
4. Which personal information is deleted, anonymized, or retained, with a reason and actual retention/completion timing.
5. What the user sees if deletion fails or is still pending, and what action is safe next.
6. How to obtain private assistance at `/contact` if the user cannot sign in.

Reusable explanatory sentence: `Removing D20 from your Facebook app connections does not by itself confirm that your D20 account and stored data have been deleted.`

The canonical instructions URL supplied to Meta and linked from Privacy is `https://d20.ravecat.io/help#delete-account`. The server receives `/help`; its initial HTML must contain the actual answer and id without needing JavaScript or authentication. No executable deletion action occurs merely by visiting this URL.

### How can I contact support?

Visit Contact / support or email `support@d20.ravecat.io` for account questions, technical problems, and feedback. Direct game proposals and rights inquiries to `/rights-holders` and `rights@d20.ravecat.io`.

Link: `Contact / support` -> `/contact`.

## Reference-based preparation - 2026-09-08

Use Board Game Arena's FAQ topic organization and Tabletopia's help categories to identify practical questions, then answer from D20's actual interface. See [reference research](reference-research.md) for dated sources and the limitation on live BGA FAQ extraction. Do not copy premium-account, tournament, ranking, chat, friendship, game-editor or subscription answers into D20 without a delivered feature.

Add the following original questions to the ordinary FAQ before the deletion answer:

### Is D20 free to use?

D20 is currently available without a paid-access plan while the project is being developed. Paid access may be introduced later. Any paid offer will describe its price and conditions before you choose to purchase it.

Editorial status: this reflects the operator's initial-launch direction. Recheck the actual offer before publication. Do not promise permanent free access, a guaranteed game count, payment dates or a subscription that has not launched. Voluntary support remains an undecided option; add no support-payment link or FAQ instructions until its actual destination and conditions are supplied.

### Can I sign in without an email address?

Some D20 accounts use an external sign-in provider without an email address. Use a sign-in method already linked to your account. In Settings, you can review your linked methods and add and verify an email address for email-based access and recovery. If you cannot sign in, contact support privately.

### Can I change my username?

Your username identifies you to other players. You choose it when completing your account, and it cannot currently be changed in Settings. Contact support if you have a concern about your username.

### Can I suggest a game or report a rights concern?

Yes. Use [For publishers and rightholders](/rights-holders) for game proposals, attribution questions and concerns about existing material. Include the game or material involved, a relevant link and your relationship to it. Use [Contact / support](/contact) for ordinary gameplay or account problems.

Editorial evidence: [account settings](../../../../assets/js/pages/account_settings/ui/account_settings.svelte), [username changeset](../../../../lib/d20/accounts/user.ex), and the implemented Contact/rights-holder pages. Verify the final labels during page implementation. Keep `faq` and `delete-account` stable; this research does not authorize advertising a nonexistent deletion action or silently replacing #247's required self-service process with an unverified email promise.

## Publication checks

Editorial notes under the draft questions are not page copy. The support/rights addresses were approved on 2026-09-07; receipt/monitoring is still pending. Resolve the deletion inputs and verify the operational support path before publishing Help as the Meta instructions destination. Test both FAQ and deletion fragment landing below the fixed header, with and without JavaScript, at desktop and mobile widths.
