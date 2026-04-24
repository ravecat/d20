import { defineConfig } from 'vite'
import { phoenixVitePlugin } from 'phoenix_vite'
import { svelte } from '@sveltejs/vite-plugin-svelte'
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  server: {
    port: 5173,
    strictPort: true,
    cors: { origin: "http://localhost:5000" },
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
      "@": ".",
      "phoenix-colocated": `${process.env.MIX_BUILD_PATH}/phoenix-colocated`,
    },
  },
  plugins: [
    tailwindcss(),
    svelte(),
    phoenixVitePlugin({
      pattern: /\.(ex|heex)$/
    })
  ]
});
