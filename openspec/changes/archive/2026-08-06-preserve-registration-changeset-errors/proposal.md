## Why

Registration currently replaces the changeset's duplicate-email validation message inside the controller. This makes the HTTP boundary own validation copy and prevents callers from receiving the error defined by the account changeset.

## What Changes

- Preserve translated registration changeset messages when assigning Inertia form errors.
- Keep only the transport-required conversion from each field's message list to one flat error value.
- Update duplicate-registration coverage to expect the changeset's `has already been taken` message.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `email-account-registration`: Duplicate and invalid registration responses preserve the account changeset's translated field messages instead of replacing duplicate-email feedback in the controller.

## Impact

- Affects the registration controller, its focused controller test, and the email registration specification.
- Duplicate registration now reveals that the email is already registered, matching the account changeset but reducing the previous neutral account-enumeration protection.
- No route, schema, migration, session, runtime, iframe contract, or dependency changes are required.
- Rollback restores the controller-specific duplicate-email replacement and its previous test expectation.
