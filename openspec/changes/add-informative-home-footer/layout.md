# Footer Layout and Viewport Reference

Current 2026-09-08 presentation for #268, based on the supplied Zed screenshot and https://zed.dev/. This supersedes the Apple-style disclosure and bottom-strip layouts. Design and publication ownership remain in [design.md](design.md).

## Composition

Every App-layout page renders one footer after main. DOM, reading and keyboard order are service information (`d20 © <current year>`, guest account row, Terms), Explore (About, For publishers and rightholders, For developers), then Help (How to play, FAQ, Contact / support). Preserve existing hrefs and Inertia/plain-anchor behavior. Privacy remains deferred under #248; deletion remains an expanded FAQ answer under #247.

Use one explicit heading/anchor tree per labelled navigation group, without details/summary, ul/li, duplicate representations or a repeated brand/tagline. Every link is always available.

## Geometry

- Preserve Home's theme surface, 0.8125rem type with 1.5 line height and 600-weight group headings.
- Preserve centered 46.25rem narrow and 64rem wide border-box containers. Inline insets remain 1rem, increasing to 1.5rem for the wide shell above 48rem.
- Use three columns above 48rem: a slightly wider service block and two equal navigation columns. Separate the navigation columns with fine existing border tokens and comfortable inline padding.
- At or below 48rem, place the service block across the top and Explore/Help in two equal columns below. Copyright, guest entry actions and Terms stack naturally in the top block.
- Use 1rem block padding inside the top divider, compact 0.375rem group gaps and at least 1.5rem link targets. Preserve 0.5rem bottom padding plus safe-area inset.
- Allow labels to wrap at 320px and increased text size. Do not clip, truncate, reorder links or impose a fixed height. Preserve normal document flow and the existing short-page footer placement.

## Wireframes

Desktop:

```text
------------------------------------------------------------
d20 (c) YEAR          | Explore              | Help
Sign up ·            | About                | How to play
Have an account?     | For publishers and   | FAQ
Sign in              | rightholders         | Contact / support
Terms                | For developers       |
```

Mobile:

```text
--------------------------------
d20 (c) YEAR
Sign up · Have an account?
Sign in
Terms
--------------------------------
Explore          | Help
About            | How to play
For publishers   | FAQ
and rightholders | Contact /
For developers   | support
```

## Verification

Use existing 1280x720, 1024x640 and 320x900 Storybook presets plus 390x844, 767/768/769px boundary, 768x1024, 1440x900 and 844x390. Verify narrow/wide geometry and both themes. At 200-percent scaling, verify readable wrapping and visible focus without horizontal overflow.

Keep only Default under Widgets/Footer; existing controls select width, viewport and theme. Existing Home and information-page stories cover shared layout integration. Browser tests cover seven unique visible destinations, no disclosures, keyboard order, focus across breakpoint/orientation changes and passive rendering. The layout regression test retains overflow-removal coverage using content removal instead of footer collapse. No new viewport presets or test-only product hooks are needed.
