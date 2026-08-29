## Context

Storybook 10 interprets ASCII `/` in CSF meta titles as a hierarchy separator and rejects empty or trailing path segments, so titles such as `Pages//` cannot represent a visible `/` child. The route groups must remain under `Pages`, display ordinary slash punctuation, and preserve established story IDs.

## Goals / Non-Goals

**Goals:**

- Display the home page as `/` and Account Settings as `/settings` under `Pages`.
- Preserve the `home--catalog` and `pages-settings--*` story IDs.
- Keep valid Storybook hierarchy metadata and centralize the unavoidable display conversion.

**Non-Goals:**

- Replacing Storybook's hierarchy parser.
- Adding an addon or route-label registry.
- Changing production routes, page behavior, fixtures, or visual output.

## Decisions

- Keep `Pages/∕` and `Pages/∕settings` as CSF titles. Storybook splits on the first ASCII slash and treats U+2215 DIVISION SLASH as label text, producing valid child nodes.
- Configure `sidebar.renderLabel` in the existing `.storybook/manager.ts` to replace U+2215 with ASCII `/` in displayed node names. This uses Storybook's supported Manager API and leaves hierarchy keys unchanged.
- Keep the explicit meta IDs `home` and `pages-settings` so the sidebar-only transformation cannot change story URLs.

## Risks / Trade-offs

- [Sidebar text differs from internal CSF titles] -> Document the conversion in this design and verify generated index IDs plus rendered labels.
- [A non-route label intentionally uses U+2215 later] -> The character is reserved as Storybook-safe route punctuation in this catalog; use another character for mathematical text labels.
