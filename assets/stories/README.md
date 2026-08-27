# Story conventions

- Keep stories under `assets/stories/` and group them by the production UI boundary they exercise.
- Import production components through the `~` alias. Do not copy production markup into story-only components.
- Use typed CSF3 `Meta` and `StoryObj` definitions with deterministic args that describe a complete component state.
- Put data shared by multiple stories under `assets/stories/fixtures/`. Fixtures must not depend on clocks, randomness, mutable backend state, or environment-specific identifiers.
- Replace connected dependencies at their module boundary with deterministic Storybook mocks. Stories must not open Phoenix channels, submit Inertia forms, start workspace transports, or load external game iframes.
- Use Storybook for isolated visual, viewport, controls, docs, and accessibility review.
- `@storybook/addon-vitest` runs every discovered story as a Chromium test at desktop (`1280x720`), tablet (`1024x640`), and mobile (`320x900`), and the shared visual hook compares the full rendered document after its render and optional `play` lifecycle. New deterministic stories automatically receive three viewport references under `assets/__screenshots__/<story-path>/<viewport>/<browser>/<story>.png`; review the created images, then run a normal comparison. Intentional changes use explicit `--update` followed by Git review.
- Screenshots supplement rather than replace the existing semantic, accessibility, interaction, and cross-browser assertions.
