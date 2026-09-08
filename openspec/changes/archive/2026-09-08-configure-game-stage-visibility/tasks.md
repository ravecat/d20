## 1. Configure and apply stage policy

- [x] 1.1 Set the released-only default and development stage override; remove the environment-identity key.
- [x] 1.2 Replace all `visible_stages/0` calls with direct runtime configuration reads and remove the helper, preserving explicit listing filters and existing-Session access.

## 2. Verify policy behavior

- [x] 2.1 Adapt context, page, and module tests to stage-list configuration and verify empty-policy and existing-Session cases; characterize failure before the production edit.
- [x] 2.2 Run touched-file formatting, warnings-as-errors compilation, focused tests, full backend tests, and touched-file strict Credo; verify resolved dev/test/prod configuration and absence of environment checks in application code.

## 3. Reconcile delivery records

- [x] 3.1 Record verification and reconcile the linked issue for this approved configuration step; keep the broader API-discovery issue open. Native specification synchronization, archival, and strict lifecycle validation remain the completion gates in the design.
