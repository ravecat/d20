## 1. Finished Session Discovery

- [x] 1.1 Update focused WorkspaceChannel regression tests to cover accepted and automatic transitions to `finished` plus restoration on a new Workspace join.
- [x] 1.2 Extend `D20Web.Workspace.snapshot/1` eligibility to live configured `in_progress` and `finished` Sessions while preserving durable-membership and exclusion rules.
- [x] 1.3 Cover explicit close of a finished Session and verify that it removes the actor's descriptor without stopping the shared runtime.

## 2. Public Contract

- [x] 2.1 Update the Workspace AsyncAPI description to report live in-progress and finished Sessions and allow either phase through the existing close operation.
- [x] 2.2 Confirm that Workspace event names, descriptor fields, connection data, errors, and frontend reconciliation require no schema or client changes.

## 3. Validation

- [x] 3.1 Format the touched Elixir files and run `mix test test/d20_web/channels/workspace_channel_test.exs test/d20_web/plugs/async_api_test.exs`.
- [x] 3.2 Run strict OpenSpec validation for `keep-finished-sessions-in-workspace`.
- [x] 3.3 Run the full backend suite with `mix test` and report any remaining volatile-runtime limitation.
