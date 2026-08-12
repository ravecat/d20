## Context

D20's frontend is a Svelte 5 application compiled by Vite 8 from `assets/`, with production styling assembled by Tailwind 4 and daisyUI in `assets/css/app.css`. The current Vite configuration also installs Phoenix-specific template scanning and a generated `phoenix-colocated` alias, so the component catalog must verify that reusing the shared configuration remains independent of a running Mix/Phoenix environment.

The sibling Next Station London project provides the established Surf reference: Storybook 10 with `@storybook/svelte-vite`, typed CSF3 stories under a top-level `stories/` directory, configuration under `.storybook/`, production CSS imported by `preview.ts`, docs support, telemetry disabled, Storybook lint rules, and a port-6006 development command. D20 uses Bun and exposes frontend scripts through the existing `just assets` dispatcher, which preserves optional Storybook CLI argument boundaries without adding a dedicated root recipe.

## Goals / Non-Goals

**Goals:**

- Run and build Storybook from `assets/` without starting Phoenix, PostgreSQL, a socket connection, or a game iframe.
- Render real production Svelte components with the application's aliases, Tailwind/daisyUI theme, browser policy, and source assets.
- Establish typed, deterministic story and fixture conventions that can scale to connected pages and widgets.
- Make docs, controls, viewports, and accessibility inspection available now while retaining a clean path to Storybook's Vitest browser integration later.
- Fail repository validation when Storybook configuration or story compilation is broken.
- Store explicitly generated static output under Phoenix's standard static tree so Phoenix can serve the catalog when it exists.

**Non-Goals:**

- Add the Storybook Vitest addon, visual regression service, screenshot baselines, or CI deployment in this change.
- Add stories for every page, shared component, workspace state, or embedded game surface.
- Reimplement production markup for stories or make production components depend on Storybook.
- Replace existing Vitest unit/browser tests or full Phoenix application coverage.
- Publish Storybook automatically as part of the production asset deployment.

## Decisions

### Keep Storybook inside the existing frontend package

Place `.storybook/` and `stories/` under `assets/`, install Storybook as development-only dependencies in the existing `assets/package.json`, and use `@storybook/svelte-vite`. This keeps one Svelte/Vite dependency graph, one Bun lockfile, and direct reuse of the production `~` alias and component types.

The catalog will expose `storybook` and `storybook:build` package scripts. Contributors use `just assets storybook [args...]` for development and `just assets storybook:build` for static output. The existing dispatcher runs in `assets/` and forwards each positional argument unchanged to Bun, preserving D20's intentionally small root command surface.

The development script passes Storybook's `--ci` flag so Storybook accepts the nearest free port automatically when 6006 is occupied. Storybook's CLI couples that non-interactive behavior to disabling automatic browser launch, so the terminal-reported URL is the authoritative address. Explicit trailing CLI arguments remain supported, including a caller-supplied `--port` override.

Creating a separate package was rejected because it would duplicate the Svelte, Vite, TypeScript, Tailwind, and browser-policy configuration and make version drift more likely.

### Supervise routed development output with Concurrently

Add `concurrently` to the Nix development shell and declare the composite command directly in `just up`. The workflow starts Docker Compose first, then runs `just restart-or-serve` and `just assets storybook` together. Prefix the streams as `phoenix` and `storybook` with distinct colors so one terminal remains readable. The frontend package keeps only the atomic `storybook` and `storybook:build` scripts and does not own host process orchestration.

Use `--kill-others-on-fail` instead of the reference project's `--kill-others`. D20's reuse branch intentionally touches the watched configuration and exits successfully when the exact `d20` node already exists. A successful helper exit must leave Storybook running, while an actual Phoenix or Storybook failure must terminate the other process instead of leaving a partial foreground workflow.

When `just up` starts Phoenix itself, both Phoenix and Storybook logs belong to the Concurrently process and appear in the combined stream. When an already-running Phoenix process is reused, its stdout remains owned by the terminal that started it; the new `just up` invocation cannot reattach that stream and shows the helper result plus Storybook logs. Stopping and relaunching an externally owned Phoenix process solely to capture its output was rejected because it would disrupt another active workflow.

Using Just's `[parallel]` dependency attribute was rejected because Concurrently matches the sibling project, provides explicit log names and colors, and supports failure-specific sibling termination. Keeping the composite command in `assets/package.json` was rejected because Phoenix and Docker Compose are host workflows owned by the root task supervisor, not the frontend package. Unmanaged shell background jobs were rejected because signal forwarding and partial-failure cleanup would be implicit and error-prone.

### Reuse the shared Vite configuration without a Storybook mode

Mirror the reference's typed `main.ts`, typed `preview.ts`, CSF3 story shape, production CSS import, docs addon, disabled telemetry, and onboarding suppression. Add the accessibility addon because issue #159 requires an immediately inspectable accessibility baseline.

