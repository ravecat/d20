# Footer Layout and Viewport Reference

This is the implementation and review reference for #268. [design.md](design.md) owns the architectural and interaction decisions; the two capability specifications own acceptance requirements. This document makes their geometry, variants, and review cases concrete. Values below are D20 decisions, not copied Apple dimensions.

## Variants and content

| Presentation | Width | Consumers | Content |
| --- | --- | --- | --- |
| Informative | Narrow | Home, both guest and signed-in | Introduction, Explore, Help, copyright, Privacy, Terms |
| Compact | Narrow | About, Help, Contact, Privacy, Terms, existing narrow shell pages | For developers, Privacy, Terms |
| Compact | Wide | Existing wide shell pages such as game details | The same three compact links aligned to the wide shell |

Do not create an informative-wide product variant without a new requirement. Informative/compact is a page choice; narrow/wide is geometry; mobile/desktop is a viewport mode; light/dark is theme. Authentication does not change footer content. Compact never becomes an accordion.

Exact informative copy:

- Introduction: `D20 - Board games in your browser.` Only `D20` links to `/`.
- Explore: `About D20`, `Games`, `For developers`.
- Help: `How to play`, `FAQ`, `Contact / Support`.
- Legal: `(c) <current year> D20`, `Privacy`, `Terms`; render the actual copyright symbol and current year in the application.

The route inventory in [design.md](design.md) supplies hrefs. Account deletion is an expanded FAQ answer at `/help#delete-account`, not a fourth Help link or a legal-strip item.

## Geometry and typography

| Element | Desktop directory, above 48rem | Mobile directory, at or below 48rem |
| --- | --- | --- |
| Background | Neutral theme surface across viewport width | Same |
| Narrow inner box | `min(100%, 46.25rem)`, centered, border-box | Same |
| Narrow inline padding | 1rem | 1rem |
| Wide compact inner box | `min(100%, 64rem)`, 1.5rem inline padding | Same maximum, 1rem inline padding |
| Informative block padding | 1.5rem top, at least 1rem bottom | 1rem top, at least 1rem bottom |
| Introduction | Full inner width, 1rem below | Wrap naturally, 1rem below |
| Directory | Two equal columns; 2rem gap; 1rem block padding | Full-width disclosure rows, minimum 44px trigger height |
| Directory links | 0.375rem block padding, text wraps | At least 44px rows; 0.75rem extra inline start inset |
| Legal strip | 1rem above/below; copyright at start, links at end when they fit | Copyright followed by wrapping Privacy/Terms; 0.5rem row gap |
| Compact row | 0.625rem top/bottom; 1rem link gap; right aligned | Same content and order; wrap at available width |
| Separators | 1px, existing subdued border token | Between disclosure rows and above legal content |

All block-end padding includes the bottom safe-area inset. Match existing shell inline insets; do not add padding to only one physical edge for scrollbar compensation. No fixed footer height, positioning, hidden page overflow, or ellipsis is allowed to conceal content.

Use the current D20 font family. Set footer text to 0.8125rem with 1.5 line height; group headings use the same size at weight 600. Copyright can use 0.75rem if contrast remains sufficient. Links use regular weight with visible hover/focus treatment. Light and dark modes use semantic theme colors with at least 4.5:1 text contrast and a visible focus outline. There is no alternate content or layout in dark mode.

## Viewport matrix

Dimensions are CSS pixels. The existing Storybook presets in `assets/.storybook/preview.ts` are the canonical visual-suite sizes. Supplementary widths are targeted browser cases, not new global Storybook presets. The numeric 768px boundary assumes default 16px initial font size; the CSS condition remains 48rem.

| Viewport | Source/use | Informative mode | Required observation |
| --- | --- | --- | --- |
| 1280 x 720 | Existing desktop preset | Two columns | 740px outer narrow box; content stays aligned to Home |
| 1024 x 640 | Existing tablet landscape preset | Two columns | Same narrow composition; tablet label does not force mobile |
| 320 x 900 | Existing mobile preset | Disclosure rows | 288px usable narrow width; every label and link fits or wraps |
| 390 x 844 | Common phone review | Disclosure rows | Closed, Help open, Explore open, both open |
| 768 x 1024 | Tablet portrait / exact threshold | Disclosure rows | 740px bounded box; mobile controls still apply |
| 769 x 1024 | Just above threshold | Two columns | All links visible; disclosure controls absent from tab order |
| 767 x 900 | Just below threshold | Disclosure rows | No one-pixel gap or conflicting mode |
| 1440 x 900 | Large desktop review | Two columns | No stretching beyond the bounded container |
| 844 x 390 | Short landscape viewport | Two columns | Footer can scroll naturally; no viewport-height clipping |

Run compact narrow and compact wide at the three existing presets. Verify the 320px wrapping case and the wide 48rem inset transition. Review both light and dark themes at those presets; use targeted interactions for supplementary widths instead of multiplying every screenshot state by every width.

At 200 percent browser zoom, record the effective CSS viewport width and apply the same media rule. A desktop-sized window can therefore use disclosure mode. Test text enlargement without adding a third layout mode.

## Wireframes

Desktop informative, 1280 x 720 or tablet landscape 1024 x 640:

```text
viewport-wide neutral surface
       +---------------------------------------------------+
       | D20 - Board games in your browser.               |
       |---------------------------------------------------|
       | Explore                   Help                    |
       | About D20                 How to play             |
       | Games                     FAQ                     |
       | For developers            Contact / Support       |
       |---------------------------------------------------|
       | (c) YEAR D20                  Privacy | Terms      |
       +---------------------------------------------------+
```

Mobile, initial closed state:

```text
+------------------------------+
| D20 - Board games in         |
| your browser.                |
|------------------------------|
| Explore                    > |
|------------------------------|
| Help                       > |
|------------------------------|
| (c) YEAR D20                 |
| Privacy | Terms              |
+------------------------------+
```

Mobile, both independently opened:

```text
+------------------------------+
| D20 - Board games in         |
| your browser.                |
|------------------------------|
| Explore                    v |
|   About D20                  |
|   Games                      |
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

Compact narrow/wide, desktop and a wrapped small-screen example:

```text
|                     For developers   Privacy   Terms |

| For developers   Privacy |
|                   Terms |
```

Compact wraps only when the actual labels and spacing require it. Do not force the illustrated break or change the link order. Both compact widths use the same markup and content.

## Interaction and review states

The transition table in [design.md](design.md) remains authoritative. Acceptance evidence must cover:

1. Desktop all visible; mobile both closed; each group open; both open.
2. Mobile > desktop > mobile with focus outside the footer: reset to closed on return.
3. Desktop > mobile with FAQ focused: Help remains open and FAQ retains visible focus.
4. Focused mobile heading > desktop heading > mobile trigger: focus stays on a visible corresponding target.
5. A resize/orientation change within one mode: preserve disclosure state and focus.
6. Closed groups: descendants absent from keyboard and accessibility navigation, accurate expanded state.
7. Reduced motion: immediate toggle; no animated geometry on breakpoint changes.
8. Available footer markup without successful disclosure enhancement: links stay visible and usable. This does not promise that the whole existing client-rendered Home works without JavaScript.
9. Guest/signed-in, empty/short/long Home, visible Workspace controls: the footer remains in normal document flow and reachable.

Use existing public/authenticated Home stories for full-shell views and focused footer cases where states need isolation. Browser checks own resize/focus assertions; screenshots own visual geometry. Do not regard a static screenshot as evidence of correct breakpoint behavior.
