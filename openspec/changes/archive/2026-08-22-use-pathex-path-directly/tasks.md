## 1. Shared and Koala Paths

- [x] 1.1 Remove the private `lens/1` helper from `D20.Game` and replace active Koala aggregate calls with direct `path/1` expressions.
- [x] 1.2 Remove Pathex traversal mechanics from `D20.GameTest` while preserving D20-owned callback, server, preview, changeset, and initialization coverage.

## 2. Next Station Aggregate Mutations

- [x] 2.1 Rewrite setup join, leave, start, first-round assignment, and reveal commits through Pathex field, keyed-player, and collection paths.
- [x] 2.2 Rewrite player action, instruction advancement, round advancement, finish, deck consumption, draw history, and uniform player status transitions through Pathex paths, removing the map-rebuild status helper.

## 3. Validation

- [x] 3.1 Confirm active Elixir sources contain no `lens/1` calls and Next Station transition helpers contain no replaced direct mutation forms, then format touched Elixir files.
- [x] 3.2 Run focused `D20.Game`, Koala aggregate, and Next Station aggregate tests followed by warnings-as-errors compilation and the complete backend suite.
- [x] 3.3 Synchronize all capability deltas and strictly validate OpenSpec.
