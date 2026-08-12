import type { StorybookConfig } from "@storybook/svelte-vite";

const config: StorybookConfig = {
  stories: ["../stories/**/*.stories.ts"],
  addons: ["@storybook/addon-docs", "@storybook/addon-a11y"],
  framework: "@storybook/svelte-vite",
  core: {
    disableTelemetry: true,
  },
  features: {
    sidebarOnboardingChecklist: false,
  },
};

export default config;
