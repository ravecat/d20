# Footer Layout and Viewport Reference

Implementation and review reference for #268. [design.md](design.md) owns architecture and interaction decisions; the capability specifications own acceptance. The 2026-09-07 simplification removes page-specific footer modes and the repeated brand/tagline introduction.

## One shared composition

Every existing App-layout page renders the same footer once after main content:

- Explore: `About`, `For Publishers and Rightholders`, `For developers`.
- Help: `How to play`, `FAQ`, `Contact / Support`.
- Legal: copyright with the current year and D20, `Privacy`, `Terms`.

Use the hrefs in [design.md](design.md). Deletion remains an expanded FAQ answer at `/help#delete-account`, not another footer item. Do not repeat the header brand or add a tagline above the directory.

There is no `compact`/`informative` content setting. Authentication and page identity do not change the footer's links. The shell's existing narrow/wide setting controls alignment only; viewport width controls desktop columns versus mobile disclosures; theme changes colors only.

## Geometry and typography

| Element | Above 48rem | At or below 48rem |
| --- | --- | --- |
| Background | Home's `--color-base-100` page surface | Same; preserve the dark page surface in dark mode |
| Narrow inner box | Centered, border-box, maximum 46.25rem, 1rem inline padding | Same |
| Wide inner box | Centered, border-box, maximum 64rem, 1.5rem inline padding | Same maximum, 1rem inline padding |
| Outer block padding | 1rem top, 0.75rem bottom plus safe-area inset | Same |
| Directory | Two equal columns capped at 12rem, 1rem gap, 0.5rem block padding | Full-width disclosure rows, no grid gap or block padding |
| Links | 0.25rem block padding, wrapping text | Minimum 44px rows, 0.75rem inline start inset |
| Legal strip | 0.5rem above, copyright at start, links at end when they fit | Copyright followed by wrapping Privacy/Terms, 0.5rem row gap |
| Separators | 1px existing subdued border token | Around the directory and between disclosure rows |

Use the existing font and theme tokens. Footer text is 0.8125rem at 1.5 line height; headings use weight 600; copyright and legal links inherit the same 0.8125rem size, family, weight, and line height. The legal strip remains a baseline-aligned wrapping flex row even below 48rem, fitting on one line at 446px and wrapping only on content pressure. Mobile ASCII rows below illustrate wrapping, not forced stacking. Preserve visible focus, 4.5:1 normal-text contrast, and at least 44px mobile disclosure triggers. Keep the footer in normal flow with no fixed height, clipping, truncation, or hidden overflow.

## Viewports and review

Dimensions are CSS pixels. Existing Storybook toolbar presets remain authoritative; do not add global presets for this change.

| Viewport | Mode | Required observation |
| --- | --- | --- |
| 1280 x 720 | Columns | Footer aligned with Home and other narrow shell pages |
| 1024 x 640 | Columns | Tablet label does not force mobile |
| 320 x 900 | Disclosures | Labels and legal links fit or wrap |
| 390 x 844 | Disclosures | Closed, either group open, both open |
| 767/768/769px wide | Boundary | Mobile at 767/768, columns at 769 with default 16px root size |
| 768 x 1024 | Disclosures | Bounded narrow inner box |
| 1440 x 900 | Columns | No stretching beyond shell maximum |
| 844 x 390 | Columns | Normal scrolling, no viewport-height clipping |

Review narrow and wide shell alignment in both themes. At 200-percent zoom, use the effective CSS viewport and the same 48rem threshold. Keep Privacy and Terms outside disclosures and available without opening a group.

## Wireframes

Desktop:

```text
       +---------------------------------------------------+
       | Explore          Help                             |
       | About            How to play                      |
       | For Publishers   FAQ                              |
       | and Rightholders Contact / Support                |
       | For developers                                    |
       |---------------------------------------------------|
       | (c) YEAR D20                  Privacy | Terms      |
       +---------------------------------------------------+
```

Mobile, closed:

```text
+------------------------------+
| Explore                    > |
|------------------------------|
| Help                       > |
|------------------------------|
| (c) YEAR D20                 |
| Privacy | Terms              |
+------------------------------+
```

Mobile, expanded:

```text
+------------------------------+
| Explore                    v |
|   About                      |
|   For Publishers and         |
|   Rightholders                |
|   For developers             |
|------------------------------|
| Help                       v |
|   How to play                |
|   FAQ                        |
|   Contact / Support          |
|------------------------------|
| (c) YEAR D20                 |
| Privacy | Terms              |
+------------------------------+
```

## Storybook and interaction coverage

Keep only `Default` and `Mobile expanded` under `Widgets/Footer`. Use existing toolbar controls for theme and viewport and the width control for shell alignment; do not duplicate stories for dark mode, focus, or narrow/wide geometry. Existing public/authenticated Home and information-page stories cover the real Layout integration, without an extra footer-focused Home story.

Browser tests cover native independent disclosures, hidden-link exclusion, keyboard activation, state retention across viewport changes, and unique accessible destinations. Native controls also work when the component markup is supplied without client JavaScript. CSS switches between static desktop lists and mobile details with explicit inline Explore and Help links. Automatic focus transfer and state reset are intentionally omitted. Screenshots cover geometry; existing Workspace integration remains unchanged.
