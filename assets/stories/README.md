# Story conventions

- Keep stories under `assets/stories/` and group them by the production UI boundary they exercise.
- Import production components through the `~` alias. Do not copy production markup into story-only components.
- Use typed CSF3 `Meta` and `StoryObj` definitions with deterministic args that describe a complete component state.
- Put data shared by multiple stories under `assets/stories/fixtures/`. Fixtures must not depend on clocks, randomness, mutable backend state, or environment-specific identifiers.
- Replace connected dependencies at their module boundary with deterministic Storybook mocks. Stories must not open Phoenix channels, submit Inertia forms, start workspace transports, or load external game iframes.
- Use Storybook for isolated visual, viewport, controls, docs, and accessibility review. Keep automated behavior coverage in the existing Vitest unit and browser suites until Storybook browser testing is added explicitly.
