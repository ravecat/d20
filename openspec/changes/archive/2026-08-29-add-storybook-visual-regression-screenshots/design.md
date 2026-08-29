## Context

D20 already has two Vitest projects in `assets/vite.config.mjs`: a jsdom unit project and a real-browser project that runs in Chromium and Firefox. Storybook 10.5 uses the same Svelte/Vite toolchain, discovers six typed CSF3 files under `assets/stories/`, and supplies deterministic mocks for connected boundaries, but Storybook is currently built only as a static catalog and is not transformed into automated browser tests.

The official `@storybook/addon-vitest` plugin transforms discovered stories into Vitest Browser Mode tests without starting a Storybook development server. Vitest 4 provides native `toMatchScreenshot()` comparison, stable-screenshot detection, explicit baseline updates, image attachments, UI/HTML review, and a Playwright browser provider. The Next Station London repository has already proven the lifecycle needed here; D20 must adapt it without copying that repository's pnpm commands, Vite root, aliases, story format, or single-browser test assumptions.

## Goals / Non-Goals

**Goals:**

- Make Storybook discovery the only manifest for visual coverage.
- Run every story through its existing render and optional `play` lifecycle before screenshot comparison.
- Compare desktop, tablet, and mobile output in one Vitest command surface.
- Preserve the existing jsdom unit project and Chromium/Firefox browser project unchanged in purpose and coverage.
- Keep committed references easy to review and generated failure evidence easy to inspect.
- Keep the integration deterministic, local, account-free, and isolated from production services.
- Pin shared production and Storybook text and mathematical-symbol font assets so reference glyph outlines do not depend on host font lookup or a runtime network font request.

**Non-Goals:**

- Add a cloud visual-testing service or token.
- Add Playwright Test, a custom image comparator, a second story manifest, or a running Storybook server requirement.
- Replace semantic, accessibility, interaction, or cross-browser assertions with screenshots.
- Capture Firefox screenshot baselines for Storybook stories.
- Change component structure, story fixtures, Phoenix behavior, iframe modules, or release infrastructure.

## Decisions

### Transform stories with the official Storybook Vitest plugin

Add version-aligned `@storybook/addon-vitest` and `@vitest/ui` development dependencies. Register the addon in `.storybook/main.ts`, then use `storybookTest()` from `@storybook/addon-vitest/vitest-plugin` in three explicit Vitest projects. Each project points at `assets/.storybook` and pins one stable viewport global.

This preserves Storybook's own composition, decorators, mocks, and `play` functions and avoids rebuilding story fixtures in separate tests. Explicit projects are preferred over a project factory so each viewport's ordering, trace directory, and future diagnostics remain visible in configuration.

Rejected alternatives:

- Playwright Test duplicates the existing runner, browser provider, reporting, and command lifecycle.
- A hand-maintained story allowlist can silently omit newly added stories.
- Importing Vitest screenshot assertions inside story `play` functions would couple interactive Storybook rendering to a Vitest-only runtime.

### Establish named viewports before story execution

Define desktop (`1280x720`), tablet (`1024x640`), and mobile (`320x900`) options once in `.storybook/preview.ts`, with desktop as the interactive default. Each Storybook Vitest project selects its viewport through `storybookTest({ initialGlobals })`, so responsive layout is established before decorators, render, and `play` execute. The browser instance explicitly names the generated Vitest project `desktop`, `tablet`, or `mobile`; screenshot paths and `--project` filters use that complete name directly without parsing or rewriting a runtime-generated project label.

The Storybook Chromium provider receives a `1280x900` host context and screen. This prevents the tallest mobile iframe from being scaled into Playwright's shorter default host. Storybook files run with `fileParallelism: false`, and the three viewport projects receive increasing `sequence.groupOrder` values after the existing projects to reduce browser resource contention and avoid trace or attachment collisions. The existing browser project's files also run serially so its Chromium and Firefox interaction tests remain stable when the complete command shares Browser Mode resources with the visual projects; its include rules, aliases, instances, and `1280x800` viewport remain unchanged. Browser Mode explicitly disables strict API port binding so Vite selects the next available port when the default `63315` is occupied by another test run.

Rejected alternative: resizing the page in the screenshot hook would occur after `play`, so interaction assertions and the captured responsive state could observe different layouts.

### Pin text and mathematical symbols through lockfile-managed Fontsource assets

The D20 global stack (`ui-monospace, "SF Mono", "Cascadia Mono", Consolas, monospace`) resolves through host Fontconfig on Linux because none of the named families is installed. The selected Noto fallback varies with the host font set, Fontconfig and FreeType versions, and Chromium rasterization state, so identical DOM and CSS can produce different glyph edge pixels between runs and environments. A baseline update cannot fix this: the next run can rasterize the same text differently again.

Add `@fontsource-variable/noto-sans-mono` at an exact version in `assets/package.json` so `bun.lock` pins the exact WOFF2 and its integrity. Its Google Fonts subsets do not contain mathematical operators such as `≤` (`U+2264`), so add the exact `@fontsource/noto-sans-symbols-2` package and import only its math subset as the next family in the production font stack. Vite bundles both assets for production and Storybook, which already imports the production stylesheet, so ordinary text and mathematical symbols no longer use a runtime Google Fonts request or host font lookup.

Rejected alternatives:

- A runtime Google Fonts stylesheet can change the served font revision without a manifest change, depends on the network and cache, and reintroduces a font-loading race.
- A Storybook-only stylesheet could make references quieter while diverging from the production UI they are intended to review.
- Replacing mathematical symbols with test-only text or CSS would alter the visual contract instead of stabilizing production rendering.

