# Production auth email provider research

Research date: 2026-08-07

Scope: low-volume transactional email for D20 registration and login magic links
Source policy: current first-party pricing pages, provider documentation, AWS documentation, Phoenix announcements, and Swoosh documentation only

## Decision

Use **Resend** for the first production integration.

This is an evaluation, not a provider-published fact. Resend is the best fit for the combined criteria because its permanent free tier is large enough for an early low-volume application, its HTTP integration needs only an API key after domain verification, Swoosh 1.27 has a native adapter, and Resend publishes Elixir and Phoenix examples. The free limit is 3,000 emails per month and 100 per day. After that, the first paid plan is $20 per month for 50,000 emails, so its cost cliff is the main tradeoff. [Resend pricing](https://resend.com/docs/knowledge-base/what-is-resend-pricing), [Swoosh Resend adapter](https://swoosh.hexdocs.pm/Swoosh.Adapters.Resend.html), [Resend Elixir guide](https://resend.com/docs/send-with-elixir)

Shortlist:

1. **Resend - recommended default.** Best balance of no-cost operation, simple D20 integration, narrow API credentials, and relevant framework examples.
2. **Brevo - choose when the continuing free allowance matters more than a clean product email.** It permits 300 sends every day indefinitely, but unused capacity does not roll over and every Free-plan email has a mandatory "Sent with Brevo" sticker. [Brevo Free limits](https://help.brevo.com/hc/en-us/articles/208580669-FAQs-What-are-the-limits-of-the-Free-plan)
3. **Amazon SES - choose when D20 has already outgrown free tiers and minimizing marginal cost is worth AWS operational complexity.** Standard outbound email is $0.10 per 1,000 recipients with no minimum fee, but a new account starts in a restrictive regional sandbox and needs a production-access review. [SES pricing](https://aws.amazon.com/ses/pricing/), [SES sandbox and production access](https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html)
4. **ZeptoMail - price-check before choosing as the low fixed-cost fallback.** Its public USD page displays $2.50 per 10,000-email credit, valid for six months, after a free first credit valid for one month. It is cheap and has a native Swoosh adapter, but buying credits requires account review, the review normally takes two business days, and its terms require identifying business and contact information in every message. [ZeptoMail pricing](https://www.zoho.com/zeptomail/pricing.html?src=pd-menu), [account review](https://help.zoho.com/portal/en/kb/zeptomail/faqs/sending-emails/articles/why-is-my-zeptomail-account-still-not-reviewed), [ZeptoMail terms](https://www.zoho.com/zeptomail/terms.html)

Do not select Postmark or Mailgun for this use case on price alone. Their first paid tier is $15 per month, while their free allowances are no better than the shortlisted providers. SMTP2GO remains a reasonable fallback if Resend onboarding fails, but its free allowance is only 1,000 per month and its current public pricing metadata is internally inconsistent.

## Acceptance criteria for the implementation issue

The production provider task should be complete only when all of the following are true:

- A provider is selected explicitly, with the expected daily and monthly auth-email volume recorded.
- The sending domain or a dedicated auth subdomain is verified, with SPF, DKIM, and DMARC alignment checked from a delivered message.
- Production uses the provider's native Swoosh HTTP adapter and the existing `Swoosh.ApiClient.Req`; SMTP is not introduced unless the chosen provider lacks a suitable HTTP adapter.
- A send-only, domain-scoped API key is used when the provider supports that scope. The key is supplied by production environment configuration and is never committed.
- Production startup fails clearly when required mailer environment variables are missing.
- Registration and login magic-link delivery succeeds to at least Gmail and Outlook test recipients from the production deployment.
- Provider responses that mean quota exceeded, rejected sender, invalid key, rate limit, or transient failure are logged without exposing tokens or magic links.
- The auth request does not produce an Inertia HTML error dialog when delivery fails. The user receives the existing delivery-failure state, while operators receive actionable logs.
- Duplicate user-visible magic-link sends are prevented or made safe across retries. Resend supports API idempotency keys retained for 24 hours, which Swoosh exposes as a provider option. [Resend idempotency](https://resend.com/docs/dashboard/emails/idempotency-keys), [Swoosh Resend adapter](https://swoosh.hexdocs.pm/Swoosh.Adapters.Resend.html)
- Quota alerts are configured before 80 percent of the relevant daily or monthly limit, and the runbook says what happens at the hard limit.
- The sender address can receive replies, or `Reply-To` points to a monitored address.
- A rollback is documented: switch the runtime mailer adapter and credentials back to the previous provider without changing auth email construction.

## Provider comparison

Prices are in USD before taxes unless the provider states otherwise. A recipient counts as a billable email for these services, so D20's one-recipient magic-link messages map directly to the listed units.

| Provider | Free allowance and hard limits | First cost after free | HTTP API and Swoosh fit | Domain and account setup | Assessment for D20 |
| --- | --- | --- | --- | --- | --- |
| **Resend** | 3,000 emails/month, 100/day, one domain, no free-plan overage | Pro is $20/month for 50,000; optional overage is $0.90/1,000 on paid plans | Native `Swoosh.Adapters.Resend`; adapter config is an API key; D20 already has Req; provider has Elixir and Phoenix examples | Verify two DNS entries, SPF and DKIM; create a send-only key that may be restricted to the domain | **Best overall.** Very small code and operational surface. Main risk is the jump from $0 to $20 when either quota is too small. |
| **Brevo** | 300/day forever, no credit card; unused sends do not roll over; up to 1,000 over-limit emails are held for retry and later sends are not delivered; mandatory Brevo footer branding | Starter starts at $9/month for 5,000/month and removes the daily cap; removing Brevo branding is an add-on on Starter | Native `Swoosh.Adapters.Brevo`; one API key; JSON `POST /v3/smtp/email`; D20's Req client is sufficient | Automatic DNS setup is available for supported registrars; manual flow adds Brevo ownership TXT, DKIM as one TXT or two CNAME records, and DMARC TXT | **Best permanent free capacity.** Branding and the daily rather than monthly quota make it less clean for an auth-only product. |
| **Amazon SES** | No SES-specific permanent free tier for new customers as of 2026-07-21; new AWS customers can use up to $200 of general AWS credits for six months; older qualifying SES users retain the prior 3,000-message-charge benefit for the rest of their 12 months | Standard outbound is $0.10/1,000 plus $0.12/GB of outgoing message data; no minimum fee | Native `Swoosh.Adapters.AmazonSES`, but it needs region, access key, secret, and the additional `gen_smtp` dependency; direct HTTPS requests require AWS signing | Three Easy DKIM CNAME records; identity is regional; every new regional account starts in sandbox with verified-recipient-only sending, 200/day, 1/second, then requests production access | **Cheapest metered service, most setup.** Good after free tiers, poor for the quickest safe launch. |
| **Postmark** | 100/month indefinitely; no overage on Free | Basic is $15/month for 10,000; extra $1.80/1,000 | Native `Swoosh.Adapters.Postmark`; one server API key; simple JSON `POST /email` | Confirm a sender signature or domain; DKIM is the key DNS record; custom Return-Path is recommended for full DMARC alignment | **Very simple but expensive for this volume.** The gap between 100 free and the $15 tier is unfavorable. |
| **Mailgun** | 100/day on Free; one custom domain; one day of logs | Basic starts at $15/month for 10,000; extra from $1.80/1,000 | Native `Swoosh.Adapters.Mailgun`, but D20 would also need the `multipart` dependency; HTTP API is multipart form rather than JSON | Documented verification flow lists SPF TXT, DKIM TXT, tracking CNAME, and MX records; production uses a custom domain and selected US or EU endpoint | **No price or simplicity advantage.** Its Phoenix-generated recipe is useful, but that is not enough to outweigh extra dependency and DNS work. |
| **SMTP2GO** | 1,000/month for as long as needed; 200/day; 25/hour until the sender domain is verified; sending stops at the monthly cap | The pricing page rendered Starter at $10/month or $100/year for 10,000, with $1/1,000 overage; its page title still says plans start at $15/month, so checkout must be verified | Native `Swoosh.Adapters.SMTP2GO`; API key and JSON `POST /v3/email/send`; D20's Req client is sufficient | Three CNAME records for SPF, DKIM, and tracking; sign-up requires a private-domain work email and SMS verification | **Solid fallback.** Easier and cheaper paid floor than Postmark or Mailgun, but lower free capacity than Resend and Brevo. |
| **ZeptoMail** | First 10,000-email credit is free for one month; initial sending is limited to 100/day; additional credits cannot be bought before review | Public USD page displays $2.50 per 10,000-email credit; credits expire six months after purchase; no monthly subscription | Native `Swoosh.Adapters.ZeptoMail`; API token and JSON HTTP API; each Agent has separate credentials | Verify DKIM TXT and return-path CNAME; create or use an Agent; account review normally takes two business days | **Strong cheap paid candidate with policy friction.** Magic links fit its transaction-only policy, but the required entity address, telephone number, email contact, and abuse contact in every message may not fit D20. |

### Pricing facts and caveats

#### Resend

- Verified fact: Free is $0 for 3,000 sent or received emails per month, limited to 100 per day and one domain. Multiple `To`, `Cc`, or `Bcc` recipients count separately. There is no overage on Free. Pro starts at $20 for 50,000, and paid overage is $0.90 per 1,000. [Official pricing detail](https://resend.com/docs/knowledge-base/what-is-resend-pricing)
- Verified fact: after adding a domain, Resend requires SPF and DKIM records; DMARC is optional but recommended. [Domain verification](https://resend.com/docs/dashboard/domains/introduction)
- Verified fact: sending-only keys can be scoped to a domain. [API key permissions](https://resend.com/docs/dashboard/api-keys/introduction)
- Inference: 3,000 per month and 100 per day is ample for an early D20 deployment if each auth attempt sends one email and there are no marketing sends. The issue should record real volume and alert before either cap rather than assume this remains true.

#### Brevo

- Verified fact: Free is unlimited in time, needs no credit card, and includes 300 sends per day. Unused sends do not roll over. After the cap, at most 1,000 messages wait in a retry queue and later messages are not delivered. [Free plan limits](https://help.brevo.com/hc/en-us/articles/208580669-FAQs-What-are-the-limits-of-the-Free-plan)
- Verified fact: Starter starts at $9 per month for 5,000 monthly sends and removes the daily cap. Free emails always include Brevo branding. [Plans](https://help.brevo.com/hc/en-us/articles/208589409-About-Brevo-s-pricing-plans), [branding rule](https://help.brevo.com/hc/en-us/articles/208580669-FAQs-What-are-the-limits-of-the-Free-plan)
- Verified fact: its transactional endpoint is a conventional API-key authenticated JSON POST and Swoosh has a native transactional-only adapter. [Transactional API](https://developers.brevo.com/docs/send-a-transactional-email), [Swoosh adapter](https://swoosh.hexdocs.pm/Swoosh.Adapters.Brevo.html)
- Inference: Brevo's theoretical 9,000 sends in a 30-day month is not a monthly bucket. It cannot absorb a signup spike above 300 in one day without delayed or failed auth mail.

#### Amazon SES

- Verified fact: AWS announced that the SES-specific free tier ended for new customers on 2026-07-21. Existing qualifying customers keep their remaining 12-month benefit, while new AWS customers may apply up to $200 in general AWS credits during their first six months. [AWS announcement](https://aws.amazon.com/blogs/messaging-and-targeting/introducing-amazon-simple-email-service-ses-pricing-plans/)
- Verified fact: standard outbound pricing is $0.10 per 1,000 recipients with no minimum, plus outgoing data charges. [SES pricing](https://aws.amazon.com/ses/pricing/)
- Source caveat: the general SES pricing page still described the older 3,000-message-charge free tier when accessed. The newer dated AWS announcement is used for new-account eligibility.
- Verified fact: sandbox restrictions are per region, restrict recipients to verified identities, and cap sending at 200 per 24 hours and one per second. AWS says the initial production-access response is normally within 24 hours. [Production access](https://docs.aws.amazon.com/ses/latest/dg/request-production-access.html)
- Verified fact: Swoosh's direct SES adapter uses the SES Query API and needs `gen_smtp`, region, access key, and secret. [Swoosh SES adapter](https://swoosh.hexdocs.pm/Swoosh.Adapters.AmazonSES.html)
- Inference: at 10,000 small magic-link emails per month, the base send charge is about $1 before message data. This is far cheaper than provider subscription floors but shifts cost into setup, IAM, monitoring, and sandbox approval.

#### Postmark

- Verified fact: Free includes 100 emails every month, never expires, and permits no overage. Basic is $15 for 10,000, with $1.80 per additional 1,000. [Postmark pricing](https://postmarkapp.com/pricing/)
- Verified fact: one JSON endpoint and one server token send an email; a confirmed Sender Signature is mandatory. [Email API](https://postmarkapp.com/developer/api/email-api)
- Verified fact: Swoosh has a native Postmark adapter configured with one API key. [Swoosh Postmark adapter](https://swoosh.hexdocs.pm/Swoosh.Adapters.Postmark.html)
- Inference: Postmark is technically easy but its pricing step is too large for a product that only sends low-volume auth mail.

#### Mailgun

- Verified fact: Free includes 100 emails per day, one custom domain, API and SMTP, webhooks, and one day of logs. Basic is $15 for 10,000, with additional email from $1.80 per 1,000. [Mailgun pricing](https://www.mailgun.com/pricing/)
- Verified fact: Mailgun supports both HTTP and SMTP. Its basic HTTP call uses API credentials and multipart form fields. [HTTP sending guide](https://documentation.mailgun.com/docs/mailgun/user-manual/sending-messages/send-http)
- Verified fact: the Swoosh adapter needs both Plug and `multipart`; `multipart` is not currently a direct D20 dependency. [Swoosh Mailgun adapter](https://swoosh.hexdocs.pm/Swoosh.Adapters.Mailgun.html)
- Verified fact: Mailgun's documented domain flow presents SPF, DKIM, tracking, and receive-routing records and warns DNS propagation may take 24 to 48 hours. [Domain verification](https://documentation.mailgun.com/docs/mailgun/user-manual/domains/domains-verify)
- Inference: Mailgun is viable and familiar to Phoenix users, but it is not the smallest current D20 change or the cheapest path.

#### SMTP2GO

- Verified fact: Free provides 1,000 emails per month indefinitely. It has 200/day and, before domain verification, 25/hour limits. Sending pauses at the monthly cap. [Pricing and limits](https://www.smtp2go.com/pricing/), [billing FAQ](https://support.smtp2go.com/hc/en-gb/articles/20483715021081-Billing-Pricing-and-Plans-FAQ)
- Verified fact: the same pricing page rendered a 10,000-email Starter plan at $10 per month or $100 per year and $1 per 1,000 overage. The HTML title said "Plans From $15/mo", so this value needs confirmation at purchase. [SMTP2GO pricing](https://www.smtp2go.com/pricing/)
- Verified fact: sender-domain verification uses three CNAME records, and the JSON email API requires only sender, recipient array, subject, and an API key. [Sender verification](https://support.smtp2go.com/hc/en-gb/articles/9150216032537-Verified-Senders-Sender-Domain-vs-Single-Sender-Emails), [email API](https://developers.smtp2go.com/docs/send-an-email)
- Verified fact: Swoosh has a native API adapter. [Swoosh SMTP2GO adapter](https://swoosh.hexdocs.pm/Swoosh.Adapters.SMTP2GO.html)
- Inference: it is a credible fallback if provider account acceptance or regional considerations rule out Resend.

#### ZeptoMail

- Verified fact: the first credit permits 10,000 emails for one month. The public USD pricing page displays $2.50 per later 10,000-email credit, and paid credits expire after six months. [ZeptoMail pricing](https://www.zoho.com/zeptomail/pricing.html?src=pd-menu), [subscription rules](https://www.zoho.com/zeptomail/help/subscription.html)
- Verified fact: an account can begin at up to 100 sends per day, but purchases require review. Zoho says review normally takes two business days. [Initial sending](https://www.zoho.com/zeptomail/transition-guides/mailgun.html), [account review](https://help.zoho.com/portal/en/kb/zeptomail/faqs/sending-emails/articles/why-is-my-zeptomail-account-still-not-reviewed)
- Verified fact: domain verification needs DKIM TXT and CNAME records and can take 24 to 48 hours. [Domain verification](https://www.zoho.com/zeptomail/help/domains.html)
- Verified fact: Swoosh has a native ZeptoMail adapter configured with an API key and optional regional base URL. [Swoosh ZeptoMail adapter](https://swoosh.hexdocs.pm/Swoosh.Adapters.ZeptoMail.html)
- Verified fact: its terms permit transactional mail such as welcome and password-reset messages, but require every email to contain the sender entity's name and address, telephone number and email contact, plus abuse, postmaster, or legal contact information. [ZeptoMail terms](https://www.zoho.com/zeptomail/terms.html)
- Source caveat: the pricing page also carries a notice that pricing would change for signups from 2026-07-01, while its USD rendering still displays $2.50. Confirm the checkout price before selecting it.
- Inference: the credit model is unusually good for sporadic low volume, but review delay and mandatory message identity fields make it a less frictionless default than Resend.

## Phoenix and D20 integration context

- Verified fact: Phoenix has included Swoosh by default since Phoenix 1.6 and generates notifier support plus a local development mailbox. [Phoenix 1.6 announcement](https://www.phoenixframework.org/blog/phoenix-1.6-released)
- Repository fact: D20 locks Swoosh 1.27.0 and Req, and production already selects `Swoosh.ApiClient.Req`. The current generated runtime comment gives Mailgun as an example, not as a requirement or endorsement. [D20 dependency lock](../../mix.lock), [D20 production API client](../../config/prod.exs), [D20 generated mailer example](../../config/runtime.exs)
- Verified fact: current Swoosh documentation provides native adapters for every provider compared here. Resend, Brevo, Postmark, SMTP2GO, and ZeptoMail need only their adapter configuration plus the existing HTTP client. Mailgun adds `multipart`; Amazon SES adds `gen_smtp`. [Swoosh adapters and installation](https://swoosh.hexdocs.pm/Swoosh.html#module-adapters)
- Verified fact: Resend also publishes Elixir examples, including a Phoenix app, but labels its separate `resend` Hex library community-maintained. D20 should use the already-installed native Swoosh adapter instead of adding that library. [Resend Elixir guide](https://resend.com/docs/send-with-elixir), [native Swoosh Resend adapter](https://swoosh.hexdocs.pm/Swoosh.Adapters.Resend.html)
- Inference: changing only runtime mailer configuration to `Swoosh.Adapters.Resend`, reading a required `RESEND_API_KEY`, and preserving `Swoosh.ApiClient.Req` is the smallest provider integration. No new dependency is needed with D20's locked Swoosh version.

## Proposed selection rule

Use this rule at issue implementation time:

- Select **Resend** if forecast volume stays below both 80 emails/day and 2,400/month, leaving 20 percent alert headroom.
- Select **Brevo** if a permanent 300/day allowance is required and provider branding is acceptable.
- Select **Amazon SES** if forecast volume will make a subscription plan material and the team accepts AWS onboarding and IAM operations.
- Evaluate **ZeptoMail** only after confirming the current checkout price and confirming that D20 can satisfy its mandatory sender-information terms.
- Keep Postmark, Mailgun, and SMTP2GO as onboarding or deliverability fallbacks, not the initial price winner.

The volume thresholds above are D20 decision guardrails, not provider limits. They intentionally reserve headroom for retries, login bursts, and operator test messages.
