# Privacy Policy Page

Route: `/privacy`. Document title and h1: `Privacy Policy`. Content owner: #248. Footer/page coordination: #268. Layout: [shared article](README.md#shared-page-layout). Status: structured content brief; final policy requires confirmed operational facts and approval by its responsible owner.

## Block order and content brief

| Heading / id | Required content |
| --- | --- |
| Title and effective/revision date | Identify D20 and the approved document date |
| Who operates D20 / `operator` | Actual operator, relevant contact details, and service covered |
| Information we process / `information` | Account and optional email data, linked identities, browser state, game/session information, and operational logs actually processed |
| How we use information / `purposes` | A concrete purpose for each category; applicable processing grounds established by #248 |
| Sign-in providers / `providers` | Providers actually supported, what is received/stored, transient versus retained claims, and linking behavior |
| Browser storage / `browser-storage` | Actual session cookies and other storage; distinguish necessary operation from any separately introduced tracking |
| Sharing and service providers / `sharing` | Actual recipients/processors, hosting/mail/game-client boundaries and relevant transfer arrangements |
| Retention / `retention` | Approved periods or decision criteria by category, including deletion and backups/logs where applicable |
| Your choices and requests / `requests` | Applicable rights, contact process, identity verification, and practical access/deletion paths |
| Delete account and data / `deletion` | Concise explanation and direct link to `/help#delete-account` |
| Policy changes / `changes` | How revisions are dated and communicated |
| Contact / `contact` | Confirmed contact or direct link to the working `/contact` page |

These ids are page-local section targets, not additional public routes. Render the main sections as expanded headings and paragraphs with a simple contents list.

## Verified implementation facts for drafting

- D20 supports accounts linked to external identity providers; provider-only accounts can have no email.
- The Facebook adapter normalizes an app-scoped identifier and an optional email candidate. Its documented boundary excludes provider credentials and unrelated raw claims from the public normalized result.
- The product uses authentication session/browser state and has game-session and operational boundaries. Exact storage, recipients, and retention need an inventory; this brief does not assert an exhaustive data list.

Evidence: `lib/d20_web/auth/facebook.ex`, `lib/d20/accounts/user_identity.ex`, and the active provider-only/account specifications. Confirm current implementation when writing the final policy. Do not claim that no data is stored or that every account has an email.

## Prepared deletion section wording

`For instructions on deleting your D20 account and data, see How do I delete my account and data? in Help. If you cannot sign in, contact Support.`

Link the question directly to `/help#delete-account` and Support to `/contact`. Approve this text only when those paths describe an actually supported process.

## Required decisions before publication

The operator identity/contact, full processing inventory, purposes and applicable grounds, real recipients, retention, international transfers if any, applicable rights/age handling, and document date must be supplied under #248. This document does not choose a jurisdiction or invent a company, legal basis, DPO, processor, retention period, or consent mechanism.

The final `/privacy` response must contain the complete policy and revision date in anonymous initial HTML. No login, consent dialog, client-only fetch, PDF-only policy, or mobile accordion can be required to read it.


## Approved contact input on 2026-09-07

The user supplied `support@d20.ravecat.io` for support, feedback, and private account inquiries, and `rights@d20.ravecat.io` for game proposals and rights concerns. Contact-page implementation is authorized during provisioning; mail receipt/monitoring is not yet verified. This resolves the destination-address input only. Operator identity, approved legal content, retention/deletion facts, and publication approval remain with #248/#247.
