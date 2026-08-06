## Context

`Accounts.register_user_with_magic_link/2` returns an Ecto changeset for invalid and duplicate email submissions. The registration controller translates that changeset, flattens each field's list to one Inertia error value, and additionally replaces the duplicate-email message with controller-owned copy. The account changeset already defines `has already been taken`, and nearby Accounts tests treat it as the authoritative duplicate-email error.

## Goals / Non-Goals

**Goals:**

- Preserve changeset ownership of registration validation messages.
- Keep the flat error shape required by Inertia forms.
- Cover the externally observed duplicate-email message at the controller boundary.

**Non-Goals:**

- Change email validation, uniqueness constraints, translation, registration delivery, or form presentation.
- Introduce an application-wide changeset serializer.
- Preserve neutral duplicate-email feedback or account-enumeration resistance at registration.

## Decisions

### Flatten messages without field-specific rewriting

`registration_errors/1` will translate the changeset and select the first message for every field with one uniform mapping. This retains the existing Inertia error shape while leaving message choice to the changeset and translation layer.

Moving the replacement message into the changeset was rejected because the requested behavior is to return the changeset's existing natural error. Returning message lists unchanged was rejected because the current Inertia forms consume one string per field.

### Assert the boundary message in the controller test

The duplicate-registration controller test will expect `has already been taken`. Existing Accounts tests already cover uniqueness and the changeset message, while the controller test verifies that the HTTP boundary no longer rewrites it.

## Risks / Trade-offs

- [Duplicate feedback reveals account existence] -> The behavior is explicit in the updated specification and limited to registration. Login continues using neutral credential and magic-link responses.
- [Selecting only the first message omits additional field errors] -> Preserve the established flat Inertia contract; changing it requires a separate form-error shape decision.
- [Translated changeset copy can change with validation or locale changes] -> Treat that as changeset and translation ownership rather than duplicating copy in the controller.

## Migration Plan

1. Remove the duplicate-email branch and helper from the registration controller.
2. Update the focused controller assertion.
3. Run formatter and focused controller tests.

Rollback restores the field-specific controller branch and prior neutral test expectation. No data or deployment migration is required.

## Open Questions

None.
