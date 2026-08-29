## Context

Storybook already discovers typed Svelte CSF stories under `assets/stories/`, aliases Inertia to a no-network mock, and automatically runs every deterministic story through desktop, tablet, and mobile visual projects. The production `HomePage` is prop-driven but has no story.

## Goals / Non-Goals

**Goals:**

- Render the production `HomePage` through the existing Storybook boundary.
- Give the sidebar a route-like title using the approved division slash `∕`.
- Show representative catalog stages with deterministic local metadata.
- Keep the automatic visual regression suite complete.

**Non-Goals:**

- Changing home-page behavior or styles.
- Introducing shared fixture abstractions for a single story.
- Loading catalog data from Phoenix or remote image hosts.
- Renaming existing stories.

## Decisions

- Add one classic typed CSF story because every existing story uses `Meta` and `StoryObj`; introducing CSF Next would create an inconsistent one-off pattern.
- Set the visible `title` to the approved division slash `∕` and provide the stable alphanumeric meta `id` `home`. Storybook reserves `/` as a hierarchy separator and rejects a title ending with it; `∕` preserves the intended appearance without breaking the manager, while the explicit ID keeps the story URL readable and stable.
- Keep the complete catalog fixture inline in meta `args` so the scenario remains readable and no single-use helper hides required game metadata.
- Use catalog entries without remote images. The production fallback artwork is deterministic and avoids network-dependent rendering.
- Include released, in-development, and planned entries in one representative scenario so the story covers the meaningful catalog distinctions without multiplying baseline images.
- Generate and review the desktop, tablet, and mobile baselines because Storybook stories are automatically included in those projects.

## Risks / Trade-offs

- [Storybook rejects a title ending in `/` and breaks the manager sidebar] -> Use the approved `∕` lookalike with the explicit `home` meta ID, then verify the manager and generated index.
- [Adding a story expands visual-regression runtime and repository size] -> Keep one cohesive story rather than separate stage stories.
- [Fallback artwork does not exercise image loading] -> Existing home-page tests cover image URL selection; this story prioritizes deterministic visual review.
