## Why

D20 currently keeps authentication email in the local Swoosh mailbox and constructs messages with the placeholder sender `contact@example.com`, so production registration and magic-link login cannot deliver usable messages. The provider integration must be deployable and verifiable with the current synchronous flow before background delivery, retries, and persistent failure handling are introduced as a separate reliability subtask.

## What Changes

- Select Resend as the initial production transactional email provider through the native Swoosh HTTP adapter and the existing Req API client.
- Send authentication messages from `D20 <noreply@d20.ravecat.io>` and direct human replies to a separately monitored support address; the `noreply` sender itself does not require an inbox.
- Keep the stable sender and reply addresses in checked-in application configuration, require only the Resend API key from the production environment, and preserve the Swoosh Local and Test adapters outside production.
- Deliver and verify Resend first through the current request-coupled Accounts and notifier flow without adding a queue or changing token construction.
- Add Oban in a separate follow-up subtask, then move registration and login magic-link delivery outside the request lifecycle with persistent jobs, bounded concurrency, bounded retry and backoff, stable provider idempotency, and controlled duplicate enqueueing.
- Keep magic-link material out of persisted job arguments and operational logs while making every retry of one job reproduce the same message and provider idempotency key.
- Emit structured delivery outcomes that correlate an application job with the provider message without logging the recipient, magic link, or API credential.
- Preserve terminal failures for operator diagnosis and keep the existing login magic-link request as the player recovery path.
- Document Resend account creation, Terraform-managed Cloudflare DNS verification, monitored reply routing, quota alerts, production verification, hard-limit recovery, and provider rollback.

## Capabilities

### New Capabilities

- `production-auth-email-delivery`: Define a staged production provider baseline followed by persistent delivery jobs, retries, idempotency, observability, verification, and operational recovery.

### Modified Capabilities

- `email-account-registration`: Treat successful persistent enqueueing as registration request success and make enqueue failure recoverable without waiting for provider delivery.
- `email-account-login`: Queue existing-account magic-link instructions while preserving the same neutral response for existing and unknown email addresses.

## Impact

- Tracks [GitHub issue #38](https://github.com/ravecat/d20/issues/38) and uses the existing provider decision in `docs/research/production-auth-email-provider.md`.
- Affects Accounts orchestration, token construction, the Swoosh notifier and mailer configuration, the OTP supervision tree, authentication controllers, telemetry, focused tests, runtime environment documentation, and deployment operations.
- Adds a maintained PostgreSQL-backed job dependency and its database migration; no public game, channel, iframe, or session contract changes.
- Separates provider onboarding from queue adoption so the Resend baseline can be deployed, tested, and rolled back without an Oban migration.
- Requires a Resend account, DNS write access for `ravecat.io`, a send-only domain-scoped production API key, and a monitored destination mailbox. It does not require an SMTP or IMAP server on Hetzner.
- Rollback pauses the mail queue, preserves queued jobs for diagnosis, and restores the previous runtime adapter and credentials without changing authentication email construction.
