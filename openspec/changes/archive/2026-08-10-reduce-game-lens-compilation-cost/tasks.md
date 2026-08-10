## 1. Shared Private Lens Helper

- [x] 1.1 Extend `D20.GameTest` coverage for arbitrary map and struct fields, collection composition, and helper privacy.
- [x] 1.2 Replace the private `lens/1` macro injected by `D20.Game.__using__/1` with the private runtime helper while preserving automatic availability and existing engine call sites.

## 2. Validation

- [x] 2.1 Format the touched Elixir files and run the focused `D20.Game` and Koala aggregate tests.
- [x] 2.2 Run forced compiler profiling, record the Koala aggregate compilation time and BEAM size, and compare them with the pre-change baseline.
- [x] 2.3 Run the complete backend test suite and strict OpenSpec validation.
