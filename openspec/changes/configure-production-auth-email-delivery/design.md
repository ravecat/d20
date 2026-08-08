## Context

`D20.Mailer` uses Swoosh, but the base configuration selects `Swoosh.Adapters.Local`, production does not override it, and `D20.Accounts.UserNotifier` builds every message with `contact@example.com`. Registration and login magic-link requests currently call the mailer inside the HTTP request. Registration converts an immediate adapter error into a recoverable state, while login intentionally returns a neutral response and ignores the delivery result.

The existing provider research selects Resend for the initial deployment. D20 already locks Swoosh 1.27 and Req, and that Swoosh version contains a native Resend adapter with provider idempotency support. Resend Free currently permits 3,000 transactional messages per month and 100 per day, requires a verified owned domain, supports send-only domain-scoped keys, retains idempotency keys for 24 hours, and exposes downstream delivery events in its dashboard.

Authentication email is security-sensitive. The existing `users_tokens` table stores only a hash of each email token because possession of the raw token grants account access. A durable queue must not weaken that property by persisting the raw token or complete magic-link URL in visible job arguments.

## Goals / Non-Goals

**Goals:**

- Deliver registration confirmation and login magic-link messages through Resend in production.
- Use `D20 <noreply@d20.ravecat.io>` as the first production sender and a monitored address as `Reply-To`.
- Establish a production-verified Resend baseline through the current synchronous delivery flow before adding a background queue.
- Keep provider calls outside the HTTP request lifecycle and persist jobs through application restarts.
- Bound concurrency, duplicate enqueueing, retry count, and retry duration below the magic-link validity window.
- Make retry payloads and provider idempotency keys stable without persisting raw authentication tokens in job arguments or logs.
- Fail production startup with an actionable message when the required provider secret is absent.
- Give operators correlation, terminal-failure visibility, quota alerts, verification steps, and a safe rollback procedure.

**Non-Goals:**

- Receiving or storing inbound email in D20.
- Running SMTP, IMAP, spam filtering, or another mail server on Hetzner.
- Adding marketing mail, mailing lists, provider-hosted templates, HTML email design, or open and click tracking.
- Adding a Resend webhook endpoint or application-owned downstream event store in the first release. Resend Dashboard owns delivered, bounced, complained, and suppressed visibility for this volume.
- Adding an administration UI for jobs or provider events.
- Changing the 15-minute magic-link lifetime, route shape, confirmation semantics, session rotation, or iframe contracts.
- Moving account email-change instructions to the queue. That path keeps the same provider-neutral notifier configuration and can be migrated separately.

## Decisions

### Use the native Resend Swoosh adapter

Production configures `D20.Mailer` with `Swoosh.Adapters.Resend`, a required `RESEND_API_KEY`, and the existing `Swoosh.ApiClient.Req`. No Resend SDK, SMTP client, or provider abstraction dependency is added. Development keeps the Local adapter and tests keep the Test adapter.

Checked-in application configuration defines the stable, non-secret message identities as `from: {"D20", "noreply@d20.ravecat.io"}` and `reply_to: {"D20 Support", "support@ravecat.io"}` under one auth-email configuration entry. Message construction reads those tuples from application configuration and sets both headers consistently for every auth message. The production environment contains only `RESEND_API_KEY`; changing either address requires a reviewed configuration change and deployment rather than production secret rotation.

Resend must verify `d20.ravecat.io` with its generated SPF and DKIM records, and the deployment must establish DMARC for that sending subdomain. Cloudflare DNS changes are declared and applied through the separate `infra` repository's Terraform configuration rather than edited in the Cloudflare dashboard. The Resend key uses Sending access restricted to `d20.ravecat.io`. The key is stored only in the production secret environment.

Alternative considered: use Resend SMTP. Rejected because the native HTTP adapter has fewer credentials and dependencies and supports provider idempotency directly.

Alternative considered: manage the Resend account and domain with the community Resend Terraform provider. Rejected for the initial production path because Resend does not publish an official Terraform provider; Resend owns account and domain creation, while the official Cloudflare provider in the `infra` repository owns all DNS changes.

Alternative considered: make `noreply@d20.ravecat.io` an inbox. Rejected because replies are deliberately redirected with `Reply-To`; the sender address itself needs only domain authorization. If `ravecat.io` DNS is already hosted by Cloudflare, Cloudflare Email Routing may forward the support alias to an existing mailbox. If another provider already owns the root-domain MX records, that provider handles the support alias instead.

### Stage Resend before adding Oban

