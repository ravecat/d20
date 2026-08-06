## Why

Auth form failures are returned under a duplicated Inertia error-bag key after the Phoenix redirect, so the submitting form cannot display its field or recovery error. The account forms already use independent Inertia `Form` instances, making explicit error bags unnecessary and contrary to the form helper's standard error-scoping flow.

## What Changes

- Remove explicit Inertia error bags from registration, login, confirmation, and account-settings forms.
- Keep Phoenix controllers responsible for assigning flat changeset or field-error maps and redirecting back to the response page.
- Preserve independent processing, success, and error state through each submitting `Form` instance.
- Add server integration coverage for the final Inertia page response after redirect, plus focused browser coverage for user-visible registration and password errors.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `email-account-registration`: Registration validation and delivery failures must reach the submitting form as flat user-visible errors after the complete Inertia redirect.
- `email-account-login`: Independent auth-form state is provided by separate Inertia form instances without explicit error bags.

## Impact

- Affects shared and direct Svelte account forms plus focused auth controller and browser tests.
- Keeps existing routes, form payloads, Accounts behavior, sessions, database schema, and public account outcomes unchanged.
- Does not change dependencies or iframe module contracts.
- Rollback can restore explicit error bags, but would also restore duplicated redirect errors with the current Inertia Phoenix adapter.
- Tracks the unfinished account-registration acceptance boundary in GitHub issue #193.
