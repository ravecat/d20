import path from "node:path";
import { fileURLToPath } from "node:url";
import { svelte } from "@sveltejs/vite-plugin-svelte";
import tailwindcss from "@tailwindcss/vite";
import { phoenixVitePlugin } from "phoenix_vite";
import { defineConfig } from "vite";

const assetsDir = fileURLToPath(new URL(".", import.meta.url));
const appPort = process.env.PORT || "5000";
const vitePort = Number(process.env.VITE_PORT || "5174");
const phoenixUrlPort = process.env.PHX_URL_PORT || appPort;
const phoenixUrlScheme = process.env.PHX_URL_SCHEME || "http";
const phoenixHost = process.env.PHX_HOST || "localhost";
const defaultPhoenixOrigin = `${phoenixUrlScheme}://${phoenixHost}${
  ["80", "443"].includes(phoenixUrlPort) ? "" : `:${phoenixUrlPort}`
}`;
const isVitest = process.env.VITEST === "true";

export default defineConfig({
  root: assetsDir,
  server: {
    host: "0.0.0.0",
    port: vitePort,
    strictPort: true,
    cors: { origin: defaultPhoenixOrigin },
  },
  optimizeDeps: {
    // https://vitejs.dev/guide/dep-pre-bundling#monorepos-and-linked-dependencies
    include: ["@inertiajs/svelte", "phoenix", "phoenix_html", "phoenix_live_view", "svelte"],
  },
  build: {
    manifest: true,
    rollupOptions: {
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
      "~actions": path.resolve(assetsDir, "js/actions"),
      "~components": path.resolve(assetsDir, "js/components"),
      "~pages": path.resolve(assetsDir, "js/pages"),
      "~stores": path.resolve(assetsDir, "js/stores"),
      "~types": path.resolve(assetsDir, "js/types"),
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
    environment: "jsdom",
    include: ["js/**/*.test.ts"],
  },
});
