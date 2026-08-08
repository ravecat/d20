## ADDED Requirements

### Requirement: Production authentication email uses a verified Resend sender

The production system SHALL deliver registration confirmation and login magic-link messages through `Swoosh.Adapters.Resend` using the configured Swoosh Req API client. Checked-in application configuration SHALL define `D20 <noreply@d20.ravecat.io>` as the sender and `D20 Support <support@ravecat.io>` as `Reply-To`; neither address SHALL be required from the runtime environment. The support alias SHALL forward to a monitored destination, while the `noreply` sender itself MUST NOT require an inbound mailbox. Development SHALL retain the Local adapter and tests SHALL retain the Test adapter.

#### Scenario: Production builds a confirmation message

- **WHEN** the production delivery worker builds a registration confirmation message
- **THEN** its sender is `D20 <noreply@d20.ravecat.io>`
- **AND** its `Reply-To` is `D20 Support <support@ravecat.io>` from application configuration
- **AND** delivery uses the Resend HTTP adapter through Req

#### Scenario: User replies to an authentication message

- **WHEN** an email client honors the authentication message `Reply-To` header
- **THEN** the reply is addressed to the monitored support address
- **AND** no inbox is required for `noreply@d20.ravecat.io`

#### Scenario: Development previews authentication email

- **WHEN** D20 runs in development with the Local adapter
- **THEN** authentication messages remain available through the existing local mailbox
- **AND** no Resend credential is required

### Requirement: Production mail configuration fails closed

Production startup SHALL require only a non-empty Resend API key for authentication email before starting the endpoint or email queue. The stable sender and reply addresses SHALL be defined in checked-in application configuration and MUST NOT be required as environment variables. The Resend API key SHALL have Sending access restricted to the verified `d20.ravecat.io` domain and MUST be supplied only through production secret configuration. A startup error SHALL name `RESEND_API_KEY` without exposing any configured value.

#### Scenario: Required mail secret is absent

- **WHEN** production starts without `RESEND_API_KEY`
- **THEN** startup fails before accepting HTTP requests or processing email jobs
- **AND** the error identifies `RESEND_API_KEY` as missing
- **AND** the error does not include any other secret value

#### Scenario: Production mail configuration is complete

- **WHEN** production starts with `RESEND_API_KEY` and the checked-in sender and reply configuration
- **THEN** the mailer selects the Resend adapter
- **AND** the persistent email queue can process jobs

### Requirement: Authentication delivery is persistent and request-independent

Registration confirmation and login magic-link provider calls SHALL run in a PostgreSQL-backed email queue outside the HTTP request process. A delivery job SHALL survive an application restart, SHALL contain only the target user identifier and non-secret message kind in its persisted arguments, and MUST NOT persist the recipient address, raw authentication token, rendered magic-link URL, API key, subject, or body in its job arguments. The queue SHALL process at most one authentication email job concurrently.

#### Scenario: Existing user requests a magic link

- **WHEN** the login action accepts a magic-link request for an existing user
- **THEN** it persistently enqueues an authentication delivery job
- **AND** it returns without waiting for a provider API call
- **AND** the persisted job arguments contain no email address, raw token, magic-link URL, API key, subject, or body

#### Scenario: Application restarts after enqueueing

- **WHEN** an authentication delivery job is persisted and the application restarts before execution
- **THEN** the restarted email queue can execute the same job
- **AND** the HTTP request that created the job does not need to be repeated

### Requirement: Job retries reproduce one safe authentication message

Each authentication delivery job SHALL derive one stable raw token from its job identity and domain-separated application secret, SHALL store only the token hash in the existing authentication token store, and SHALL reconstruct the same recipient, subject, body, magic-link URL, and versioned provider idempotency key on every retry. The raw token and complete URL MUST NOT appear in persisted job arguments, telemetry metadata, or logs. Duplicate enqueueing SHALL be constrained across incomplete jobs for the same user and message kind during the 15-minute magic-link validity window.

#### Scenario: Provider response is ambiguous

- **WHEN** the first provider attempt ends with an ambiguous transport failure and the job retries
- **THEN** the retry uses the same raw token and magic-link URL
- **AND** the retry uses the same Resend idempotency key
- **AND** the raw token remains absent from job arguments and logs

#### Scenario: Equivalent incomplete job already exists

- **WHEN** another request attempts to enqueue the same user's message kind while an equivalent job remains incomplete inside the uniqueness window
- **THEN** the queue retains one effective incomplete delivery request
- **AND** it does not create uncontrolled duplicate provider sends