Storybook will load the shared Vite configuration directly without a Storybook-specific environment flag. The Phoenix Vite plugin only adjusts hot updates for `.ex` and `.heex` files and closes Vite with its parent stdin; it does not start Phoenix or require a backend. Keeping it in the shared plugin list avoids a second configuration mode while Tailwind, Svelte preprocessing, aliases, and browser targets remain identical to the application build.

Running a separate application Vite server as Next Station London does was rejected because D20's initial production-component stories do not need application HTML or a backend entry point. A `STORYBOOK` environment guard was rejected after direct verification because it changed no required behavior and added a mode used only to suppress a harmless plugin.

### Use typed CSF3 and real production components

Story files live under `assets/stories/**/*.stories.ts`, use `Meta` and `StoryObj` from `@storybook/svelte-vite`, place shared defaults in meta-level `args`, and import components from `assets/js` through the production alias. The first smoke story will cover meaningful player-count states on the existing `PlayerCountLabel`, which exercises Svelte props, production CSS variables, controls, and conditional rendering without requiring application infrastructure.

Future connected stories MUST isolate side effects at module boundaries and use deterministic fixtures. Reusable data belongs under `assets/stories/fixtures/`; Storybook module mocks belong in `assets/.storybook/preview.ts` or a narrowly scoped story module. Stories must not create live Phoenix channels, workspace transports, external game iframes, or Inertia form submissions.

Copying component markup into story-only Svelte files was rejected because it can pass catalog review after production UI has diverged.

### Extend existing static tooling and aggregate validation

Include `.storybook/**/*.ts` and `stories/**/*.ts` in the strict frontend TypeScript project and apply Storybook's recommended flat ESLint rules. Emit the static catalog to `priv/static/storybook`, add `storybook` to `D20Web.static_paths/0`, and ignore that generated Phoenix static subtree in Git. Because the output is outside the frontend package, ESLint and Oxfmt require no generated-output exception. Add a Mix asset alias for the static catalog build and invoke it from `just check` after frontend type checking and before backend tests.

Static Storybook output will remain untracked. Phoenix serves it when the explicit build exists, but `mix assets.deploy` does not generate or publish the catalog automatically. The regular Vite build owns and clears `priv/static`, so workflows that need both outputs run the Storybook build after the application asset build. A successful catalog build proves configuration and story bundling; it does not claim browser interaction, visual, or accessibility test coverage.

Keeping the build as an undocumented manual check was rejected because issue #159 requires repository validation to detect catalog breakage.

## Risks / Trade-offs

- [Storybook and the application resolve different Vite behavior] - Share the production Vite configuration and verify the Phoenix-specific plugin does not require a running backend in development or static builds.
- [Tailwind scans omit story-only class names] - Stories render production components and import production CSS; story-only wrappers must use minimal inline layout or existing utility sources rather than becoming a second styling surface.
- [Connected stories trigger network or process side effects] - Document fixture and module-mock boundaries and prohibit live transports in stories; add focused mocks when the first connected story is introduced.
- [Static catalog builds lengthen `just check`] - Keep the initial catalog small and use Storybook's static build as the narrow validation required to catch configuration and bundling failures.
- [Storybook upgrades drift from Svelte/Vite] - Start from the versions already proven in Next Station London and keep all Storybook packages on one release line in the Bun lockfile.
- [Generated output appears in commits] - Ignore `priv/static/storybook/` alongside Phoenix's other generated static output.
- [Application assets remove a previously built catalog] - Treat Vite's `priv/static` cleanup as authoritative and run the explicit Storybook build afterward when both outputs are needed.
- [Storybook is exposed unintentionally in production] - Keep the catalog out of `mix assets.deploy`; Phoenix serves it only when another workflow explicitly builds or supplies it.
- [One supervised process fails while the other continues] - Use Concurrently's failure-only sibling termination so real failures clean up the foreground workflow while successful Phoenix reuse does not stop Storybook.

## Migration Plan

1. Add and lock the Storybook development dependencies alongside the existing Svelte/Vite toolchain, and expose Concurrently through the Nix development shell.
2. Add shared configuration and extend TypeScript, lint, and format scopes without introducing a Storybook-specific Vite mode.
3. Add the typed production-component smoke story and document story/fixture conventions.
4. Add the static build alias to aggregate repository validation and emit its output under `priv/static/storybook`.
5. Extend `just up` with prefixed Concurrently supervision for Phoenix and Storybook.
6. Run the focused Storybook build, lint, typecheck, frontend tests, production asset build, and broad repository check; manually inspect the smoke story at supported desktop and narrow viewports.
7. Roll back by removing the Storybook package scripts, dependencies, configuration, story sources, Phoenix static-path entry, validation alias, generated-output ignore entry, and Nix Concurrently package, then restore `just up` to direct server delegation.

## Open Questions

None.
