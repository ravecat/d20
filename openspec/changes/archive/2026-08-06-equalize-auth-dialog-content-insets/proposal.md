## Why

The account content scroller permanently reserves a scrollbar gutter on its inline end, so non-scrolling dialog content has a larger visible right inset than left inset. This breaks the dialog-owned alignment contract and makes fields, actions, separators, and provider rows look shifted.

## What Changes

- Stop reserving scrollbar space when account dialog content does not overflow.
- Verify that the email field uses equal left and right insets at a desktop viewport.
- Preserve viewport-constrained scrolling and reachability when Login mode actually overflows.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `email-account-login`: Clarify that non-scrolling account content uses equal inline insets without a reserved scrollbar gutter.

## Impact

- Affects one shared account panel style and its focused browser coverage.
- Does not change markup, forms, focus behavior, Phoenix routes, account or session semantics, dependencies, database schemas, migrations, or iframe contracts.
- Rollback restores the permanent gutter declaration, including its asymmetric non-scrolling inset.
