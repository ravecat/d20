# Production Authentication Email

This runbook covers the synchronous Resend baseline. It does not include Oban,
background retries, a database migration, or inbound email hosting on the D20
server.

## Ownership and prerequisites

Before deployment, record the following operational ownership in GitHub issue
[#38](https://github.com/ravecat/d20/issues/38):

- the owner of the production Resend team;
- the mailbox that receives Resend quota and security notifications;
- the monitored destination behind the configured `Reply-To` address;
- the reviewer and operator for the Terraform DNS apply.

The application reads its `From` and `Reply-To` identities from checked-in
authentication email configuration. Do not duplicate their current addresses
in this runbook. The sender does not need a mailbox. Replies must reach the
monitored destination behind the configured `Reply-To` address.

## Resend account and domain

1. Use one production Resend team and select the Free transactional plan while
   expected traffic remains within the operating guardrails below.
2. Add the current sending domain managed by the `infra` repository. Do not
   duplicate its value in D20 documentation.
3. Copy every SPF, DKIM, and return-path record exactly as Resend generates it.
   Do not derive, shorten, or copy example values from documentation.
4. After Resend verifies SPF and DKIM, add DMARC for the sending subdomain.
   Start with a monitored `p=none` policy, verify `dmarc=pass` for every sender,
   then deliberately move to `quarantine` or `reject`.
5. Create an API key with Sending access restricted to the verified sending
   domain.
   Resend displays a new key only once.

Official references:

- [domain verification](https://resend.com/docs/dashboard/domains/introduction);
- [DMARC rollout](https://resend.com/docs/dashboard/domains/dmarc);
- [API key permissions and domain restriction](https://resend.com/docs/dashboard/api-keys/introduction);
- [key rotation](https://resend.com/docs/knowledge-base/how-to-handle-api-keys).

## Cloudflare DNS through Terraform

DNS for the current sending domain is managed in the separate `infra`
repository. D20 documentation intentionally does not duplicate the domain
value. Do not add or edit these records manually in the Cloudflare dashboard.
Create the Resend team, domain, and restricted key in Resend itself. The initial
production path does not add the community Resend Terraform provider; the
official Cloudflare provider remains the Terraform boundary.

1. Start from a clean, current checkout of `/home/max/apps/infra`.
2. In the Terraform Cloud `infra` workspace, create the non-sensitive HCL
   variable `resend_dns_records` and copy every exact Resend-generated MX, TXT,
   and optional CNAME record into the map documented by the infra repository.
   The checked-in `cloudflare_dns_record.resend` resource keeps all mail records
   unproxied and requires a priority for MX records.
3. Keep `d20_dmarc_rua` empty for the first apply. After Resend verifies SPF and
   DKIM, configure a DMARC aggregate-report destination, set this non-sensitive
   Terraform string variable to its complete `mailto:` URI, and apply again.
   The checked-in `cloudflare_dns_record.d20_dmarc` resource starts with
   `p=none`.
4. Inspect existing root-domain MX records before enabling Cloudflare Email
   Routing for the configured `Reply-To` address. If another provider owns
   those MX records, configure the alias there instead.
5. Run:

   ```sh
   terraform -chdir=terraform fmt -check -recursive
   terraform -chdir=terraform validate
   terraform -chdir=terraform plan
   ```

6. Review each plan, apply it through the established Terraform Cloud workflow,
   and restart domain verification in Resend after the first apply.
7. Compare public DNS with the exact records shown by Resend. DNS propagation
   can take time; do not replace generated values while propagation is pending.

The generated DNS values are not application secrets, but they still belong in
Terraform rather than `envs/.env` or D20 runtime configuration.

## Production secret and deployment

Store only the Resend key as `RESEND_API_KEY` in the Hetzner production secret
environment. Do not put the key in Git, Terraform state, `terraform.tfvars`,
container images, logs, or `envs/.env.example` values.

The new release fails before the Phoenix endpoint starts when the variable is
missing or blank. The error names `RESEND_API_KEY` and does not print its value.
No new database migration is required for this baseline.

Deploy the release with the existing production variables plus:

```text
RESEND_API_KEY=<domain-scoped send-only key>
```

Do not add environment variables for `From` or `Reply-To`; those identities are
reviewed application configuration.

## Acceptance check

Use controlled Gmail and Outlook accounts. Exercise all three messages:

1. register a new passwordless account and open its confirmation link;
2. request a login link for a confirmed account and log in;
3. request an account email change and open its confirmation link.

For each message, verify:

- visible sender matches the checked-in `From` identity;
- reply targets the checked-in `Reply-To` identity and reaches its monitored
  destination;
- full headers show `spf=pass`, `dkim=pass`, and `dmarc=pass` with aligned
  domains;
- the link uses the production HTTPS host, is valid once, and expires according
  to the existing authentication policy;
- the message contains no Resend branding or provider watermark;
- Resend Logs shows the request and downstream delivery result.

Do not paste API keys, raw magic-link tokens, full links, recipient addresses,
or message bodies into issue comments or operational logs.

## Failure behavior

The baseline sends synchronously in the HTTP request and performs no automatic
retry:

- registration keeps the unconfirmed account and token, then returns a flat
  recovery error when the provider rejects the request or times out;
- login keeps a neutral response for existing and unknown addresses even when
  delivery fails; an existing account's token remains stored;
- account email change retains its current behavior: the token is stored and the
  settings flow reports that a link was sent even if synchronous delivery fails.

The last item is a known limitation of the unchanged settings flow. Inspect
Resend Logs during acceptance and use a fresh request after correcting provider
configuration. Oban reliability work is responsible for persistent retries and
terminal failure visibility later.

Exercise these failures before sign-off:

- invalid API key;
- unverified or rejected sender;
- provider or network timeout;
- daily and monthly quota exhaustion;
- recovery through a fresh login-link request.

## Quotas and alerts

As of 2026-08-07, Resend documents a Free transactional quota of 100 messages
per day and 3,000 per month. D20 uses lower operating guardrails of 80 per day
and 2,400 per month to retain capacity for verification and bursts. Multiple
recipients and inbound messages also count toward quota.

Confirm that the Resend team sends its 80 percent and hard-limit notifications
to the recorded operator mailbox. Check the Usage page regularly. A free-plan
daily limit recovers after its documented window; a monthly limit requires the
next quota reset or a plan upgrade. Do not repeatedly retry a hard-limit error
inside the request lifecycle.

See [Resend account quotas](https://resend.com/docs/knowledge-base/account-quotas-and-limits)
and [usage-limit errors](https://resend.com/docs/api-reference/rate-limit).

## Key rotation

1. Create a replacement send-only key with the same domain restriction.
2. Update `RESEND_API_KEY` in the production secret environment and deploy.
3. Send one controlled authentication message and confirm the new key in Resend
   Logs.
4. Revoke the old key only after the new release is verified.

## Rollback

This baseline has no queue to pause and no migration to reverse. Prefer a
forward fix for a bad key or DNS record. If the release itself must be rolled
back, redeploy the previous application version and treat production
authentication email as unavailable until a working production adapter is
restored. The previous Local adapter does not deliver internet email and is not
a valid long-term production fallback.

Do not remove `RESEND_API_KEY` while this release is active because startup will
fail closed. Switching to another provider requires a reviewed Swoosh adapter
configuration and provider credential deployment; message construction remains
provider-neutral.
