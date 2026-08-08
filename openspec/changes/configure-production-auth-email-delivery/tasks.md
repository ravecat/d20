## 1. Resend Baseline - Account, DNS, And Replies

- [ ] 1.1 Create or confirm one Resend account and select the Free transactional plan while expected volume remains below 80 messages per day and 2,400 per month.
- [ ] 1.2 Add `d20.ravecat.io` as the Resend sending domain, declare its exact generated SPF and DKIM records in the separate `infra` repository's Terraform configuration, and apply them to Cloudflare.
- [ ] 1.3 Declare DMARC for the sending subdomain in the `infra` repository's Terraform configuration, apply it after SPF and DKIM verification succeeds, and validate the resulting policy.
- [ ] 1.4 Create a Resend Sending access API key restricted to `d20.ravecat.io` and store only `RESEND_API_KEY` in the Hetzner production secret environment.
- [ ] 1.5 Create or confirm a monitored destination for the configured `support@ravecat.io` alias; manage Cloudflare Email Routing through the `infra` Terraform configuration only if no existing root-domain MX provider should handle the alias.
- [ ] 1.6 Configure Resend account notifications for 80 percent and hard-limit quota events and identify the monitored operator mailbox.

## 2. Resend Baseline - Current Phoenix Delivery Flow

- [x] 2.1 Replace the generated production mailer comment with runtime Resend configuration through `Swoosh.Adapters.Resend` and the existing Req API client.
- [x] 2.2 Require only `RESEND_API_KEY` in production with a missing-variable error that never exposes configured values.
- [x] 2.3 Define `from: {"D20", "noreply@d20.ravecat.io"}` and `reply_to: {"D20 Support", "support@ravecat.io"}` in provider-neutral checked-in application configuration while preserving Local and Test adapters outside production.
- [x] 2.4 Update `D20.Accounts.UserNotifier` to use the configured sender identities while retaining the current synchronous `Mailer.deliver/1` boundary and existing random token construction.
- [x] 2.5 Keep registration delivery errors controlled and login responses neutral when the direct provider request fails or times out, without adding automatic request-time retries.
- [x] 2.6 Keep account email-change delivery behavior provider-neutral and unchanged, and confirm that it receives the configured sender and reply headers.
- [x] 2.7 Update `envs/.env.example` and README runtime-variable documentation with only `RESEND_API_KEY`, without reading or editing `envs/.env`.
- [x] 2.8 Add focused configuration, notifier, Accounts, and controller tests for direct Resend success, missing key, configured headers, provider failure, timeout, neutral login response, and absence of an Inertia HTML error dialog.

## 3. Resend Baseline - Production Verification Checkpoint

- [x] 3.1 Format the Resend baseline Elixir files with `mix format <files>` and run its focused configuration, notifier, Accounts, and controller tests.
- [x] 3.2 Run `mix compile --warnings-as-errors`, `mix test`, and `just check`, resolving only failures caused by the Resend baseline.
- [ ] 3.3 Deploy the Resend baseline without an Oban dependency or database migration and verify startup with only `RESEND_API_KEY` added to the existing production environment.
- [ ] 3.4 Deliver registration confirmation, login magic-link, and account email-change messages to controlled Gmail and Outlook recipients and verify visible sender, `Reply-To`, SPF, DKIM, DMARC, link validity, and absence of provider branding.
- [ ] 3.5 Exercise invalid-key, rejected-sender, provider timeout, daily or monthly quota, controlled registration recovery, neutral login response, and provider rollback without exposing production secrets or tokens.
- [x] 3.6 Document account ownership, DNS checks, secret rotation, Resend event inspection, free-tier resets and hard limits, current synchronous failure behavior, and provider rollback in a production mail runbook.
- [ ] 3.7 Record the separately deployable Resend baseline evidence in GitHub issue #38 before beginning the Oban subtask.

## 4. Oban Reliability - Persistent Queue Foundation

- [ ] 4.1 Add the maintained Oban dependency, update the lockfile, and add an Oban migration with reversible `up` and `down` callbacks.
- [ ] 4.2 Configure Oban Basic with PostgreSQL, an `emails` queue concurrency of one, seven-day final-job retention, and manual test mode.
- [ ] 4.3 Start Oban under `D20.Application` before `D20Web.Endpoint` and add focused configuration and supervision coverage.
- [ ] 4.4 Add Oban testing helpers to the nearest existing data and controller test support without changing unrelated test isolation.

