## 1. Shared dialog behavior

- [x] 1.1 Extend the focused Header browser test to require the local mailbox link in both Register and Login modes while preserving the unavailable case.
- [x] 1.2 Render the existing local mailbox notice whenever `auth.local` is true, without gating it on the current mode or result state.
- [x] 1.3 Infer AuthDialog's mode parameter from the store transition and remove the standalone exported mode type.

## 2. Validation and delivery

- [x] 2.1 Run the focused Header browser test, frontend formatting check, lint, and typecheck.
- [x] 2.2 Run strict OpenSpec validation, sync the updated registration requirement, archive the change, and review the final diff.