### Normalize text rendering through shared production CSS

Keep `font-synthesis: none`, `text-rendering: optimizeLegibility`, `-webkit-font-smoothing: antialiased`, and `-moz-osx-font-smoothing: grayscale` on the existing global `html, body` rule. Disabling synthesis prevents Chromium from inventing missing bold or italic glyphs; the remaining declarations request consistent legibility and grayscale smoothing where the browser and platform support them. These are best-effort hints: repeated unchanged comparisons still produced text-only pixel differences before the font asset was pinned, so they complement rather than replace the pinned font.

### Capture the complete story test document in one shared hook

Add `.storybook/vitest.setup.ts` with an asynchronous `afterEach` hook that explicitly loads every declared document font before running `expect(document.documentElement).toMatchScreenshot()` without an explicit name. Storybook's generated test owns render and `play`; the project hook captures only after that lifecycle completes and before cleanup. Explicit `FontFace.load()` calls are required because `font-display: swap` can otherwise leave a stable host fallback in place long enough for Vitest's screenshot retry to accept it under full-matrix load.

The complete document is the intended contract because each story represents one isolated canvas and the request is to preserve the rendered Storybook state, including its story-level layout. The configured viewport project and browser remain visible as nested directories while the filename contains only Vitest's automatic test identity. No task-name inspection, screenshot-only CSS wrapper, arbitrary delay, manual viewport resize, custom comparator, custom Fontconfig file, or Chromium font, color-profile, or text-rendering launch override is introduced.

### Separate committed references from generated evidence

Configure `resolveScreenshotPath` so committed Linux Chromium references live below the frontend root:

```text
assets/__screenshots__/
└── stories/
    └── <story-file>/
        ├── desktop/
        │   └── chromium/
        ├── tablet/
        │   └── chromium/
        └── mobile/
            └── chromium/
```

The path mirrors the owning story directory, encodes the viewport as a plain `desktop`, `tablet`, or `mobile` child directory, and places the single supported Chromium browser in its own `chromium` directory so otherwise identical generated test identities cannot overwrite one another. The filename contains only the automatic story test identity because viewport and browser are already encoded by directories and the reference environment is fixed to Linux Chromium. Keep Vitest's generated actual and diff attachments under `assets/.vitest-attachments/`; place HTML output and retained failure traces under `assets/.vitest/`. Track only `assets/__screenshots__/`, preserve the broad screenshot ignore with an exception for that reviewed root, and exclude references and runtime test evidence from the Docker build context because none is required at runtime.

Normal runs never replace references. Missing references are created and fail their first comparison for review. Intentional changes use explicit `--update`, followed by Git review and a normal comparison run. Renamed or deleted stories require stale-reference review because Vitest cannot infer repository cleanup intent.

### Use existing command boundaries

Keep `bun run test` as the complete Vitest invocation so `mix assets.test` and `just check` automatically include unit, existing browser, and all Storybook viewport projects. Keep the current `test:unit` and `test:browser` filters. Use Vitest's native `--project`, reporter, `--ui`, and `--update` flags for focused visual work rather than adding a custom argument parser or one command per viewport.

Keep the repository README focused on the pinned Chromium installation, normal comparison, explicit baseline update, and tracked reference location. Vitest reporter, UI, and trace-viewer usage belongs in upstream tool documentation. Storybook's static build remains a separate validation step and does not become a prerequisite for generated story tests.

## Risks / Trade-offs

- [Baseline volume and runtime increase] -> Every new story adds three images and three Chromium tests; keep one automatic discovery boundary and run viewport projects in deterministic order.
- [Platform rendering drift] -> Keep Linux Chromium as the single documented reference environment, encode Chromium once in each viewport's `chromium` directory, omit the redundant platform filename suffix, pin the Playwright version, pin text and mathematical-symbol assets, and explicitly load declared web fonts before capture instead of relying on host fallback timing.
- [Dynamic story content] -> Preserve the existing deterministic fixture rules and fix nondeterministic stories at their source rather than masking broad regions or loosening comparison thresholds.
- [Hook lifecycle changes in dependency upgrades] -> Validate at least one story with a `play` function and one without whenever Storybook or Vitest is upgraded.
- [Resource contention] -> Serialize files in the existing browser and Storybook projects, order viewport projects, and retain traces only on failure.
- [Accidental baseline acceptance] -> Require explicit `--update`, Git image review, and a subsequent normal run.
- [Stale references after story deletion] -> Include screenshot-tree cleanup in baseline review and validation tasks.
- [Local browser prerequisite] -> Document the pinned Chromium install command and fail clearly when it is absent rather than downloading browsers during ordinary tests.

## Migration Plan

1. Add the version-aligned addons, Storybook viewport definitions, generated-story projects, shared screenshot hook, and artifact paths without changing existing test projects.
2. Prove one story's baseline creation, normal comparison, deliberate mismatch evidence, HTML/UI review, trace retention, and explicit update lifecycle.
3. Generate and review all current desktop, tablet, and mobile Linux Chromium references, then rerun normal comparison.
4. Update ignore rules, Docker context exclusions, story conventions, and contributor commands.
5. Pin the text and mathematical-symbol fonts, regenerate all references, and verify repeated unchanged visual comparisons plus all frontend checks, static Storybook build, broad repository validation, and strict OpenSpec validation.
6. Roll back by removing the three Storybook projects, setup hook, viewport globals, font dependencies and font-family changes, added development dependencies, and reference tree. Existing unit/browser tests and static Storybook build then return to their current independent behavior.

## Open Questions

None. The supported reference environment, viewport matrix, artifact layout, and command boundary are fixed by this change.
