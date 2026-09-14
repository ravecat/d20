## 1. Scoring and contract

- [x] 1.1 Add complete interchange category points and derive the existing aggregate from them.
- [x] 1.2 Require the complete map in AsyncAPI and cover rules, projections, and channel serialization.

## 2. Validation and reconciliation

- [x] 2.1 Run targeted Mix rules, projection, and London channel tests and format touched Elixir files.
- [x] 2.2 Synchronize and archive the scoped change, run strict OpenSpec validation, and reconcile tracking evidence.

Validation: `ERL_FLAGS="+S 2:2" mix test test/d20/next_station_london/rules_test.exs test/d20/next_station_london/projection_test.exs test/d20_web/channels/session_channel_test.exs:444` passed 21 tests (12 excluded). Touched Elixir files formatted with `mix format`. Local HTTP GET returned 200 after development code reload; no runtime restart was performed. Client acceptance is owned by the separate client repository.

Live client verification: the finished game displayed counts 8/1/0, category points 16/5/0, interchange total 21, and final total 121. Browser DOM and screenshot checks passed without console errors or automated gameplay actions.
