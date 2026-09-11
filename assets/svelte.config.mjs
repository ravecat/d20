import { vitePreprocess } from "@sveltejs/vite-plugin-svelte";

const config = {
  // Let Svelte resolve :global selectors before Vite transforms emitted CSS.
  preprocess: vitePreprocess({ script: true, style: false }),
};

export default config;
