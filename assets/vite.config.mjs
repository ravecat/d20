import path from "node:path";
import { fileURLToPath } from "node:url";
import { storybookTest } from "@storybook/addon-vitest/vitest-plugin";
import { svelte } from "@sveltejs/vite-plugin-svelte";
import tailwindcss from "@tailwindcss/vite";
import { playwright } from "@vitest/browser-playwright";
import browserslist from "browserslist";
import browserslistToEsbuild from "browserslist-to-esbuild";
import { browserslistToTargets, Features } from "lightningcss";
import { phoenixVitePlugin } from "phoenix_vite";
import { defineConfig } from "vite";

const assetsDir = fileURLToPath(new URL(".", import.meta.url));
const storybookDir = path.join(assetsDir, ".storybook");
const browserTargets = browserslistToEsbuild(undefined, { path: assetsDir });
const staticPort = Number(process.env.STATIC_PORT || "5174");
const isVitest = process.env.VITEST === "true";

const themes = ["light", "dark"];
const viewports = ["desktop", "tablet", "mobile"];
const visualProjects = themes.flatMap((theme) =>
  viewports.map((viewport) => {
    const name = `visual-${theme}-${viewport}`;

    return {
      extends: true,
      optimizeDeps: {
        exclude: ["@storybook/svelte"],
      },
      plugins: [
        storybookTest({
          configDir: storybookDir,
          initialGlobals: {
            theme,
            viewport: { value: viewport },
          },
        }),
        {
          name: "visual-project-cache",
          enforce: "post",
          config: () => ({ cacheDir: path.join(assetsDir, ".vitest/cache", name) }),
        },
      ],
      test: {
        fileParallelism: false,
        setupFiles: [path.join(storybookDir, "vitest.setup.ts")],
        browser: {
          enabled: true,
          headless: true,
          instances: [{ browser: "chromium", name }],
          trace: {
            mode: "retain-on-failure",
            tracesDir: path.join(assetsDir, ".vitest/traces", name),
          },
          expect: {
            toMatchScreenshot: {
              resolveDiffPath: ({
                arg,
                attachmentsDir,
                browserName,
                ext,
                root: projectRoot,
                testFileDirectory,
                testFileName,
              }) =>
                path.join(
                  projectRoot,
                  attachmentsDir,
                  testFileDirectory,
                  testFileName,
                  theme,
                  viewport,
                  browserName,
                  `${arg}${ext}`,
                ),
              resolveScreenshotPath: ({
                arg,
                browserName,
                ext,
                root: projectRoot,
                screenshotDirectory,
                testFileDirectory,
                testFileName,
              }) =>
                path.join(
                  projectRoot,
                  screenshotDirectory,
                  testFileDirectory,
                  testFileName,
                  theme,
                  viewport,
                  browserName,
                  `${arg}${ext}`,
                ),
            },
          },
        },
      },
    };
  }),
);

export default defineConfig({
  root: assetsDir,
  css: {
    transformer: "lightningcss",
    lightningcss: {
      targets: browserslistToTargets(browserslist(undefined, { path: assetsDir })),
      include: Features.Nesting,
    },
  },
  server: {
    host: true,
    port: staticPort,
    strictPort: true,
    cors: true,
    allowedHosts: true,
  },
  build: {
    target: browserTargets,
    manifest: true,
    rolldownOptions: {
      input: ["js/app.js", "css/app.css"],
    },
    outDir: "../priv/static",
    emptyOutDir: true,
  },
  // LV Colocated JS and Hooks
  // https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.ColocatedJS.html#module-internals
  resolve: {
    conditions: ["svelte", "browser", "import", "default"],
    alias: {
      "~": path.resolve(assetsDir, "js"),
      "~stories": path.resolve(assetsDir, "stories"),
      "phoenix-colocated": `${process.env.MIX_BUILD_PATH}/phoenix-colocated`,
    },
  },
  plugins: [
    tailwindcss(),
    svelte({ configFile: "svelte.config.mjs" }),
    !isVitest &&
      phoenixVitePlugin({
        pattern: /\.(ex|heex)$/,
      }),
  ],
  test: {
    outputFile: {
      html: path.join(assetsDir, ".vitest/report/index.html"),
    },
    browser: {
      api: { strictPort: false },
      provider: playwright({
        contextOptions: {
          viewport: { width: 1280, height: 900 },
          screen: { width: 1280, height: 900 },
        },
      }),
      expect: {
        toMatchScreenshot: {
          resolveScreenshotPath: ({
            arg,
            browserName,
            ext,
            project,
            root: projectRoot,
            screenshotDirectory,
            testFileDirectory,
            testFileName,
          }) =>
            path.join(
              projectRoot,
              screenshotDirectory,
              testFileDirectory,
              testFileName,
              project.name,
              browserName,
              `${arg}${ext}`,
            ),
        },
      },
    },
    projects: [
      {
        extends: true,
        test: {
          name: "unit",
          environment: "jsdom",
          include: ["tests/**/*.test.ts"],
          exclude: ["tests/**/*.browser.test.ts"],
          setupFiles: ["tests/setup.ts"],
        },
      },
      {
        extends: true,
        optimizeDeps: {
          exclude: ["@inertiajs/svelte", "@sjsf/basic-theme", "@sjsf/form"],
          include: ["@inertiajs/core"],
        },
        test: {
          name: "browser",
          fileParallelism: false,
          include: ["tests/**/*.browser.test.ts"],
          alias: {
            "@inertiajs/svelte": path.resolve(assetsDir, "tests/mocks/inertia_svelte.ts"),
          },
          browser: {
            enabled: true,
            headless: true,
            provider: playwright(),
            instances: [{ browser: "chromium" }, { browser: "firefox" }],
            viewport: { width: 1280, height: 800 },
          },
        },
      },
      ...visualProjects,
    ],
  },
});
