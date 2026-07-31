## 1. Automatic Turn Completion

- [x] 1.1 Rewrite final and non-final `maybe_finish/1` aggregate access through field and collection lenses and remove `set_player_statuses/2`.

## 2. Validation

- [x] 2.1 Format `Game`, run the focused Koala aggregate test module, and confirm non-final advancement and final scoring behavior.
- [x] 2.2 Compile with warnings treated as errors and inspect the focused diff for unintended scoring, badge, or contract changes.
- [x] 2.3 Run strict OpenSpec validation for `route-koala-turn-advancement-through-lenses`.
