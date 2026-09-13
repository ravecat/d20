# Story conventions

- Keep stories under `assets/stories/` and group them by the production UI boundary they exercise.
- Import production components through the `~` alias. Do not copy production markup into story-only components.
- Use typed CSF3 `Meta` and `StoryObj` definitions with deterministic args that describe a complete component state.
- Keep the branch-driving state for a scenario inline in its story. Put only genuinely shared or bulky data under `assets/stories/fixtures/`; fixtures must not depend on clocks, randomness, mutable backend state, or environment-specific identifiers.
- Replace connected dependencies at their module boundary with deterministic Storybook mocks. Prefer small direct state controls such as `set`, `setStatus`, and `clear`; call `set` from the story's `beforeEach`, apply reactive transitions from `play`, and return `clear` as cleanup. Stories must not open Phoenix channels, submit Inertia forms, start workspace transports, or load external game iframes.
- Use Storybook for isolated visual, viewport, controls, docs, accessibility review, and production-component interaction behavior expressed through `play` functions and accessible queries.
- Visual tests run every discovered story in light and dark themes at desktop (`1280x720`), tablet (`1024x640`), and mobile (`320x900`), with screenshot comparison after rendering and `play`.
- Declare each scenario once. Use the theme toolbar for interactive review instead of creating theme-only Dark stories or setting story-level theme overrides. New deterministic stories receive six references under `assets/__screenshots__/<story-path>/<theme>/<viewport>/chromium/<scenario>-1.png`; review newly created images, then run a normal comparison. Intentional changes use explicit `--update` followed by Git review.
- The current native iframe capture clips content below the configured viewport on long pages, leaving white rows in larger images. Track the capture correction in [#281](https://github.com/ravecat/d20/issues/281); passing these references does not verify below-fold content.
- Screenshots supplement rather than replace semantic, accessibility, and interaction assertions, whether those assertions live in a focused browser test or a Storybook `play` function.
