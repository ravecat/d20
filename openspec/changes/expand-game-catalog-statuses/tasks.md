## 1. Registry and Catalog Data

- [x] 1.1 Extend registry entries with optional status and conditional engine/sandbox validation.
- [x] 1.2 Add the requested game BGG bindings and assign Qwinto active and Koala Rescue Club in-progress statuses.
- [x] 1.3 Add registry tests for the expanded list, supported statuses, inactive entries, and invalid launchable bindings.

## 2. Metadata and Launch Policy

- [x] 2.1 Add batch BGG detail fetching and use it for catalog resolution while preserving single-game detail lookup.
- [x] 2.2 Add status to catalog records and implement environment-aware session launch policy.
- [x] 2.3 Update game context, BGG adapter, and controller tests for batching, statuses, inactive detail access, and launch denial.
- [x] 2.4 Make `D20.Games.list/0` return stable availability order with active games first, in-progress games second, and inactive games last while keeping the listing flow in one `with` block.
- [x] 2.5 Update game-context and page-controller tests to assert backend and serialized catalog ordering.

## 3. Home and Detail UI

- [x] 3.1 Extend TypeScript game props with catalog status and detail launch availability.
- [x] 3.2 Render active cards prominently, mute other cards, and add the in-progress badge without disabling detail navigation.
- [x] 3.3 Hide session creation controls when launch is unavailable while preserving detail metadata and existing-session rendering.
- [x] 3.4 Update Svelte tests for card states, badges, links, and detail launch controls.
- [x] 3.5 Render availability-ordered home cards and replace the visible in-progress badge copy with `Soon`.
- [x] 3.6 Add Svelte coverage for catalog order and the `Soon` badge.
- [x] 3.7 Remove client-side catalog regrouping so the home page preserves backend order, and render unboxed game titles over a subtle left-side scrim.
- [x] 3.8 Update Svelte coverage to assert received-order rendering and the revised title structure.

## 4. Validation

- [x] 4.1 Run targeted Elixir registry, metadata, context, and page-controller tests.
- [x] 4.2 Run frontend format, type checks, and targeted page tests.
- [x] 4.3 Verify active, in-progress, inactive, and production-disabled states in the browser and run repository diff checks.
- [x] 4.4 Run frontend formatting, type checks, targeted page tests, browser verification at desktop and mobile widths, and OpenSpec strict validation for the ordering update.
- [x] 4.5 Run targeted Elixir and Svelte tests, formatting and type checks, desktop and mobile browser verification, repository diff checks, and OpenSpec strict validation for backend ordering and title presentation.