## 5. Oban Reliability - Stable Message Worker

- [ ] 5.1 Extend `D20.Accounts.UserToken` with domain-separated deterministic token derivation from job id, user id, and message context while retaining SHA-256-only token persistence.
- [ ] 5.2 Add focused tests proving stable reconstruction for one job, separation across jobs and contexts, compatibility with existing token verification, and absence of raw token persistence.
- [ ] 5.3 Centralize canonical registration confirmation and login magic-link URL construction outside controller callbacks without changing the public route shape or 15-minute validity.
- [ ] 5.4 Add a dedicated Oban authentication email worker whose persisted arguments contain only user id and message kind and whose incomplete-job uniqueness window is 15 minutes.
- [ ] 5.5 Reuse or insert the stable token record, build the same message on every retry, and set a versioned Resend idempotency key derived from the Oban job id.
- [ ] 5.6 Implement four total attempts with 15, 60, and 180 second backoff and classify Resend status and error types into retryable and terminal outcomes.
- [ ] 5.7 Ensure terminal or expired jobs remain diagnosable and require a fresh login magic-link request rather than manual delivery of an expired token.
- [ ] 5.8 Add worker tests for success metadata, ambiguous retry identity, transient errors, permanent errors, quota exhaustion, uniqueness, maximum attempts, and restart-safe persisted execution.

## 6. Oban Reliability - Accounts Integration

- [ ] 6.1 Change registration orchestration to persistently enqueue confirmation delivery after creating the account and preserve the current controlled recovery state when enqueueing fails.
- [ ] 6.2 Change existing-account login magic-link requests to enqueue delivery without making a provider call in the HTTP request and preserve neutral output for unknown addresses and enqueue failures.
- [ ] 6.3 Update Accounts and controller tests to assert queued work, no synchronous provider call, no duplicate incomplete jobs, registration recovery, neutral login responses, and no Inertia HTML error dialog after asynchronous failure.
- [ ] 6.4 Confirm that the Oban transition does not change the separately verified Resend adapter, sender identities, DNS requirements, or account email-change behavior.

## 7. Oban Reliability - Telemetry And Data Safety

- [ ] 7.1 Emit structured enqueue, attempt, accepted, retry, and terminal outcomes with job id, message kind, attempt, normalized provider result, and provider email id where available.
- [ ] 7.2 Attach focused telemetry or logger handling through the existing D20 telemetry boundary and verify final jobs remain queryable for seven days.
- [ ] 7.3 Add tests proving recipient addresses, user-entered values, raw tokens, complete magic-link URLs, bodies, credentials, and unfiltered provider payloads never appear in job args or emitted operational metadata.
- [ ] 7.4 Verify accepted job ids can be correlated with Resend provider email ids and retain Resend Dashboard as the downstream bounce, complaint, and suppression boundary.

## 8. Oban Reliability - Production Verification And Completion

- [ ] 8.1 Format the Oban subtask Elixir files with `mix format <files>` and run focused queue, worker, Accounts, telemetry, runtime configuration, and controller tests.
- [ ] 8.2 Run `mix compile --warnings-as-errors`, `mix test`, and `just check`, resolving only failures caused by the Oban subtask.
- [ ] 8.3 Deploy the Oban migration before the queue-enabled release, start with the email queue paused, verify the existing Resend runtime configuration, and then enable the queue.
- [ ] 8.4 Re-run registration and login delivery to controlled Gmail and Outlook recipients and verify queue persistence, retry idempotency, sender headers, provider correlation, and recovery after a simulated application restart.
- [ ] 8.5 Exercise transient retry, terminal failure, duplicate enqueue, token expiry, fresh-request recovery, queue pause, and application rollback without exposing production secrets or tokens.
- [ ] 8.6 Update the production mail runbook with queue pause and resume, job inspection, seven-day retention, expired-job handling, migration ordering, and rollback without dropping `oban_jobs`.
- [ ] 8.7 Run `openspec validate configure-production-auth-email-delivery --strict --no-interactive` and `openspec validate --all --strict --no-interactive`.
- [ ] 8.8 Update GitHub issue #38 with both checkpoint results, complete every acceptance criterion, then archive this OpenSpec change and confirm it no longer appears in `openspec list --json`.
