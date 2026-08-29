import type { StorybookConfig } from "@storybook/svelte-vite";
import { fileURLToPath } from "node:url";
import { mergeConfig } from "vite";

const config: StorybookConfig = {
  stories: ["../stories/**/*.stories.ts"],
  addons: [
    "@storybook/addon-docs",
    "@storybook/addon-a11y",
    "@storybook/addon-vitest",
    "@storybook/addon-themes",
  ],
  framework: "@storybook/svelte-vite",
  core: {
    disableTelemetry: true,
  },
  features: {
    sidebarOnboardingChecklist: false,
  },
  viteFinal: async (config) =>
    mergeConfig(config, {
      resolve: {
        alias: {
          "@inertiajs/svelte": fileURLToPath(
            new URL("../stories/mocks/inertia_svelte.ts", import.meta.url),
          ),
          "phoenix-session": fileURLToPath(
            new URL("../stories/mocks/phoenix_session.ts", import.meta.url),
          ),
        },
      },
    }),
};

export default config;