Split delivery work into two ordered subtasks with separate production checkpoints.

The Resend baseline subtask configures the native adapter, required API key, checked-in sender identities, DNS authentication, reply routing, documentation, and focused tests while preserving the current synchronous Accounts and notifier behavior. Existing random magic-link token construction and controlled request-time delivery failures remain unchanged. This subtask is complete when registration and login messages are verified through the production Resend account and the current flow can be rolled back without a database migration.

The Oban reliability subtask starts only after that baseline is verified. It adds the queue dependency, database migration, worker, stable retry identity, asynchronous Accounts integration, telemetry, and queue-specific production verification. The second subtask reuses the already working Resend and DNS configuration instead of debugging provider onboarding and queue semantics simultaneously.

The two subtasks are separately deployable checkpoints within this OpenSpec change. The final requirements still describe the queued target state, so the change remains open until both subtasks are complete. If production experience shows that synchronous delivery is sufficient, removing the Oban subtask requires a deliberate scope and requirement update rather than leaving its tasks incomplete indefinitely.

Alternative considered: add Oban before the first real Resend send. Rejected because provider credentials, DNS authentication, sender policy, queue behavior, token identity, and retries would all change at once, making failures harder to isolate and rollback.

### Persist auth delivery with Oban Basic

Add the maintained open-source Oban dependency, its PostgreSQL jobs migration, an `emails` queue with concurrency `1`, and the Oban supervisor before the web endpoint. Test configuration uses Oban manual mode so tests can assert enqueueing and execute workers deterministically.

Registration creates the unconfirmed user first and then inserts one delivery job. An enqueue error preserves the account and returns the existing controlled recovery state. Login inserts a job only for an existing user and always returns the same neutral response, including when enqueueing fails. Provider calls never run in either request.

Job arguments contain only the user identifier and non-secret message kind, such as `confirmation` or `login`. They do not contain an email address, raw token, rendered URL, API key, or message body. Queue uniqueness considers the worker, user identifier, and message kind across incomplete jobs for the 15-minute token window. A completed or terminal job does not prevent an explicit later login request from creating a replacement message.

Alternative considered: start an unlinked task from the request. Rejected because task work is lost on restart and does not preserve terminal failures or controlled retries.

Alternative considered: persist the raw magic-link token in Oban arguments. Rejected because Oban jobs and their arguments are operator-visible database records and may appear in generic job logs.

### Derive one stable token per job without storing the raw value

The delivery worker derives the raw token deterministically from the Oban job id, user id, message context, and a domain-separated key derived from the Phoenix endpoint `secret_key_base`. It stores only the existing SHA-256 token hash and `sent_to` value in `users_tokens`. On retry, the worker derives the same raw token, finds the same token record, and reconstructs the same canonical production URL.

The job id is available only after persistent insertion. The secret-key derivation makes predictable job ids insufficient to predict tokens, and domain separation prevents reuse of the endpoint secret in another protocol. Rotating `SECRET_KEY_BASE` invalidates pending auth jobs along with other Phoenix-signed state, so the rollback runbook pauses and drains or replaces pending jobs before such a rotation.

Alternative considered: generate a new random token for every attempt. Rejected because the Resend idempotency key would then be reused with a different payload, producing a conflict, or each attempt would require a new idempotency key and could deliver duplicates after an ambiguous transport failure.

Alternative considered: add a separate encrypted delivery-outbox table. Rejected for the first release because deterministic derivation preserves the existing hash-only token storage property without another sensitive persistence model or encryption key lifecycle.

### Combine queue uniqueness with provider idempotency

Every attempt sets the Resend idempotency key to a versioned value derived from the stable job id, such as `auth-email/v1/<job-id>`. Swoosh sends it through `put_provider_option/3`. All retries of one job therefore submit the same recipient, subject, body, token URL, and idempotency key inside Resend's 24-hour retention window.

Queue uniqueness suppresses concurrent or repeated insertion of the same incomplete user and message-kind job for 15 minutes. Provider idempotency protects retries after timeouts or ambiguous API responses. These mechanisms solve different duplicate paths and are both required.

### Retry only recoverable provider failures within a short window

The worker has four total attempts with explicit backoff of 15, 60, and 180 seconds. The final attempt therefore occurs well inside the 15-minute token lifetime and the 24-hour provider idempotency window. The `emails` queue concurrency of one remains below Resend's default account rate limit.

