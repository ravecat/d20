import path from "node:path";
import { fileURLToPath } from "node:url";
import { svelte } from "@sveltejs/vite-plugin-svelte";
import tailwindcss from "@tailwindcss/vite";
import { playwright } from "@vitest/browser-playwright";
import browserslistToEsbuild from "browserslist-to-esbuild";
import { phoenixVitePlugin } from "phoenix_vite";
import { defineConfig } from "vite";

const assetsDir = fileURLToPath(new URL(".", import.meta.url));
const browserTargets = browserslistToEsbuild(undefined, { path: assetsDir });
const staticPort = Number(process.env.STATIC_PORT || "5174");
const isVitest = process.env.VITEST === "true";

export default defineConfig({
  root: assetsDir,
  server: {
    host: true,
    port: staticPort,
    strictPort: true,
    cors: true,
    allowedHosts: true,
  },
  optimizeDeps: {
    // https://vitejs.dev/guide/dep-pre-bundling#monorepos-and-linked-dependencies
    include: isVitest
      ? ["svelte"]
      : ["@inertiajs/svelte", "phoenix", "phoenix_html", "phoenix_live_view", "svelte"],
    exclude: isVitest ? ["@inertiajs/svelte"] : [],
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
        test: {
          name: "browser",
          include: ["tests/**/*.browser.test.ts"],
          browser: {
            enabled: true,
            headless: true,
            provider: playwright({
              launchOptions: {
                channel: "chrome",
              },
            }),
            instances: [{ browser: "chromium" }],
            viewport: { width: 1280, height: 800 },
          },
        },
      },
    ],
  },
});