#### Scenario: User requests a replacement after terminal failure

- **WHEN** the earlier job has reached a terminal state and the user makes a fresh supported login magic-link request
- **THEN** the system may enqueue a new job with a new job identity, token, and provider idempotency key

### Requirement: Delivery retries are bounded and classified

The authentication email worker SHALL make at most four attempts. Retry backoff SHALL be 15 seconds before the second attempt, 60 seconds before the third attempt, and 180 seconds before the fourth attempt, so all automatic attempts occur within the 15-minute magic-link validity period and Resend's idempotency retention period. Network failures, provider server failures, rate-limit responses, and concurrent-idempotency responses SHALL be retryable. Invalid credentials, rejected or unverified sender, invalid payload, exhausted daily or monthly quota, invalid-idempotency payload conflict, and other configuration or policy failures SHALL be terminal.

#### Scenario: Provider is temporarily unavailable

- **WHEN** Resend or the network reports a classified transient failure
- **THEN** the job is scheduled with the bounded backoff for its next available attempt
- **AND** the worker never exceeds four total attempts

#### Scenario: Production key is rejected

- **WHEN** Resend rejects the configured API key
- **THEN** the job enters a terminal state without futile automatic retries
- **AND** the failure is available for operator diagnosis

#### Scenario: Free-plan quota is exhausted

- **WHEN** Resend reports daily or monthly quota exhaustion
- **THEN** the current job enters a terminal state
- **AND** recovery requires restored capacity and a fresh user magic-link request

### Requirement: Authentication delivery is observable without sensitive data

The system SHALL emit structured operational outcomes for enqueue acceptance, enqueue failure, attempt start, provider acceptance, retry scheduling, and terminal failure. Operational fields SHALL be limited to job id, message kind, attempt, normalized outcome, provider status or error type, and provider email id when accepted. The system MUST NOT log recipient addresses, user-entered values, raw tokens, complete magic-link URLs, message bodies, API keys, or unfiltered provider response bodies. Final queue jobs SHALL remain available for seven days, and the logged provider email id SHALL correlate an accepted job with Resend Dashboard delivery, bounce, complaint, and suppression visibility.

#### Scenario: Resend accepts a message

- **WHEN** Resend returns a provider email id
- **THEN** D20 records the job id, message kind, accepted outcome, attempt, and provider email id
- **AND** the record contains no recipient address, raw token, complete URL, body, or credential

#### Scenario: Delivery reaches terminal failure

- **WHEN** a job exhausts retries or receives a terminal provider error
- **THEN** the terminal job and normalized failure remain diagnosable for seven days
- **AND** logs contain no sensitive message material

### Requirement: Production delivery has a verified operating procedure

The production runbook SHALL record Resend and DNS account prerequisites, exact generated SPF and DKIM record handling, DMARC validation, send-only domain-scoped key creation, the `RESEND_API_KEY` production secret, checked-in sender and reply configuration, queue pause and resume, Gmail and Outlook delivery checks, reply routing, quota guardrails, hard-limit recovery, provider event inspection, and rollback. Production acceptance SHALL include delivered registration and login messages to controlled Gmail and Outlook recipients with passing SPF, DKIM, and DMARC alignment. Resend account notifications SHALL alert operators at 80 percent of applicable quota, and D20 SHALL treat 80 messages per day and 2,400 messages per month as free-tier operating guardrails.

#### Scenario: Operator prepares production mail

- **WHEN** an operator follows the production runbook
- **THEN** the operator can create or access the Resend account, verify `d20.ravecat.io`, create and configure the restricted production key, confirm the checked-in addresses, and route replies without an SMTP or IMAP server on Hetzner

#### Scenario: Production verification succeeds

- **WHEN** registration and login messages are sent to controlled Gmail and Outlook accounts
- **THEN** both message kinds are delivered
- **AND** their headers pass SPF, DKIM, and DMARC alignment
- **AND** replying selects the monitored support address

#### Scenario: Usage approaches a free-tier limit

- **WHEN** Resend usage reaches 80 percent of an applicable daily or monthly quota
- **THEN** the configured Resend account notification alerts an operator
- **AND** the runbook identifies whether to wait for reset, reduce sending, upgrade, or switch provider before the hard limit

#### Scenario: Production provider must be rolled back

- **WHEN** the Resend integration must be disabled or replaced
- **THEN** the operator pauses the email queue before changing adapter configuration and credentials
- **AND** pending and terminal job records are preserved
- **AND** authentication email construction does not require a provider-specific rewrite