Network failures, provider `5xx`, rate-limit responses, and concurrent-idempotency conflicts are retryable. Invalid credentials, unverified or rejected sender, invalid payload, exhausted daily or monthly quota, invalid-idempotency payload conflicts, bounce suppression reported at API time, and other configuration or policy errors are terminal. Error classification uses the Resend HTTP status and error type returned by the Swoosh adapter, not string matching against rendered messages.

Terminal jobs remain available for operator diagnosis. The Oban Pruner retains final jobs for seven days, which is acceptable for the expected low volume. Operators do not manually retry an expired auth job; the supported recovery is a fresh login magic-link request, which creates a new job and token.

### Split application telemetry from downstream provider visibility

D20 emits structured events and logs for enqueue accepted, enqueue failed, attempt started, provider accepted, retry scheduled, and terminal failure. Fields are limited to job id, message kind, attempt, normalized outcome, provider status or error type, and provider email id when accepted. Email addresses, user-entered values, raw tokens, URLs, bodies, API keys, and response payloads that may contain those values are excluded.

Oban supplies persistent job state and execution telemetry. Resend Dashboard supplies downstream `sent`, `delivered`, `bounced`, `complained`, and `suppressed` visibility and its provider-side retention. The provider email id logged after acceptance is the correlation key between the two systems. A webhook and local event table are deferred until automatic bounce handling or retention beyond the provider dashboard is justified.

Resend account notifications provide quota warnings at 80 percent and hard-limit notifications. The runbook also records the free-plan guardrails of 80 messages per day and 2,400 per month, leaving 20 percent for retries, tests, and bursts. Daily or monthly quota exhaustion is terminal for the current token and requires a later fresh request after capacity is restored or the account is upgraded.

## Risks / Trade-offs

- [A deterministic token design is security-sensitive] -> Domain-separate the derived key, keep the same 256-bit token strength, store only the token hash, add focused determinism and non-disclosure tests, and request security review before implementation completion.
- [A provider may accept a request while the client observes a timeout] -> Recreate the identical message and idempotency key for every retry.
- [Oban Basic uniqueness is insertion-oriented rather than a general concurrency lock] -> Keep queue concurrency at one, use incomplete-job uniqueness for duplicate requests, and rely on provider idempotency for repeated execution of one persisted job.
- [A job can fail after the HTTP response already promised an email] -> Preserve terminal job evidence, keep the neutral player-facing copy, and make a fresh login request the documented recovery path.
- [The support alias may conflict with existing root-domain MX records] -> Inspect current MX records before enabling Cloudflare Email Routing and use the existing mail provider when one already owns them.
- [The free daily limit can fail during a burst despite unused monthly allowance] -> Alert at 80 messages per day, serialize sends, document the hard limit, and upgrade or switch provider before expected bursts exceed the guardrail.
- [Seven-day Oban retention increases the jobs table] -> Expected free-tier volume leaves fewer than 700 final jobs in that window; retain pruning and review table size before increasing volume.
- [No webhook means D20 does not automatically react to later bounces or complaints] -> Use Resend Dashboard and suppression handling for the initial low volume, verify test recipients, and introduce signed webhook ingestion only when automation is required.

## Migration Plan

1. Create or confirm the Resend account, add `d20.ravecat.io`, declare the exact generated SPF and DKIM records in the `infra` repository's Terraform configuration, apply them to Cloudflare, and validate DMARC.
2. Create a Sending access API key restricted to `d20.ravecat.io`, store only that key in production secrets, and confirm the configured support alias forwards to a monitored mailbox.
3. Configure the Resend adapter and checked-in sender identities while preserving synchronous Accounts delivery, then run focused tests for success and controlled failure.
4. Deploy the Resend baseline without a database migration and verify registration and login messages, reply routing, SPF, DKIM, DMARC, provider visibility, quota notifications, and rollback.
5. Add Oban, its migration, test support, and the bounded `emails` queue without changing the verified provider configuration.
6. Add stable per-job token derivation, the delivery worker, error classification, idempotency, and telemetry.
7. Change registration and login requests to enqueue jobs, update focused tests, and document the new asynchronous success and failure semantics.
8. Deploy the Oban migration before the queue-enabled application release, start with the queue paused, verify runtime config, then enable and verify queued production delivery.

Rollback pauses the email queue first, preserves the `oban_jobs` table and pending jobs, then restores the prior application release or configures another Swoosh adapter with its runtime credentials. Do not run the Oban down migration during an application rollback. Resume or replace pending auth jobs only after confirming their tokens remain within the validity window.

## Open Questions

None. The checked-in reply address is `support@ravecat.io`; its forwarding destination remains an operational mailbox choice outside application configuration.
