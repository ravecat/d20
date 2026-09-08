# Privacy Policy Page

Route: `/privacy`. Document title and h1: `Privacy Policy`. Content owner: #248. Footer/page coordination: #268. Layout: [shared article](README.md#shared-page-layout). Status: publication deferred; internal content brief only, pending the blockers below.

## Publication blockers - 2026-09-08

Privacy publication is explicitly deferred. Remove the current shared-footer link; retain this internal brief and planned URL without creating a placeholder page. The removal does not resolve applicable transparency obligations for the public service. #248 is Blocked. The two deletion issues below are native blocked-by dependencies; the remaining rows record unresolved publication inputs:

| Blocker | Unblock evidence |
| --- | --- |
| [Explicit account deletion #247](https://github.com/ravecat/d20/issues/247) | Confirmed/recently authenticated deletion, credential revocation, shared delete/anonymize/retain decisions, failure/retry safety, provider-only and lost-access handling, and usable Help instructions |
| [Automatic account/data deletion #270](https://github.com/ravecat/d20/issues/270) | Approved inactivity definition, retention and notice/grace periods, exceptions and rollout; working cleanup with returning-user/concurrency protection, retries, monitoring and backup/restore handling |
| Operator and contact under #248 | Exact EU member state and controller identity; legally sufficient public contact/address with a residential-address alternative assessed for that country; no invented company or host-as-controller substitution |
| Production data inventory under #248 | Actual stored/transient data, purposes and legal grounds, recipients/countries and transfer safeguards, browser state, logs, support mail and backups |
| Retention and rights handling under #248/#247/#270 | Approved category-specific periods or criteria, justified exceptions, actual deletion/anonymization and backup expiry/restoration, monitored private requests and identity/response procedures |
| Support delivery under [ravecat/infra#2](https://github.com/ravecat/infra/issues/2) | Verified receipt and monitoring for private account/privacy requests |
| Eligibility and final content under #248 | Chosen minors' eligibility/parental process, jurisdiction-specific review, responsible content owner and revision date |

Inspection of `lib/d20/accounts.ex`, `lib/d20/accounts/user_token.ex`, `lib/d20/application.ex` and `lib/d20_web/router.ex` found authentication-token validity checks and action-specific token deletion, but no account-deletion route or scheduled inactive-account cleanup. Validity durations are not a retention schedule. Neither inactivity periods nor a cleanup implementation are selected in this footer increment.

Automation is a chosen product prerequisite, not an assertion that GDPR requires a scheduler or one fixed lifetime for all accounts. Manual handling of applicable rights must also work. Restore Privacy with verified #248 publication, its direct deletion-instructions link and updated navigation tests; public-launch and Meta checks remain open.

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

`For instructions on deleting your D20 account and data, see How do I delete my account and data? in Help. If you cannot sign in, contact support.`

Link the question directly to `/help#delete-account` and Support to `/contact`. Approve this text only when those paths describe an actually supported process.

## Reference-based preparation - 2026-09-08

Use the current Board Game Arena legal document as the primary coverage reference, with Tabletopia and Lichess as comparisons. The [reference research](reference-research.md) records source dates, useful patterns, and exclusions. Write original D20 copy. This brief is not a completed policy, and another service's policy does not establish D20's legal basis, retention schedule, recipients, or compliance.

### Verified D20 inventory

This is a repository inventory for drafting, not a production audit. Confirm deployment and operating practices before publication.

| Category | Verified implementation | Disclosure or decision needed |
| --- | --- | --- |
| Account | [User schema](../../../../lib/d20/accounts/user.ex) stores username, optional email, password hash when set, account role, confirmation and record timestamps | Explain account creation, access and security. Do not say every account has email or that plaintext passwords are stored |
| Linked sign-in | [Identity schema](../../../../lib/d20/accounts/user_identity.ex) stores provider name, provider user id, user association and timestamps; provider credentials are outside this schema | Explain optional sign-in/linking and distinguish transient authentication exchanges from persisted identifiers. Verify which providers are enabled |
| Authentication tokens | [Token implementation](../../../../lib/d20/accounts/user_token.ex) stores session/email token records, context, recipient where relevant and timestamps | Validity is 15 minutes for magic links, 7 days for email changes and 14 days for sessions. These values do not prove deletion of expired database rows or backups |
| Browser state | [Endpoint](../../../../lib/d20_web/endpoint.ex) uses the `_d20_key` session cookie; [authentication](../../../../lib/d20_web/auth.ex) defines a 14-day remember-me cookie, renewable during continued use | Explain session continuity, account security and remembering sign-in. Inventory cookie lifetimes and actual deployed attributes separately from database retention |
| Apple sign-in state | [Apple adapter](../../../../lib/d20_web/auth/apple.ex) defines short-lived flow, linking and reauthentication cookies with 600-second maximum ages | Include these when Apple sign-in is enabled; do not claim that only two cookies can ever exist |
| Game participation | [Session state](../../../../lib/d20/sessions/session.ex) processes actor ids, membership/presence and game state; [module connection](../../../../lib/d20_web/module.ex) supplies actor/game/session context to embedded game clients | Describe participating-player visibility and game-client processing; verify each deployed game's storage and host. Runtime state is not proof of permanent game-history storage |
| Email and support | [Production configuration](../../../../config/runtime.exs) configures Resend for outbound application mail; approved support/rights aliases have a separate forwarding dependency | Confirm actual mail recipients, forwarding provider, storage locations, access, agreements and retention. Repository configuration does not verify successful delivery |
| Operations | [Production logging](../../../../config/prod.exs) enables info-level logging and [parameter filtering](../../../../config/config.exs) redacts specified authentication fields | Inventory actual application, proxy/CDN, host, error, backup and security records, including any IP/browser data. Do not infer zero logging from a minimal account schema |

### Original candidate wording

The following paragraphs cover verified product behavior only. Add the missing operator, purpose-by-purpose legal grounds, recipient, location, retention and rights sections before using them publicly.

#### Account and sign-in information

When you create or use an account, D20 processes your username, account identifiers and the information needed to provide your chosen sign-in methods. An account may have an email address, a password, linked sign-in providers, or a combination of these. When you set a password, D20 stores its password hash. An account created through an external provider can exist without an email address.

When you use or link an external sign-in provider, D20 uses the provider's account identifier to connect that identity to your D20 account. Authentication may also supply an email address. The provider processes the sign-in interaction under its own terms and privacy information.

#### Browser state and games

D20 uses browser cookies to maintain your session, protect sign-in flows and remember your sign-in when you request that option. Blocking this browser state can prevent sign-in or interrupt features that depend on your session.

When you play, D20 processes your participation and game actions to operate the session and show the game state permitted for each participant. Your username identifies you to other players. Embedded game clients receive the connection and player context needed to operate the game.

#### Contacting support

When contacting support, send only the information needed to explain your request. Do not send passwords, one-time sign-in links or provider access tokens. Use the private contact path for account and privacy questions.

### Complete before publication

- Use the [confirmed launch inputs](README.md#operator-and-launch-inputs---2026-09-08): the operator is an individual in the EU, without an incorporated company, with intended worldwide availability. Obtain the exact member state and public operator identity/contact; decide minors' eligibility and any parental procedure. Do not identify the hosting provider as the service operator or infer its processing locations from worldwide accessibility.
- Map each actual processing purpose to its applicable legal basis. Distinguish any optional consent from processing needed for the service; do not treat use of the site or acceptance of Terms as blanket privacy consent.
- Record recipients and relevant processing countries, including hosting, transactional mail, forwarding, external sign-in, embedded clients and remotely loaded assets. Assess transfer safeguards where applicable.
- Approve retention periods or meaningful criteria for accounts, identities, tokens, support mail, logs and backups; document how deletion and anonymization actually occur. Do not borrow BGA's periods or claim immediate removal from every backup.
- Determine applicable user rights, request/identity-verification procedure, response deadlines, supervisory complaint route, age handling, and any automated decision-making. Publish contact and deletion instructions only when the corresponding operation is usable.
- Verify the production storage/network inventory before making advertising, tracking, sale/sharing, security or data-residency claims. This investigation found no evidence that justifies copying another service's marketing or advertising practices into D20.

Where GDPR applies, the [European Commission's transparency guidance](https://commission.europa.eu/law/law-topic/data-protection/information-business-and-organisations/obligations_en) supports identifying the controller, purposes, legal grounds, recipients, retention, transfers and applicable rights. Applicability and D20's concrete answers remain to be established. A lawyer familiar with the operator's jurisdiction should review the completed policy before publication.

### Current stage and future payment data

Prepare the notice for the public EU-operated service and its actual current data flows. Personal-project status, free initial access and publicly available source code are not evidence of a data-protection exemption. Use the [EDPB scope guidance](https://www.edpb.europa.eu/sme/learn-the-basics/data-protection-basics_en) and the eventual member-state review to establish the applicable obligations.

Paid access is a future intention; voluntary support is only being considered. Do not list a payment provider, billing categories or donation records as current D20 processing without evidence. Before activating either kind of payment, inventory the actual recipient/provider, transaction data, billing/tax records, purpose and legal basis, retention, transfers and user rights. Do not infer charity status or deductible donations from the word support.

## Required decisions before publication

The operator identity/contact, full processing inventory, purposes and applicable grounds, real recipients, retention, international transfers if any, applicable rights/age handling, and document date must be supplied under #248. This document does not choose a jurisdiction or invent a company, legal basis, DPO, processor, retention period, or consent mechanism.

The final `/privacy` response must contain the complete policy and revision date in anonymous initial HTML. No login, consent dialog, client-only fetch, PDF-only policy, or mobile accordion can be required to read it.


## Approved contact input on 2026-09-07

The user supplied `support@d20.ravecat.io` for support, feedback, and private account inquiries, and `rights@d20.ravecat.io` for game proposals and rights concerns. Contact-page implementation is authorized during provisioning; mail receipt/monitoring is not yet verified. This resolves the destination-address input only. Operator identity, approved legal content, retention/deletion facts, and publication approval remain with #248/#247.
